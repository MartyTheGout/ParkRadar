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
//        setupLocationManager()
    }
    
//    private func setupLocationManager() {
//        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.requestWhenInUseAuthorization()
//        locationManager.startUpdatingLocation()
//    }
    
    // MARK: - Public Methods
    func setImage(_ image: UIImage) {
        imageSubject.send(image)
    }
    
    func saveLocation() {
        guard let location = locationSubject.value, let image = imageSubject.value else {
            print("Location or image is missing")
            return
        }
        
        // Here you would implement your Realm saving logic
        // For example:
        // let locationRecord = LocationRecord()
        // locationRecord.latitude = location.coordinate.latitude
        // locationRecord.longitude = location.coordinate.longitude
        // locationRecord.memo = memo
        // locationRecord.imageData = image.jpegData(compressionQuality: 0.7)
        // try? realm.write {
        //     realm.add(locationRecord)
        // }
    
    }
}
//
//// MARK: - CLLocationManagerDelegate
//extension LocationPhotoViewModel: CLLocationManagerDelegate {
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        if let location = locations.last {
//            locationSubject.send(location)
//            // We only need one location update for this use case
//            locationManager.stopUpdatingLocation()
//        }
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
//        print("Location manager failed with error: \(error.localizedDescription)")
//    }
//}
