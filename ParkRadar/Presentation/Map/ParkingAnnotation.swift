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
    let symbolName: String

    init(from model: SafeParkingArea) {
        self.coordinate = CLLocationCoordinate2D(latitude: model.latitude ?? 0, longitude: model.longitude ?? 0)
        self.title = model.name
        self.subtitle = model.address
        self.symbolName = "car.2.fill"
    }
}

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

class ParkingAnnotationView: MKAnnotationView {
    
    static let identifier = "ParkingAnnotationView"

    private let imageView = UIImageView()
    private let titleLabel = UILabel()

    override var annotation: MKAnnotation? {
        didSet {
            guard let parking = annotation as? ParkInfoAnnotation else { return }
            imageView.image = parking.image ?? UIImage(systemName: parking.symbolName)
            titleLabel.text = parking.title
        }
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func setupUI() {
        frame = CGRect(x: 0, y: 0, width: 120, height: 120)
        canShowCallout = false // 기본 callout은 off

        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true

        titleLabel.font = .systemFont(ofSize: 12)
        titleLabel.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        stack.frame = bounds

        addSubview(stack)
    }
}

