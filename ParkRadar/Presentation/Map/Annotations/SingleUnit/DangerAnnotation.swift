//
//  DangerAnnotation.swift
//  ParkRadar
//
//  Created by marty.academy on 4/9/25.
//

import MapKit

final class DangerAnnotation: NSObject, RadarAnnotaion {
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

class DangerAnnotationView: MKMarkerAnnotationView {

    static let ReuseID = "dangerAnnotation"

    /// - Tag: ClusterIdentifier
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "danger"
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
