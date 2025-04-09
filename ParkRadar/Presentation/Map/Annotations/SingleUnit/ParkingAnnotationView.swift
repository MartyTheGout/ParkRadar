//
//  ParkingAnnotationView.swift
//  ParkRadar
//
//  Created by marty.academy on 4/9/25.
//

import MapKit

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
