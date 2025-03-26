//
//  ParkingAnnotation.swift
//  ParkRadar
//
//  Created by marty.academy on 3/26/25.
//

import MapKit

class ParkingAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}


