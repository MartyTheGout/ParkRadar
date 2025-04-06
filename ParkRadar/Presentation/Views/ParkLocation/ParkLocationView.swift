//
//  ParkLocationView.swift
//  ParkRadar
//
//  Created by marty.academy on 4/5/25.
//

import UIKit
import MapKit

class ParkLocationView : UIView {
    let mapView = MKMapView()
    
    let addressTitle = UILabel()
    let addressLabel = UILabel()
    
    let photoTitle = UILabel()
    
    let photoButton = UIButton()
    let horizontalLine = UIView()
    let verticalLine = UIView()
    let saveButton = UIButton()
    let cancelButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViewHierarchy()
        configureViewContraints()
        configureViewDetails()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureViewHierarchy() {
        addSubview(mapView)
        addSubview(addressTitle)
        addSubview(addressLabel)
        addSubview(photoTitle)
        addSubview(photoButton)
        addSubview(saveButton)
        addSubview(cancelButton)
        addSubview(horizontalLine)
        addSubview(verticalLine)
    }
    
    private func configureViewContraints() {
        mapView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.3)
        }
        
        addressTitle.snp.makeConstraints { make in
            make.top.equalTo(mapView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
        }
        addressTitle.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(addressTitle.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
        }
        addressLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        photoTitle.snp.makeConstraints { make in
            make.top.equalTo(addressLabel.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
        }
        photoTitle.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        photoButton.snp.makeConstraints { make in
            make.top.equalTo(photoTitle.snp.bottom).offset(20)
            make.bottom.equalTo(horizontalLine.snp.top).offset(-20)
            make.horizontalEdges.equalToSuperview().inset(16)
        }
        photoButton.setContentHuggingPriority(.defaultLow, for: .vertical)
        
        let buttonHeight = 50
        
        saveButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.trailing.equalToSuperview()
            make.leading.equalTo(safeAreaLayoutGuide.snp.centerX)
            make.height.equalTo(buttonHeight)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalTo(safeAreaLayoutGuide.snp.centerX)
            make.height.equalTo(buttonHeight)
        }
        
        horizontalLine.snp.makeConstraints { make in
            make.top.equalTo(saveButton)
            make.height.equalTo(1)
            make.horizontalEdges.equalToSuperview()
        }
        
        verticalLine.snp.makeConstraints { make in
            make.top.equalTo(horizontalLine)
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(1)
        }
    }
    
    private func configureViewDetails() {
        backgroundColor = .white
        
        addressTitle.attributedText = NSAttributedString(string: "현재 위치", attributes: [
            .font : UIFont.systemFont(ofSize: 15, weight: .bold),
        ])
        
        photoTitle.attributedText = NSAttributedString(string: "주차 위치 사진", attributes: [
            .font : UIFont.systemFont(ofSize: 15, weight: .bold),
        ])
        
        
        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
        let image = UIImage(systemName: "camera.circle.fill", withConfiguration: config)
        photoButton.setImage(image, for: .normal)
        photoButton.backgroundColor = .white
        photoButton.layer.cornerRadius = 30
        
        saveButton.setAttributedTitle(NSAttributedString(string: "저장하기", attributes: [
            .font : UIFont.systemFont(ofSize: 15),
            .foregroundColor : UIColor.systemBlue
        ]), for: .normal)
        saveButton.backgroundColor = .clear
        saveButton.layer.cornerRadius = 5
        
        cancelButton.setAttributedTitle(NSAttributedString(string: "돌아가기", attributes: [
            .font : UIFont.systemFont(ofSize: 15),
            .foregroundColor : UIColor.red
        ]), for: .normal)
        cancelButton.backgroundColor = .clear
        cancelButton.setTitleColor(.red, for: .normal)
        
        cancelButton.layer.cornerRadius = 5
        
        horizontalLine.backgroundColor = .lightGray
        verticalLine.backgroundColor = .lightGray
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        photoButton.layer.cornerRadius = 20
        photoButton.layer.masksToBounds = false
        photoButton.layer.shadowColor = UIColor.black.cgColor
        photoButton.layer.shadowOffset = .init(width: 0, height: 1)
        photoButton.layer.shadowRadius = 1.5
        photoButton.layer.shadowOpacity = 0.25
        photoButton.layer.shadowPath = UIBezierPath(
            roundedRect: photoButton.bounds,
            cornerRadius: photoButton.layer.cornerRadius
        ).cgPath
        
        photoButton.imageView?.contentMode = .scaleAspectFill
        photoButton.imageView?.clipsToBounds = true
        photoButton.imageView?.layer.cornerRadius = photoButton.layer.cornerRadius
    }
    
    func fillUpText(with data: String) {
        addressLabel.attributedText = NSAttributedString(string: " " + data, attributes: [
            .font : UIFont.systemFont(ofSize: 14, weight: .medium),
            .foregroundColor : UIColor.darkGray
        ])
    }
    
    func changeSaveButtonText(with value: String) {
        saveButton.setAttributedTitle(NSAttributedString(string: value, attributes: [
            .font : UIFont.systemFont(ofSize: 15),
            .foregroundColor : UIColor.systemBlue
        ]), for: .normal)
    }
}
