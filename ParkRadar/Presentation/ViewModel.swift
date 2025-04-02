import Foundation
import Combine
import RealmSwift
import CoreLocation
import MapKit

final class MapViewModel: ObservableObject {
    
    let geocodingService = GeocodingService()
    
    let repository = Repository()
    
    struct Input {
        let currentCenter: AnyPublisher<CLLocationCoordinate2D, Never>
        let currentAltitude: AnyPublisher<CLLocationDistance, Never>
        let currentLocation: AnyPublisher<CLLocation, Never>
        let selectedParking: AnyPublisher<SafeParkingArea, Never>
        let safeFilter: AnyPublisher<Bool, Never>
        let dangerFilter: AnyPublisher<Bool, Never>
    }
    
    struct Output {
        let safeAnnotations: AnyPublisher<[SafeAnnotation], Never>
        let dangerAnnotations: AnyPublisher<[DangerAnnotation], Never>
        let addressInformation: AnyPublisher<String, Never>
        let parkingInformation: AnyPublisher<[SafeParkingArea], Never>
        let convertedLocation: AnyPublisher<NavigationData, Never>
        
        let safeFilterCondition: AnyPublisher<Bool, Never>
        let dangerFilterCondition: AnyPublisher<Bool, Never>
    }
    
    let latestLocationAndZoom = CurrentValueSubject<(CLLocationCoordinate2D, CLLocationDistance), Never>((.init(), 0))
    
    private var cancellables = Set<AnyCancellable>()
    private let realm = try! Realm()
    
    func bind(input: Input) -> Output {
        let locationAndZoom = input.currentCenter
            .combineLatest(input.currentAltitude)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        
        let safePub = PassthroughSubject<[SafeAnnotation], Never>()
        let dangerPub = PassthroughSubject<[DangerAnnotation], Never>()
        let addressPub = PassthroughSubject<String, Never>()
        let parkingPub = PassthroughSubject<[SafeParkingArea], Never>()
        let convertedAddressPub = PassthroughSubject<NavigationData, Never>()
        
        let safeFilterPub = CurrentValueSubject<Bool, Never>(true)
        let dangerFilterPub = CurrentValueSubject<Bool, Never>(true)
        
        //        print(realm.configuration.fileURL!) //**for debbuging
        
        input.currentLocation
            .flatMap { location in
                self.geocodingService.reverseGeocode(location: location)
            }
            .sink { address in
                print(address)
                if let address {
                    print("address reverse geocoding called")
                    addressPub.send(address)
                }
            }
            .store(in: &cancellables)
        
        input.safeFilter.sink { value in
            safeFilterPub.send(value)
        }.store(in: &cancellables)
        
        input.dangerFilter.sink { value in
            dangerFilterPub.send(value)
        }.store(in: &cancellables)
        
        safeFilterPub
            .sink { [weak self] filter in
                guard let self = self else { return }

                let (center, altitude) = self.latestLocationAndZoom.value
                let isZoomedIn = altitude < 3000
                if isZoomedIn {
                    let safeObjects = repository.getSafeArea(latitude: center.latitude, longitude: center.longitude)
                    let safeAnnotations: [SafeAnnotation] = safeObjects.compactMap { SafeAnnotation(from: $0) }
                    safePub.send(filter ? safeAnnotations : [])
                } else {
                    safePub.send([])
                }
            }
            .store(in: &cancellables)
        
        dangerFilterPub
            .sink { [weak self] filter in
                guard let self = self else { return }

                let (center, altitude) = self.latestLocationAndZoom.value
                let isZoomedIn = altitude < 3000
                if isZoomedIn {
                    let dangerObjects = repository.getDangerArea(latitude: center.latitude, longitude: center.longitude)
                    let dangerAnnotations: [DangerAnnotation] = dangerObjects.compactMap { DangerAnnotation(from: $0) }
                    dangerPub.send(filter ? dangerAnnotations : [])
                } else {
                    dangerPub.send([])
                }
            }
            .store(in: &cancellables)
        
        locationAndZoom
            .handleEvents(receiveOutput: { [weak latestLocationAndZoom] value in
                    latestLocationAndZoom?.send(value)
                })
            .sink { [weak self] (center, altitude) in
                guard let self = self else { return }
                
                let isZoomedIn = altitude < 3000 // Temporary Zoom at this point, need to be fixed later
                
                if isZoomedIn {
                    let safeObjects = repository.getSafeArea(latitude: center.latitude, longitude: center.longitude)
                    let dangerObjects = repository.getDangerArea(latitude: center.latitude, longitude: center.longitude)
                    
                    let safeAnnotations: [SafeAnnotation] = safeObjects.compactMap { SafeAnnotation(from: $0) }
                    let dangerAnnotations: [DangerAnnotation] = dangerObjects.compactMap { DangerAnnotation(from: $0) }
                    
                    let centerLatIndex = Int(center.latitude * 1000)
                    let centerLngIndex = Int(center.longitude * 1000)
                    
                    let sortedNearbyObjects = safeObjects
                        .filter { obj in
                            obj.latIndex != nil && obj.latIndex != nil
                        }
                        .map { obj -> (object: SafeParkingArea, distance: Int) in
                            let dLat = obj.latIndex! - centerLatIndex
                            let dLng = obj.lngIndex! - centerLngIndex
                            let distance = dLat * dLat + dLng * dLng // 유클리디안 거리 제곱
                            return (object: obj, distance: distance)
                        }
                        .sorted(by: { $0.distance < $1.distance })
                        .prefix(20)
                        .map { $0.object }
                    
                    safePub.send(safeFilterPub.value ? safeAnnotations : [])
                    dangerPub.send(dangerFilterPub.value ? dangerAnnotations : [])
                    
                    parkingPub.send(sortedNearbyObjects)
                    
                    print("중심 위치: \(center.latitude), \(center.longitude)")
                    print("찾은 주차장 개수: \(safeObjects.count)")
                    print("찾은 금지구역 개수: \(dangerObjects.count)")
                } else {
                    // for zoom-out, only emits clustering info.
                    safePub.send([])
                    dangerPub.send([])
                }
            }
            .store(in: &cancellables)
        
        input.selectedParking
            .filter { $0.latitude != nil && $0.longitude != nil }
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .flatMap { [weak self] info in
                NetworkManager.shared.callRequest(KakaoRouter.transcoord(lat: info.latitude!, lot: info.longitude!), decodeType: CoordConvertResponse.self)
                    .tryMap { response in
                        guard let result = response.documents.first else {
                            throw URLError(.badServerResponse)
                        }
                        
                        return NavigationData(
                            title: info.address,
                            x: "\(result.x)",
                            y: "\(result.y)"
                        )
                    }
                    .eraseToAnyPublisher()
            }.sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("좌표 변환 실패: \(error)")
                }
            }, receiveValue: { navigationData in
                convertedAddressPub.send(navigationData)
            })
            .store(in: &cancellables)
        
        return Output(
            safeAnnotations: safePub.eraseToAnyPublisher(),
            dangerAnnotations: dangerPub.eraseToAnyPublisher(),
            addressInformation: addressPub.eraseToAnyPublisher(),
            parkingInformation: parkingPub.eraseToAnyPublisher(),
            convertedLocation: convertedAddressPub.eraseToAnyPublisher(),
            safeFilterCondition: safeFilterPub.eraseToAnyPublisher(),
            dangerFilterCondition: dangerFilterPub.eraseToAnyPublisher()
        )
    }
}

struct NavigationData {
    var title : String
    var x: String
    var y: String
}
