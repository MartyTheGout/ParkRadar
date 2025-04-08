//
//  ParkLocation.swift
//  ParkRadar
//
//  Created by marty.academy on 4/5/25.
//

import Foundation
import MapKit
import Combine

struct ParkedLocationPresentable {
    var latitude: Double
    var longitude: Double
    var title: String
    var imagePath: String?
}

class ParkLocationViewModel: NSObject {
    // MARK: - Properties
    private let repository = Repository()
    private let imageHandler = ImageHandler()
    
    private let locationManager = CLLocationManager()
    
    private var locationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
    private var imageSubject = CurrentValueSubject<UIImage?, Never>(nil)
    private var addressSubject = CurrentValueSubject<String, Never>("")

    var forSave = true
    
    // MARK: - Initialization
    init(parkedLocation: ParkedLocationPresentable) {
        super.init()
        
        let location = CLLocation(
            latitude: parkedLocation.latitude,
            longitude: parkedLocation.longitude
        )
        
        if let imagePath = parkedLocation.imagePath {
            let image = imageHandler.loadImageFromDocument(filename: imagePath)
            imageSubject.send(image)
            forSave = false
        }
         
        locationSubject.send(location)
        addressSubject.send(parkedLocation.title)
    }
    
    struct Input {}
    
    struct Output {
        var locationSeq : AnyPublisher<CLLocation?, Never>
        var imageSeq : AnyPublisher<UIImage?, Never>
        var addressSeq : AnyPublisher<String, Never>
    }
    
    func bind(_ input: Input) -> Output {
        return Output(
            locationSeq: locationSubject.eraseToAnyPublisher(),
            imageSeq: imageSubject.eraseToAnyPublisher(),
            addressSeq: addressSubject.eraseToAnyPublisher()
        )
    }
    
    
    // MARK: - Public Methods
    func setImage(_ image: UIImage) {
        imageSubject.send(image)
    }
    
    func saveLocation() {
        guard let location = locationSubject.value else {
            print("Location is missing")
            return
        }
        let fileName = "parkedInfo"
        
        if let image = imageSubject.value {
            imageHandler.saveImageToDocument(image: image, fileName: fileName)
        }
        
        let parkedLocation = ParkedLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            title: addressSubject.value,
            imagePath: fileName
        )
        
        repository.saveParkedLocation(parkedLocation)
    }
    
    func deleteLocation() {
        repository.deleteParkedLocation()
        imageHandler.removeImageFromDocument(filename: "parkedInfo")
    }
}
