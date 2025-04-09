//
//  SafeAnnotation.swift
//  ParkRadar
//
//  Created by marty.academy on 4/9/25.
//

import MapKit

final class SafeAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let symbolName: String

    init(from model: SafeParkingArea) {
        self.coordinate = CLLocationCoordinate2D(latitude: model.latitude ?? 0, longitude: model.longitude ?? 0)
        self.title = model.name
        self.subtitle = model.address
        self.symbolName = "car.2.fill"
    }
}

