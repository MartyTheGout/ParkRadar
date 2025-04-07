//
//  MainView.swift
//  ParkRadar
//
//  Created by marty.academy on 4/1/25.
//

import UIKit
import MapKit
import SnapKit

class MainView: UIView {
    let mapView = MKMapView()
    let upperTabView = UpperTabView()
    
    let dangerFilterButton = {
        let button = UIButton()
        button.configuration = .horizontalStyle(title: "주정차\n단속구역", imageName: "eye.fill", tintColor: .red)
        button.backgroundColor = .white.withAlphaComponent(0.9)
        return button
    }()
    
    let safeFilterButton = {
        let button = UIButton()
        button.configuration = .horizontalStyle(title: "서울시\n공영주차장", imageName: "car.2.fill", tintColor: Color.Subject.safe.ui)
        button.backgroundColor = .white.withAlphaComponent(0.9)
        return button
    }()
    
    let userLocationButton: UIButton = {
        let button = UIButton()
        button.configuration = .iconStyle(imageName: "location.fill", tintColor: .black)
        button.backgroundColor = .white.withAlphaComponent(0.9)
        return button
    }()
    
    let marqueeView = DangerMarqueeView()
    
    let parkedLocationButton: UIButton = {
        let button = UIButton()
        button.configuration = .iconStyle(imageName: "pin.fill", tintColor: .orange)
        button.backgroundColor = .white.withAlphaComponent(0.9)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViewHierarchy()
        configureViewConstraints()
        configureViewDetails()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureViewHierarchy() {
        addSubview(mapView)
        addSubview(upperTabView)
        addSubview(dangerFilterButton)
        addSubview(safeFilterButton)
        addSubview(userLocationButton)
        addSubview(marqueeView)
        addSubview(parkedLocationButton)
    }
    
    func configureViewConstraints() {
        mapView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.horizontalEdges.equalTo(safeAreaLayoutGuide)
            $0.bottom.equalToSuperview()
        }
        
        upperTabView.snp.makeConstraints {
            $0.horizontalEdges.equalTo(safeAreaLayoutGuide)
            $0.top.equalToSuperview()
        }
        
        dangerFilterButton.snp.makeConstraints {
            $0.top.equalTo(upperTabView.snp.bottom).offset(4)
            $0.leading.equalTo(safeAreaLayoutGuide).offset(8)
        }
        
        safeFilterButton.snp.makeConstraints {
            $0.top.equalTo(upperTabView.snp.bottom).offset(4)
            $0.leading.equalTo(dangerFilterButton.snp.trailing).offset(8)
        }
        
        userLocationButton.snp.makeConstraints {
            $0.top.equalTo(upperTabView.snp.bottom).offset(4)
            $0.trailing.equalTo(safeAreaLayoutGuide).offset(-8)
        }
        
        marqueeView.snp.makeConstraints {
            $0.top.equalTo(userLocationButton.snp.bottom).offset(4)
            $0.horizontalEdges.equalTo(safeAreaLayoutGuide)
        }
        
        parkedLocationButton.snp.makeConstraints {
            $0.top.equalTo(userLocationButton.snp.bottom).offset(4)
            $0.trailing.equalTo(safeAreaLayoutGuide).offset(-8)
        }
    }
    
    func configureViewDetails() {
        backgroundColor = Color.Back.main.ui
        marqueeView.isHidden = true
    }
    
    func makeAvailableParkedInfoButton(with isValid: Bool) {
        parkedLocationButton.isHidden = !isValid
        parkedLocationButton.isUserInteractionEnabled = isValid
    }
    
    func makeAvailableIsDangerousInfo(with isDangerous: Bool) {
        marqueeView.isHidden = !isDangerous
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        [safeFilterButton, dangerFilterButton, userLocationButton, parkedLocationButton].forEach {
            $0.layer.cornerRadius = 10
            $0.layer.masksToBounds = false
            $0.layer.shadowColor = UIColor.black.cgColor
            $0.layer.shadowOffset = .init(width: 0, height: 3)
            $0.layer.shadowRadius = 3
            $0.layer.shadowOpacity = 0.3
            $0.layer.shadowPath = UIBezierPath(
                roundedRect: $0.bounds,
                cornerRadius: $0.layer.cornerRadius
            ).cgPath
        }
    }
}
