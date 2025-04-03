//
//  FineDetailViewController.swift
//  ParkRadar
//
//  Created by marty.academy on 4/3/25.
//

import UIKit

final class FineDetailViewController: UIViewController {

    private let mainView = FineDetailView()

    override func loadView() {
        self.view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
    }

    private func configureNavigation() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        navigationController?.navigationBar.tintColor = .black
        navigationItem.title = "주정차 위반 과태료 정보 (서울특별시)"
        navigationItem.backButtonTitle = ""
    }
}

