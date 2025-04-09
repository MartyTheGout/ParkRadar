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
    
    private let viewModel: MapViewModel
    
    private let mainView = MainView()
    private let bottomView = MultiStepBottomSheet()
    private let locationManager = CLLocationManager()
    
    private var cancellables = Set<AnyCancellable>()
    private let currentLocationSubject = CurrentValueSubject<CLLocation, Never>(.init())
    private let currentCenterSubject = CurrentValueSubject<CLLocationCoordinate2D, Never>(.init())
    private let currentAltitudeSubject = CurrentValueSubject<CLLocationDistance, Never>(0)
    private let selectedParkingSubject = CurrentValueSubject<SafeParkingArea, Never>(.init())
    private let safeFilterSubject = CurrentValueSubject<Bool, Never>(true)
    private let dangerFilterSubject = CurrentValueSubject<Bool, Never>(true)
    
    private let zoneRadius: CLLocationDistance = 50 // overlayRadius for presentation
    
    private var parkingInfo:[SafeParkingArea] = []
    
    private var parkedLocation: ParkedLocation?
    
    private var mapStabilizerActivated = false // stabilizer's status value for having safer first map builder.
    
    init(viewModel: MapViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        setupParkLocationButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bottomView.attach(to: self.view)
        
        if !mapStabilizerActivated {
            mainView.userLocationButton.sendActions(for: .touchUpInside)
            mapStabilizerActivated = true
        }
    }
    
    private func setupMapView() {
        mainView.mapView.frame = view.bounds
        mainView.mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        mainView.mapView.delegate = self
        mainView.mapView.showsUserLocation = true
        
        mainView.upperTabView.noParkShowingButton.addTarget(self, action: #selector(zoomOutToSeoulWithDangerZone), for: .touchUpInside)
        mainView.upperTabView.safeParkShowingButton.addTarget(self, action: #selector(zoomOutToSeoulWithSafeZone), for: .touchUpInside)
        mainView.upperTabView.illegalExplanationButton.addTarget(self, action: #selector(goToFineDetailViewController), for: .touchUpInside)
        
        mainView.dangerFilterButton.addTarget(self, action: #selector(toggleDangerFilter), for: .touchUpInside)
        mainView.safeFilterButton.addTarget(self, action: #selector(toggleSafeFilter), for: .touchUpInside)
        mainView.userLocationButton.addTarget(self, action: #selector(moveMapViewToCurrentLocation), for: .touchUpInside)
        mainView.parkedLocationButton.addTarget(self, action: #selector(moveMapViewToParkedLocation), for: .touchUpInside)
    }
    
    private func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    private func setupParkLocationButton() {
        bottomView.parkSavingButton.addTarget(self, action: #selector(navigateParkLocationViewWithButton), for: .touchUpInside)
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
        
        output.parkedLocation
            .receive(on: RunLoop.main)
            .sink { [weak self] parkedInfo in
                guard let parkedInfo else {
                    self?.handlePakredInfoInteraction(hasInfo: false)
                    self?.parkedLocation = nil
                    self?.updateAnnotations(ofType: ParkInfoAnnotation.self, with: [])
                    return
                }
                
                self?.handlePakredInfoInteraction(hasInfo: true)
                self?.parkedLocation = parkedInfo
                self?.updateAnnotations(ofType: ParkInfoAnnotation.self, with: [ParkInfoAnnotation(from: parkedInfo)])
                
            }.store(in: &cancellables)
        
        output.isDangerInformation
            .receive(on: RunLoop.main)
            .sink { [weak self] isDanger in
                self?.handlerisDangerInfo(with: isDanger)
                
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
        
        appearance.backgroundColor = UIColor.mainBack
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
            view.markerTintColor = cluster.identifier == "safeCluster" ? UIColor.safeInfo : .systemRed
            
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
            view.markerTintColor = UIColor.safeInfo
            
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
        
        if let parkedInfo = annotation as? ParkInfoAnnotation {
            let identifier = "ParkInfoAnnotation"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: parkedInfo, reuseIdentifier: identifier)
            
            view.canShowCallout = true
            view.markerTintColor = .systemOrange
            
            if let symbolImage = UIImage(systemName: parkedInfo.symbolName) {
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
        
        let isParking = mapView.annotations.contains(where: { annotation in
            if let parking = annotation as? ParkInfoAnnotation {
                return parking.coordinate.latitude == circle.coordinate.latitude &&
                parking.coordinate.longitude == circle.coordinate.longitude
            }
            return false
        })
        
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
        
        if isParking {
            renderer.fillColor = UIColor.systemOrange.withAlphaComponent(0.1)
            renderer.strokeColor = UIColor.systemOrange.withAlphaComponent(0.4)
        } else if isDanger {
            renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.1)
            renderer.strokeColor = UIColor.systemRed.withAlphaComponent(0.4)
        } else {
            renderer.fillColor = UIColor.systemGreen.withAlphaComponent(0.1)
            renderer.strokeColor = UIColor.systemGreen.withAlphaComponent(0.4)
        }
        
        return renderer
    }
    
    //MARK: - Annotation Selection Handler
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let parking = view.annotation as? ParkInfoAnnotation else { return }
        
        let selectedAnnotation = parking
        let currentMapView = mapView
        
        presentParkLocationView(parkedLocation: parkedLocation) { [weak currentMapView, weak selectedAnnotation] in
            // dismiss 후 실행될 completion handler
            // selectedAnnotation이 여전히 있다면 선택 해제
            if let mapView = currentMapView, let annotation = selectedAnnotation {
                mapView.deselectAnnotation(annotation, animated: true)
            }
        }
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        currentCenterSubject.send(mapView.centerCoordinate)
        currentAltitudeSubject.send(mapView.camera.altitude)
        //        print("altitude : \(mapView.camera.altitude)")
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
        
        cell.onTapClosure = { [weak self] in
            self?.selectedParkingSubject.send(item)
        }
        
        return cell
    }
}

//MARK: - Actions
extension MapViewController {
    func goToNavigation(with data: NavigationData) {
        let alert = UIAlertController(title: "네비게이션 앱 선택", message: "원하는 앱을 선택하세요", preferredStyle: .actionSheet)
        
        let kakaoAction = UIAlertAction(title: "Kakao Navigation", style: .default) { _ in
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
        
        let appleAction = UIAlertAction(title: "Apple Map", style: .default) { _ in
            self.startNavigationWithNative(with: data)
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        alert.addAction(kakaoAction)
        alert.addAction(appleAction)
        alert.addAction(cancelAction)
        
        
        present(alert, animated:true, completion: nil)
    }
    
    func startNavigationWithNative(with data: NavigationData) {
        
        let destinationCoordinate = CLLocationCoordinate2D(latitude: data.latittude, longitude: data.longtitude)
        
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        destinationMapItem.name = data.title
        
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
            MKLaunchOptionsShowsTrafficKey: true
        ] as [String: Any]
        
        MKMapItem.openMaps(
            with: [destinationMapItem],
            launchOptions: launchOptions
        )
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
        
        var config = mainView.safeFilterButton.configuration ?? UIButton.Configuration.plain()
        
        let newImage = UIImage(systemName: "car.2.fill")
        config.image = newImage
        config.baseForegroundColor = newValue ? .green : .black
        
        mainView.safeFilterButton.configuration = config
    }
    
    @objc func toggleDangerFilter() {
        let newValue = !dangerFilterSubject.value
        dangerFilterSubject.send(newValue)
        
        var config = mainView.dangerFilterButton.configuration ?? UIButton.Configuration.plain()
        
        let newImage = UIImage(systemName: "eye.fill")
        config.image = newImage
        config.baseForegroundColor = newValue ? .red : .black
        
        mainView.dangerFilterButton.configuration = config
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
    
    @objc private func moveMapViewToParkedLocation() {
        let status = locationManager.authorizationStatus
        
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            print("위치 정보 없음 또는 권한 미허용")
            return
        }
        
        if let location = parkedLocation {
            let camera = MKMapCamera()
            let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            camera.centerCoordinate = coordinate
            camera.altitude = 2000
            camera.pitch = 0
            camera.heading = 0
            
            mainView.mapView.setCamera(camera, animated: true)
        }
    }
    
    @objc private func navigateParkLocationViewWithButton() {
        presentParkLocationView()
    }
    
    private func presentParkLocationView(parkedLocation: ParkedLocation? = nil, completion: (() -> Void)? = nil) {
        
        var presentable: ParkedLocationPresentable
        
        if let parkedLocation {
            presentable = ParkedLocationPresentable(
                latitude: parkedLocation.latitude, longitude: parkedLocation.longitude, title: parkedLocation.title, imagePath: parkedLocation.imagePath
            )
        } else {
            let location = currentLocationSubject.value
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            let address = bottomView.locationLabel.text ?? ""
            
            presentable = ParkedLocationPresentable(
                latitude: latitude,
                longitude: longitude,
                title: address,
                imagePath: nil
            )
        }
        
        let destination = ParkLocationViewController(viewModel: DIContainer.shared.makeParkLocationViewModel(with: presentable))
        
        destination.modalPresentationStyle = .custom
        
        destination.dismissCompletion = completion
        
        present(destination, animated: true)
    }
    
    private func handlePakredInfoInteraction(hasInfo: Bool) {
        mainView.makeAvailableParkedInfoButton(with: hasInfo)
        bottomView.makeAvailableParkedInfoButton(with: hasInfo)
    }
    
    private func handlerisDangerInfo(with isDanger: Bool) {
        mainView.makeAvailableIsDangerousInfo(with: isDanger)
    }
}
