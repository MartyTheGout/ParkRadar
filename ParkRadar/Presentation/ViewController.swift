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
import KakaoSDKNavi

final class MapViewController: UIViewController {
    
    private let mainView = MainView()
    private let bottomView = MultiStepBottomSheet()
    private let locationManager = CLLocationManager()
    private let viewModel = MapViewModel()
    
    private var cancellables = Set<AnyCancellable>()
    
    private let currentLocationSubject = CurrentValueSubject<CLLocation, Never>(.init())
    private let currentCenterSubject = CurrentValueSubject<CLLocationCoordinate2D, Never>(.init())
    private let currentAltitudeSubject = CurrentValueSubject<CLLocationDistance, Never>(0)
    private let selectedParkingSubject = CurrentValueSubject<SafeParkingArea, Never>(.init())
    
    private let safeFilterSubject = CurrentValueSubject<Bool, Never>(true)
    private let dangerFilterSubject = CurrentValueSubject<Bool, Never>(true)
    
    private let zoneRadius: CLLocationDistance = 50 // overlayRadius for presentation
    
    private var parkingInfo:[SafeParkingArea] = []
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationAppearance()
        setupMapView()
        setupLocationManager()
        bindViewModel()
        setupCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bottomView.attach(to: self.view)
    }
    
    private func setupMapView() {
        mainView.mapView.frame = view.bounds
        mainView.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        mainView.mapView.delegate = self
        mainView.mapView.showsUserLocation = true
        
        mainView.mapView.overrideUserInterfaceStyle = .dark // 이건 UI 요소용 (효과 제한적)
        mainView.mapView.mapType = .mutedStandard
        
        mainView.upperTabView.noParkShowingButton.addTarget(self, action: #selector(zoomOutToSeoulWithDangerZone), for: .touchUpInside)
        mainView.upperTabView.safeParkShowingButton.addTarget(self, action: #selector(zoomOutToSeoulWithSafeZone), for: .touchUpInside)
        mainView.upperTabView.illegalExplanationButton.addTarget(self, action: #selector(goToFineDetailViewController), for: .touchUpInside)
        
        mainView.dangerFilterButton.addTarget(self, action: #selector(toggleDangerFilter), for: .touchUpInside)
        mainView.safeFilterButton.addTarget(self, action: #selector(toggleSafeFilter), for: .touchUpInside)
        mainView.userLocationButton.addTarget(self, action: #selector(moveMapViewToCurrentLocation), for: .touchUpInside)
    }
    
    private func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    private func bindViewModel() {
        let input = MapViewModel.Input(
            currentCenter: currentCenterSubject.eraseToAnyPublisher(),
            currentAltitude: currentAltitudeSubject.eraseToAnyPublisher(),
            currentLocation: currentLocationSubject.eraseToAnyPublisher(),
            selectedParking: selectedParkingSubject.eraseToAnyPublisher(),
            safeFilter: safeFilterSubject.eraseToAnyPublisher(),
            dangerFilter: dangerFilterSubject.eraseToAnyPublisher()
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
        
        output.clusters
            .receive(on: RunLoop.main)
            .sink { [weak self] clusterAnnotations in
                self?.updateAnnotations(ofType: ClusterAnnotation.self, with: clusterAnnotations)
            }
            .store(in: &cancellables)
        
        output.addressInformation
            .receive(on: RunLoop.main)
            .sink { [weak self] address in
                self?.bottomView.updateCurrentAddress(with: address)
            }
            .store(in: &cancellables)
        
        output.parkingInformation
            .receive(on: RunLoop.main)
            .sink { [weak self] parkings in
                self?.updateCollection(with: parkings)
            }.store(in: &cancellables)
        
        output.convertedLocation
            .receive(on: RunLoop.main)
            .sink{ [weak self] navigationData in
                dump(navigationData)
                self?.goToNavigation(with: navigationData)
                
            }.store(in: &cancellables)
        
    }
    
    private func updateAnnotations<T: MKAnnotation>(ofType type: T.Type, with newAnnotations: [T]) {
        
        let existing = mainView.mapView.annotations.compactMap { $0 as? T }
        
        let toAdd = newAnnotations.filter { new in
            !existing.contains(where: { $0.coordinate.latitude == new.coordinate.latitude && $0.coordinate.longitude == new.coordinate.longitude })
        }
        
        let toRemove = existing.filter { existingAnno in
            !newAnnotations.contains(where: { $0.coordinate.latitude == existingAnno.coordinate.latitude && $0.coordinate.longitude == existingAnno.coordinate.longitude })
        }
        
        mainView.mapView.removeAnnotations(toRemove)
        
        let overlaysToRemove = mainView.mapView.overlays.compactMap { $0 as? MKCircle }.filter { circle in
            toRemove.contains { annotation in
                circle.coordinate.latitude == annotation.coordinate.latitude &&
                circle.coordinate.longitude == annotation.coordinate.longitude
            }
        }
        
        mainView.mapView.removeOverlays(overlaysToRemove)
        
        mainView.mapView.addAnnotations(toAdd)
        
        let radius = type is ClusterAnnotation.Type ? 1800 : zoneRadius
        
        for annotation in toAdd {
            let circle = MKCircle(center: annotation.coordinate, radius: radius)
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
        
        appearance.backgroundEffect = UIBlurEffect(style: .light)
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
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
        
        currentLocationSubject.send(location)
        currentCenterSubject.send(coordinate)
        currentAltitudeSubject.send(mainView.mapView.camera.altitude)
        
        mainView.mapView.camera.centerCoordinateDistance = 2000 // customize intial altitude of the camera.
        
        locationManager.stopUpdatingLocation()
    }
}

extension MapViewController: MKMapViewDelegate {
    
    
    // MARK: - Annotation View
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        if let cluster = annotation as? ClusterAnnotation {
            let identifier = "Cluster"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: cluster, reuseIdentifier: identifier)
            
            view.canShowCallout = true
            view.clusteringIdentifier = "parkingCluster"
            view.markerTintColor = cluster.identifier == "safeCluster" ? Color.Subject.safe.ui : .systemRed
            
            view.glyphImage = cluster.identifier == "safeCluster" ? UIImage(systemName: "car.2.fill") : UIImage(systemName: "eye.fill") // ! glyphImage is applied to Annotation firstly, then glyphText
            
            return view
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
        
        if let safe = annotation as? SafeAnnotation {
            let identifier = "SafeAnnotation"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: safe, reuseIdentifier: identifier)
            
            view.canShowCallout = true
            view.clusteringIdentifier = "parking"
            view.markerTintColor = Color.Subject.safe.ui
            
            if let symbolImage = UIImage(systemName: safe.symbolName) {
                view.glyphImage = symbolImage // ! glyphImage is applied to Annotation firstly, then glyphText
            } else {
                view.glyphText = "P"
            }
            return view
        }
        
        if let danger = annotation as? DangerAnnotation {
            let identifier = "DangerAnnotation"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: danger, reuseIdentifier: identifier)
            
            view.canShowCallout = true
            view.clusteringIdentifier = "danger"
            view.markerTintColor = .systemRed
            
            if let symbolImage = UIImage(systemName: danger.symbolName) {
                view.glyphImage = symbolImage
            } else {
                view.glyphText = "!"
            }
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
            if let danger = annotation as? DangerAnnotation {
                return danger.coordinate.latitude == circle.coordinate.latitude &&
                danger.coordinate.longitude == circle.coordinate.longitude
            }
            
            if let danger = annotation as? ClusterAnnotation {
                if danger.identifier == "dangerCluster" {
                    return danger.coordinate.latitude == circle.coordinate.latitude &&
                    danger.coordinate.longitude == circle.coordinate.longitude
                }
            }
            
            return false
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
        print("altitude : \(mapView.camera.altitude)")
    }
}

//MARK: - CollectionView related
extension MapViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func setupCollectionView() {
        bottomView.collectionView.delegate = self
        bottomView.collectionView.dataSource = self
        bottomView.collectionView.register(ParkingInfoCell.self, forCellWithReuseIdentifier: ParkingInfoCell.reuseIdentifier)
    }
    
    func updateCollection(with items: [SafeParkingArea]) {
        self.parkingInfo = items
        bottomView.collectionView.reloadData()
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        parkingInfo.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ParkingInfoCell.reuseIdentifier,
            for: indexPath
        ) as? ParkingInfoCell else {
            return UICollectionViewCell()
        }
        
        let item = parkingInfo[indexPath.item]
        cell.configure(with: item)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = parkingInfo[indexPath.item]
        
        selectedParkingSubject.send(item)
    }
}

//MARK: - Actions
extension MapViewController {
    func goToNavigation(with data: NavigationData ) {
        let destination = NaviLocation(name: data.title, x: data.x, y: data.y)
        
        guard let navigateUrl = NaviApi.shared.navigateUrl(destination: destination) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(navigateUrl) {
            UIApplication.shared.open(navigateUrl, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.open(NaviApi.webNaviInstallUrl, options: [:], completionHandler: nil)
        }
    }
    
    @objc private func zoomOutToSeoulWithDangerZone() {
        let seoulCenter = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        
        let camera = MKMapCamera()
        camera.centerCoordinate = seoulCenter
        camera.altitude = 130000
        camera.pitch = 0
        camera.heading = 0
        
        safeFilterSubject.send(false)
        dangerFilterSubject.send(true)
        
        mainView.mapView.setCamera(camera, animated: true)
    }
    
    @objc private func zoomOutToSeoulWithSafeZone() {
        let seoulCenter = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
        
        let camera = MKMapCamera()
        camera.centerCoordinate = seoulCenter
        camera.altitude = 130000
        camera.pitch = 0
        camera.heading = 0
        
        safeFilterSubject.send(true)
        dangerFilterSubject.send(false)
        
        mainView.mapView.setCamera(camera, animated: true)
    }
    
    @objc func goToFineDetailViewController() {
        let destinationVC = FineDetailViewController()
        navigationItem.backButtonTitle = ""
        
        navigationController?.pushViewController(destinationVC, animated: true)
    }
    
    @objc func toggleSafeFilter() {
        let newValue = !safeFilterSubject.value
        safeFilterSubject.send(newValue)
    }
    
    @objc func toggleDangerFilter() {
        let newValue = !dangerFilterSubject.value
        dangerFilterSubject.send(newValue)
    }
    
    @objc private func moveMapViewToCurrentLocation() {
        let status = locationManager.authorizationStatus
        
        guard status == .authorizedWhenInUse || status == .authorizedAlways,
              let location = locationManager.location else {
            print("위치 정보 없음 또는 권한 미허용")
            return
        }
        
        let camera = MKMapCamera()
        camera.centerCoordinate = location.coordinate
        camera.altitude = 2000
        camera.pitch = 0
        camera.heading = 0
        
        safeFilterSubject.send(true)
        dangerFilterSubject.send(true)
        mainView.mapView.setCamera(camera, animated: true)
    }
}
