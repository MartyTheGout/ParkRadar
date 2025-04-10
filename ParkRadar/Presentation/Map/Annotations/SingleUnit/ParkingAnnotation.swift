//
//  ParkingAnnotation.swift
//  ParkRadar
//
//  Created by marty.academy on 3/26/25.
//

import MapKit

final class ParkInfoAnnotation: NSObject, RadarAnnotaion {
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

class ParkInfoAnnotationView: MKMarkerAnnotationView {

    static let ReuseID = "parkingAnnotation"

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "parking"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()
        displayPriority = .defaultHigh
        markerTintColor = UIColor.systemOrange
        glyphImage = UIImage(systemName: "pin.fill")
    }
}
