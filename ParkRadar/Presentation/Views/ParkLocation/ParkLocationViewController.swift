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
    
    private let viewModel: ParkLocationViewModel
    
    private let mainView = ParkLocationView()
    
    var dismissCompletion: (() -> Void)?
    
    // Better Perceived Performance, when initilaize this, at the same time when parent component initialized.
    private lazy var imagePickerController: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        return picker
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: ParkLocationViewModel) {
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
        setSubComponent()
        bindViewModel()
        
        imagePickerController.delegate = self
    }
    
    private func bindViewModel() {
        let input = ParkLocationViewModel.Input()
        let output = viewModel.bind(input)
        
        output.locationSeq
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
        
        output.addressSeq
            .receive(on: DispatchQueue.main)
            .sink { [weak self] address in
                self?.setCurrentAddress(with: address)
            }
            .store(in: &cancellables)
        
        output.imageSeq
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                if let image {
                    self?.mainView.photoButton.setImage(image, for: .normal)
                    self?.mainView.photoButton.contentMode = .scaleAspectFill
                }
            }
            .store(in: &cancellables)
    }
    
    private func setSubComponent() {
        mainView.cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        
        if !viewModel.forSave {
            mainView.photoButton.isUserInteractionEnabled = false
            
            mainView.changeSaveButtonText(with: "삭제하기")
            mainView.saveButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        } else {
            mainView.saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
            mainView.photoButton.addTarget(self, action: #selector(photoButtonTapped), for: .touchUpInside)
        }
    }
    
    // MARK: - Actions
    @objc private func photoButtonTapped() {
        present(imagePickerController, animated: true)
    }
    
    @objc private func saveButtonTapped() {
        viewModel.saveLocation()
        dismiss(animated: true)
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func deleteButtonTapped() {
        viewModel.deleteLocation()
        dismiss(animated: true)
    }
    
    private func setCurrentAddress(with address: String) {
        mainView.fillUpText(with: address)
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
         super.dismiss(animated: flag) {
             completion?()
             self.dismissCompletion?()
         }
     }
}

// MARK: - UIImagePickerControllerDelegate
extension ParkLocationViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            viewModel.setImage(image)
            mainView.photoButton.setImage(image, for: .normal)
            mainView.photoButton.contentMode = .scaleAspectFill
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
