//
//  ViewController.swift
//  ParkRadar
//
//  Created by marty.academy on 3/26/25.
//

import UIKit
import MapKit
import CoreLocation
import Combine

final class MapViewController: UIViewController {

    private let mainView = MainView()
    private let locationManager = CLLocationManager()
    private let viewModel = MapViewModel()

    private var cancellables = Set<AnyCancellable>()

    private let currentCenterSubject = CurrentValueSubject<CLLocationCoordinate2D, Never>(.init())
    private let currentAltitudeSubject = CurrentValueSubject<CLLocationDistance, Never>(0)
    
    private let zoneRadius: CLLocationDistance = 100 // overlayRadius for presentation

    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationAppearance()
        setupMapView()
        setupLocationManager()
        bindViewModel()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let sheet = MultiStepBottomSheet()
        sheet.attach(to: self.view)
    }

    private func setupMapView() {
        mainView.mapView.frame = view.bounds
        mainView.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        mainView.mapView.delegate = self
        mainView.mapView.showsUserLocation = true
    }

    private func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }

    private func bindViewModel() {
        let input = MapViewModel.Input(
            currentCenter: currentCenterSubject.eraseToAnyPublisher(),
            currentAltitude: currentAltitudeSubject.eraseToAnyPublisher()
        )

        let output = viewModel.bind(input: input)

        output.safeAnnotations
            .receive(on: RunLoop.main)
            .sink { [weak self] annotations in
                self?.updateAnnotations(ofType: SafeAnnotation.self, with: annotations)
            }
            .store(in: &cancellables)

        output.dangerAnnotations
            .receive(on: RunLoop.main)
            .sink { [weak self] annotations in
                self?.updateAnnotations(ofType: DangerAnnotation.self, with: annotations)
            }
            .store(in: &cancellables)
    }

    private func updateAnnotations<T: MKAnnotation>(ofType type: T.Type, with newAnnotations: [T]) {
        let existing = mainView.mapView.annotations.compactMap { $0 as? T }
        mainView.mapView.removeAnnotations(existing)

        let overlaysToRemove = mainView.mapView.overlays.compactMap { $0 as? MKCircle }.filter { circle in
            newAnnotations.contains { annotation in
                circle.coordinate.latitude == annotation.coordinate.latitude &&
                circle.coordinate.longitude == annotation.coordinate.longitude
            }
        }
        mainView.mapView.removeOverlays(overlaysToRemove)

        mainView.mapView.addAnnotations(newAnnotations)

        for annotation in newAnnotations {
            let circle = MKCircle(center: annotation.coordinate, radius: zoneRadius)
            mainView.mapView.addOverlay(circle)
        }
    }
}

extension MapViewController {
    func configureNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()

        appearance.backgroundColor = Color.Back.main.ui
        appearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }

        let coordinate = location.coordinate
        let region = MKCoordinateRegion(center: coordinate,
                                        latitudinalMeters: 1000,
                                        longitudinalMeters: 1000)
        mainView.mapView.setRegion(region, animated: true)

        currentCenterSubject.send(coordinate)
        currentAltitudeSubject.send(mainView.mapView.camera.altitude)

        locationManager.stopUpdatingLocation()
    }
}

extension MapViewController: MKMapViewDelegate {
    
    
    // MARK: - Annotation View
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        if let cluster = annotation as? MKClusterAnnotation {
            let identifier = "Cluster"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: cluster, reuseIdentifier: identifier)

            view.markerTintColor = .systemGray
            view.glyphText = "\(cluster.memberAnnotations.count)"
            view.displayPriority = .required
            return view
        }

        if annotation is SafeAnnotation {
            let identifier = "SafeAnnotation"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)

            view.canShowCallout = true
            view.clusteringIdentifier = "parking"
            view.markerTintColor = .systemGreen
            view.glyphText = "P"
            return view
        }

        if annotation is DangerAnnotation {
            let identifier = "DangerAnnotation"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)

            view.canShowCallout = true
            view.clusteringIdentifier = "danger"
            view.markerTintColor = .systemRed
            view.glyphText = "!"
            return view
        }

        return nil
    }

    // MARK: - Overlay View (예: 반경 표시)
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let circle = overlay as? MKCircle else {
            return MKOverlayRenderer(overlay: overlay)
        }

        let isDanger = mapView.annotations.contains(where: { annotation in
            guard let danger = annotation as? DangerAnnotation else { return false }
            return danger.coordinate.latitude == circle.coordinate.latitude &&
                   danger.coordinate.longitude == circle.coordinate.longitude
        })

        let renderer = MKCircleRenderer(circle: circle)
        renderer.lineWidth = 1

        if isDanger {
            renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.1)
            renderer.strokeColor = UIColor.systemRed.withAlphaComponent(0.4)
        } else {
            renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.1)
            renderer.strokeColor = UIColor.systemGreen.withAlphaComponent(0.4)
        }

        return renderer
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        currentCenterSubject.send(mapView.centerCoordinate)
        currentAltitudeSubject.send(mapView.camera.altitude)
    }
}
