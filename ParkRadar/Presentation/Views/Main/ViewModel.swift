import Foundation
import Combine
import RealmSwift
import CoreLocation
import MapKit

final class MapViewModel {
    
    let geocodingService = GeocodingService()
    
    let repository = Repository()
    
    var notificationToken : NotificationToken?
    
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
        
        let clusters: AnyPublisher<[ClusterAnnotation], Never>
        
        let addressInformation: AnyPublisher<String, Never>
        let parkingInformation: AnyPublisher<[SafeParkingArea], Never>
        let convertedLocation: AnyPublisher<NavigationData, Never>
        
        let safeFilterCondition: AnyPublisher<Bool, Never>
        let dangerFilterCondition: AnyPublisher<Bool, Never>
        
        let parkedLocation: AnyPublisher<ParkedLocation?, Never>
        let isDangerInformation : AnyPublisher<Bool, Never>
    }
    
    let latestLocationAndZoom = CurrentValueSubject<(CLLocationCoordinate2D, CLLocationDistance), Never>((.init(), 0))
    
    private var cancellables = Set<AnyCancellable>()
    
    func bind(input: Input) -> Output {
        let locationAndZoom = input.currentCenter
            .combineLatest(input.currentAltitude)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        
        let safePub = PassthroughSubject<[SafeAnnotation], Never>()
        let dangerPub = PassthroughSubject<[DangerAnnotation], Never>()
        
        let clusterPub = PassthroughSubject<[ClusterAnnotation], Never>()
        
        let addressPub = PassthroughSubject<String, Never>()
        let parkingPub = PassthroughSubject<[SafeParkingArea], Never>()
        let convertedAddressPub = PassthroughSubject<NavigationData, Never>()
        
        let safeFilterPub = CurrentValueSubject<Bool, Never>(true)
        let dangerFilterPub = CurrentValueSubject<Bool, Never>(true)
        
        let parkedInfoPub = CurrentValueSubject<ParkedLocation?, Never>(nil)
        
        let isDangerInfoPub = CurrentValueSubject<Bool, Never>(false)
        
        makeRealmDataSeq(in: parkedInfoPub)
        
        //        repository.showFilePath() //for debugging
        
        input.currentLocation
            .flatMap { location in
                self.geocodingService.reverseGeocode(location: location)
            }
            .sink { [weak self]address in
                if let address {
                    let filtered = self?.checkDuplicateText(address)
                    addressPub.send(filtered!)
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
                
                let safeObjects = repository.getSafeArea(latitude: center.latitude, longitude: center.longitude, altitude: altitude)
                let safeAnnotations: [SafeAnnotation] = safeObjects.compactMap { SafeAnnotation(from: $0) }
                
                //클러스터를 고려해야한다.
                if altitude > 10000 {
                    
                } else {
                    safePub.send(filter ? safeAnnotations : [])
                }
            }
            .store(in: &cancellables)
        
        dangerFilterPub
            .sink { [weak self] filter in
                guard let self = self else { return }
                
                let (center, altitude) = self.latestLocationAndZoom.value
                
                let dangerObjects = repository.getDangerArea(latitude: center.latitude, longitude: center.longitude, altitude: altitude)
                let dangerAnnotations: [DangerAnnotation] = dangerObjects.compactMap { DangerAnnotation(from: $0) }
                dangerPub.send(filter ? dangerAnnotations : [])
                
            }
            .store(in: &cancellables)
        
        locationAndZoom
            .handleEvents(receiveOutput: { [weak latestLocationAndZoom] value in
                latestLocationAndZoom?.send(value)
            })
            .sink { [weak self] (center, altitude) in
                guard let self = self else { return }
                
                if altitude <= 10000 {
                    clusterPub.send([])
                    
                    let safeObjects = repository.getSafeArea(latitude: center.latitude, longitude: center.longitude, altitude: altitude)
                    let dangerObjects = repository.getDangerArea(latitude: center.latitude, longitude: center.longitude, altitude: altitude)
                    let isDanger = repository.isCurrentLocationDangerous(latitude: center.latitude, longitude: center.longitude)
                    
                    let safeAnnotations: [SafeAnnotation] = safeObjects.compactMap { SafeAnnotation(from: $0) }
                    let dangerAnnotations: [DangerAnnotation] = dangerObjects.compactMap { DangerAnnotation(from: $0) }
                    
                    let sortedNearbyObjects = repository.getClosestParkingAreas(latitude: center.latitude, longitude: center.longitude)
                    
                    safePub.send(safeFilterPub.value ? safeAnnotations : [])
                    dangerPub.send(dangerFilterPub.value ? dangerAnnotations : [])
                    isDangerInfoPub.send(isDanger)
                    
                    parkingPub.send(sortedNearbyObjects)
                    
                } else {
                    safePub.send([])
                    dangerPub.send([])
                    
                    let precision = 5 // available to control value based on altitude
                    let safeAll = repository.getSafeAreaCluster()
                    let dangeAll = repository.getDangerAreaCluster()
                    
                    var output : [ClusterAnnotation] = []
                    
                    if safeFilterPub.value {
                        let safeClusters = Dictionary(grouping: safeAll) { obj in
                            guard let geohash = obj.geohash else { return "" }
                            return String(geohash.prefix(precision))
                        }
                        
                        let summaries: [ClusterAnnotation] = safeClusters.map { (hash, group) in
                            let latAvg = group.compactMap { $0.latitude }.average
                            let lngAvg = group.compactMap { $0.longitude }.average
                            
                            let summary = ClusterSummary(
                                coordinate: CLLocationCoordinate2D(latitude: latAvg, longitude: lngAvg),
                                count: group.count,
                                geohash: String(hash)
                            )
                            
                            return ClusterAnnotation(identifier: "safeCluster", coordinate: summary.coordinate, count: summary.count)
                        }
                        
                        output.append(contentsOf: summaries)
                    }
                    
                    if dangerFilterPub.value {
                        let dangerCluster = Dictionary(grouping: dangeAll) { obj in
                            obj.geohash.prefix(precision)
                        }
                        
                        let summaries: [ClusterAnnotation] = dangerCluster.map { (hash, group) in
                            let latAvg = group.compactMap { $0.latitude }.average
                            let lngAvg = group.compactMap { $0.longitude }.average
                            let summary = ClusterSummary(
                                coordinate: CLLocationCoordinate2D(latitude: latAvg, longitude: lngAvg),
                                count: group.count,
                                geohash: String(hash)
                            )
                            return ClusterAnnotation(identifier: "dangerCluster", coordinate: summary.coordinate, count: summary.count)
                        }
                        output.append(contentsOf: summaries)
                    }
                    clusterPub.send(output)
                }
            }
            .store(in: &cancellables)
        
        input.selectedParking
            .filter { $0.latitude != nil && $0.longitude != nil }
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .flatMap { info in
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
            clusters: clusterPub.eraseToAnyPublisher(),
            addressInformation: addressPub.eraseToAnyPublisher(),
            parkingInformation: parkingPub.eraseToAnyPublisher(),
            convertedLocation: convertedAddressPub.eraseToAnyPublisher(),
            safeFilterCondition: safeFilterPub.eraseToAnyPublisher(),
            dangerFilterCondition: dangerFilterPub.eraseToAnyPublisher(),
            parkedLocation: parkedInfoPub.eraseToAnyPublisher(),
            isDangerInformation: isDangerInfoPub.eraseToAnyPublisher()
        )
    }
}

extension MapViewModel {
    private func checkDuplicateText(_ address: String) -> String {
        if address == "" {
            return ""
        }
        
        var arr = address.split(separator: " ")
        
        if arr[0] == arr[1] { // eliminate the duplicated "서울특별시" text in the address
            arr.removeFirst()
            return arr.joined(separator: " ")
        }
        
        return arr.joined(separator: " ")
    }
}

extension MapViewModel {
    private func makeRealmDataSeq(in subject: CurrentValueSubject<ParkedLocation?, Never>) {
        
        let parkedLocationRecords = repository.getParkedLocation()
        
        notificationToken = parkedLocationRecords.observe { changes in
            switch changes {
            case .initial(let results) :
                print(" Initial — count: \(results.count)")
                subject.send(results.first)
            case .update(let results, let deletions, let insertions, let modifications) :
                print(" Update — D:\(deletions), I:\(insertions), M:\(modifications), count: \(results.count)")
                if results.isEmpty {
                    subject.send(nil)
                } else {
                    subject.send(results.first)
                }
            case .error(let error) :
                print("[Error]repository observer failed", error)
            }
        }
    }
}

struct NavigationData {
    var title : String
    var x: String
    var y: String
}
