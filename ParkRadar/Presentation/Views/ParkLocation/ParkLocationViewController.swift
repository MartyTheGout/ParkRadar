//
//  ParkSavingViewController.swift
//  ParkRadar
//
//  Created by marty.academy on 4/5/25.
//

import UIKit
import Combine
import MapKit

class ParkLocationViewController: UIViewController, UINavigationControllerDelegate {

    private let mainView = ParkLocationView()
    private let viewModel: LocationPhotoViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: LocationPhotoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    private func bindViewModel() {
        viewModel.currentLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self = self, let location = location else { return }
                let region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
                )
                mainView.mapView.setRegion(region, animated: true)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = location.coordinate
                mainView.mapView.addAnnotation(annotation)
            }
            .store(in: &cancellables)
        
        viewModel.address
            .receive(on: DispatchQueue.main)
            .sink { [weak self] address in
                self?.setCurrentAddress(with: address)
            }
            .store(in: &cancellables)
        
        mainView.photoButton.addTarget(self, action: #selector(photoButtonTapped), for: .touchUpInside)
        mainView.saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        mainView.cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func photoButtonTapped() {
        // Present image picker
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .camera
        imagePickerController.delegate = self
        present(imagePickerController, animated: true)
    }
    
    @objc private func saveButtonTapped() {
        viewModel.saveLocation()
        dismiss(animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    private func setCurrentAddress(with address: String) {
        mainView.fillUpText(with: address)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ParkLocationViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            viewModel.setImage(image)
            // Update the UI to show the selected image
            mainView.photoButton.setImage(image, for: .normal)
            mainView.photoButton.contentMode = .scaleAspectFill
            mainView.photoButton.clipsToBounds = true
        }
        picker.dismiss(animated: true)
    }
}

// MARK: - Custom Transition Delegate
extension ParkLocationViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CustomPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
