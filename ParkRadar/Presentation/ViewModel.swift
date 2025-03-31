import Foundation
import Combine
import RealmSwift
import CoreLocation
import MapKit

final class MapViewModel: ObservableObject {
    struct Input {
        let currentCenter: AnyPublisher<CLLocationCoordinate2D, Never>
        let currentAltitude: AnyPublisher<CLLocationDistance, Never>
    }

    struct Output {
        let safeAnnotations: AnyPublisher<[SafeAnnotation], Never>
        let dangerAnnotations: AnyPublisher<[DangerAnnotation], Never>
    }

    private var cancellables = Set<AnyCancellable>()
    private let realm = try! Realm()

    func bind(input: Input) -> Output {
        let locationAndZoom = input.currentCenter
            .combineLatest(input.currentAltitude)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)

        let safePub = PassthroughSubject<[SafeAnnotation], Never>()
        let dangerPub = PassthroughSubject<[DangerAnnotation], Never>()

        locationAndZoom
            .sink { [weak self] (center, altitude) in
                guard let self = self else { return }

                let isZoomedIn = altitude < 3000 // Temporary Zoom at this point, need to be fixed later

                if isZoomedIn {
                    let latMin = Int((center.latitude - 0.01) * 1000)
                    let latMax = Int((center.latitude + 0.01) * 1000)
                    let lngMin = Int((center.longitude - 0.01) * 1000)
                    let lngMax = Int((center.longitude + 0.01) * 1000)

                    let safeObjects = self.realm.objects(SafeParkingArea.self)
                        .where {
                            $0.latIndex >= latMin && $0.latIndex <= latMax &&
                            $0.lngIndex >= lngMin && $0.lngIndex <= lngMax
                        }

                    let dangerObjects = self.realm.objects(NoParkingArea.self)
                        .where {
                            $0.latInt >= latMin && $0.latInt <= latMax &&
                            $0.lngInt >= lngMin && $0.lngInt <= lngMax
                        }

                    let safeAnnotations: [SafeAnnotation] = safeObjects.compactMap { SafeAnnotation(from: $0) }
                    let dangerAnnotations: [DangerAnnotation] = dangerObjects.compactMap { DangerAnnotation(from: $0) }

                    safePub.send(safeAnnotations)
                    dangerPub.send(dangerAnnotations)
                    
                    print("중심 위치: \(center.latitude), \(center.longitude)")
                    print("lat 범위: \(latMin) ~ \(latMax)")
                    print("lng 범위: \(lngMin) ~ \(lngMax)")
                    print("찾은 주차장 개수: \(safeObjects.count)")
                    print("찾은 금지구역 개수: \(dangerObjects.count)")
                } else {
                    // for zoom-out, only emits clustering info. 
                    safePub.send([])
                    dangerPub.send([])
                    print("ddddd")
                }
            }
            .store(in: &cancellables)

        return Output(
            safeAnnotations: safePub.eraseToAnyPublisher(),
            dangerAnnotations: dangerPub.eraseToAnyPublisher()
        )
    }
}

