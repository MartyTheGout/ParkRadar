//
//  GeocodingService.swift
//  ParkRadar
//
//  Created by marty.academy on 4/1/25.
//

import MapKit
import Combine

final class GeocodingService {
    func reverseGeocode(location: CLLocation) -> AnyPublisher<String?, Never> {
        Future { promise in
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first {
                    let address = [
                        placemark.administrativeArea, // 예: 서울특별시
                        placemark.locality,           // 예: 강북구
                        placemark.thoroughfare,       // 예: 노해로
                        placemark.subThoroughfare     // 예: 990
                    ]
                    .compactMap { $0 }
                    .joined(separator: " ")
                    
                    promise(.success(address))
                } else {
                    promise(.success(nil))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
