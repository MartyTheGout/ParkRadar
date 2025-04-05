//
//  ParkLocation.swift
//  ParkRadar
//
//  Created by marty.academy on 4/5/25.
//

import Foundation
import MapKit
import Combine

class LocationPhotoViewModel: NSObject {
    // MARK: - Properties
    private let repository = Repository()
    
    private let locationManager = CLLocationManager()
    
    private var locationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
    private var imageSubject = CurrentValueSubject<UIImage?, Never>(nil)
    private var addressSubject = CurrentValueSubject<String, Never>("")
    
    var currentLocation: AnyPublisher<CLLocation?, Never> {
        return locationSubject.eraseToAnyPublisher()
    }
    
    var address: AnyPublisher<String, Never> {
        return addressSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(location : CLLocation, address: String) {
        super.init()
        
        locationSubject.send(location)
        addressSubject.send(address)
    }
    
    // MARK: - Public Methods
    func setImage(_ image: UIImage) {
        imageSubject.send(image)
    }
    
    func saveLocation() {
        guard let location = locationSubject.value, let image = imageSubject.value else {
            print("Location or image is missing")
            return
        }
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let fileName = "parkedInfo"
        
        let fileURL = documentDirectory.appendingPathComponent("\(fileName).jpg")
        removeImageFromDocument(filename: fileName)
        
        guard let data = image.jpegData(compressionQuality: 0.5) else { return }
        
        do {
            try data.write(to: fileURL)
        } catch {
            print("이미지 저장 실패")
        }
        
        let parkedLocation = ParkedLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, imagePath: fileURL.path())
        
        repository.saveParkedLocation(parkedLocation)
    }
}

extension LocationPhotoViewModel {
    func loadImageFromDocument(filename: String) -> UIImage? {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        
        let fileURL = documentDirectory.appendingPathComponent("\(filename).jpg")
        
        if FileManager.default.fileExists(atPath: fileURL.path()) {
            return UIImage(contentsOfFile: fileURL.path())
        } else {
            return UIImage(systemName: "star")
        }
    }
    
    func removeImageFromDocument(filename: String) {
        guard let documentDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask).first else { return }
        
        let fileURL = documentDirectory.appendingPathComponent("\(filename).jpg")
        
        if FileManager.default.fileExists(atPath: fileURL.path()) {
            do {
                try FileManager.default.removeItem(atPath: fileURL.path())
            } catch {
                print("file remove error", error)
            }
        } else {
            print("file no exist")
        }
    }
}
