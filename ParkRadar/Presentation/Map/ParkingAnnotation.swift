//
//  ParkingAnnotation.swift
//  ParkRadar
//
//  Created by marty.academy on 3/26/25.
//

import MapKit

final class SafeAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?

    init(from model: SafeParkingArea) {
        self.coordinate = CLLocationCoordinate2D(latitude: model.latitude ?? 0, longitude: model.longitude ?? 0)
        self.title = model.name
        self.subtitle = model.address
    }
}

final class DangerAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?

    init(from model: NoParkingArea) {
        self.coordinate = CLLocationCoordinate2D(latitude: model.latitude, longitude: model.longitude)
        self.title = model.district
        self.subtitle = model.descriptionText
    }
}
