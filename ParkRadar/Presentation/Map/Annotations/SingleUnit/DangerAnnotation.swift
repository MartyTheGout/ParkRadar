//
//  DangerAnnotation.swift
//  ParkRadar
//
//  Created by marty.academy on 4/9/25.
//

import MapKit

final class DangerAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let symbolName: String

    init(from model: NoParkingArea) {
        self.coordinate = CLLocationCoordinate2D(latitude: model.latitude, longitude: model.longitude)
        self.title = model.district
        self.subtitle = model.descriptionText
        self.symbolName = "eye.fill"
    }
}
