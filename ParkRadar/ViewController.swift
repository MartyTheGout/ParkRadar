//
//  ViewController.swift
//  ParkRadar
//
//  Created by marty.academy on 3/26/25.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    private let mapView = MKMapView()
    private let locationManager = CLLocationManager()
    private let mapCoordinator = MapCoordinator()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        requestLocationAccess()
        mapCoordinator.setupAnnotations(on: mapView)
    }

    private func setupMapView() {
        view.addSubview(mapView)
        mapView.frame = view.bounds
        mapView.delegate = mapCoordinator
        mapView.showsUserLocation = true
    }

    private func requestLocationAccess() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
}
