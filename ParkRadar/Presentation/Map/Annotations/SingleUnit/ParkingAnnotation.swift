//
//  ParkingAnnotation.swift
//  ParkRadar
//
//  Created by marty.academy on 3/26/25.
//

import MapKit

final class ParkInfoAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let image: UIImage?
    let symbolName: String

    init(from model: ParkedLocation) {
        self.coordinate = CLLocationCoordinate2D(latitude: model.latitude, longitude: model.longitude)
        self.title = model.title
        self.symbolName = "pin.fill"
        self.image = ImageHandler().loadImageFromDocument(filename: model.imagePath ?? "")
    }
}
