//
//  ClusterAnnotation.swift
//  ParkRadar
//
//  Created by marty.academy on 4/3/25.
//

import MapKit

final class ClusterAnnotation: NSObject, MKAnnotation {
    let identifier : String // danger or safe
    let coordinate: CLLocationCoordinate2D
    let count: Int
    
    init(identifier: String, coordinate: CLLocationCoordinate2D, count: Int) {
        self.identifier = identifier
        self.coordinate = coordinate
        self.count = count
    }

    var title: String? {
        "\(count)개"
    }
}

struct ClusterSummary {
    let coordinate: CLLocationCoordinate2D
    let count: Int
    let geohash: String
}

extension Collection where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}


