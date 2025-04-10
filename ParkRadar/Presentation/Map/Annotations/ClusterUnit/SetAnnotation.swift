//
//  ClusterAnnotation.swift
//  ParkRadar
//
//  Created by marty.academy on 4/3/25.
//

import MapKit

protocol RadarAnnotaion: MKAnnotation {}

final class DangerSetAnnotation: NSObject, RadarAnnotaion {
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

class DangerSetAnnotationView: MKMarkerAnnotationView {

    static let ReuseID = "dangerSet"

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "dangerSetCluster"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultHigh
        markerTintColor = UIColor.systemRed
        glyphImage = UIImage(systemName: "eye.fill")
    }
}

final class SafeSetAnnotation: NSObject, RadarAnnotaion {
    
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

class SafeSetAnnotationView: MKMarkerAnnotationView {
    static let ReuseID = "safeSet"

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "safeSetCluster"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultHigh
        markerTintColor = UIColor.safeInfo
        glyphImage = UIImage(systemName: "car.2.fill")
    }
}

extension Collection where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
