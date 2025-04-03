//
//  ParkingInfoViewCell.swift
//  ParkRadar
//
//  Created by marty.academy on 4/2/25.
//

import UIKit
import SnapKit

final class ParkingInfoCell: UICollectionViewCell {
    static let reuseIdentifier = "ParkingInfoCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = .systemBlue
        view.image = UIImage(systemName: "car.fill")
        return view
    }()
    
    private let goToNavButton : UIButton = {
        let button = UIButton()
        button.configuration = .bigIconStyle(imageName: "arrow.triangle.turn.up.right.circle.fill", tintColor: .black)
        return button
    }()
    
    private let priceInfoLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .white.withAlphaComponent(0.95)
        contentView.layer.cornerRadius = 12
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.05
        contentView.layer.shadowOffset = .init(width: 0, height: 2)
        contentView.layer.shadowRadius = 4
        
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(goToNavButton)
        contentView.addSubview(priceInfoLabel)
        
        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(12)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(28)
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(12)
            $0.leading.equalTo(iconView.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(12)
        }
        
        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalTo(titleLabel)
            $0.bottom.lessThanOrEqualToSuperview().inset(12)
        }
        
        goToNavButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview().offset(-8)
        }
        
        priceInfoLabel.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalTo(titleLabel)
            $0.bottom.lessThanOrEqualToSuperview().inset(12)
        }
    }
    
    func configure(with data : SafeParkingArea) {
        titleLabel.text = data.name
        subtitleLabel.text = data.address
        priceInfoLabel.text = makeUpPriceInfo(with: data)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        goToNavButton.layer.masksToBounds = true
        goToNavButton.layer.cornerRadius = goToNavButton.frame.height / 2
    }
    
    private func makeUpPriceInfo(with data : SafeParkingArea) -> String {
        var text = ""
        
        if let basePrice = data.baseCharge, let baseTime = data.baseTime {
            text += "기본요금 \(basePrice)원 / \(baseTime)분"
        }
        
        if let additionalPrice = data.extraCharge, let additionalTime = data.extraUnitMinutes {
            text += ", 추가요금 \(additionalPrice)원 / \(additionalTime)분"
        }
        
        return text
    }
}
