//
//  UpperTabView.swift
//  ParkRadar
//
//  Created by marty.academy on 3/31/25.
//

import UIKit
import SnapKit

final class UpperTabView : UIView {
    
    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .light)
        return UIVisualEffectView(effect: blur)
    }()
    
    let stackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillEqually
        return view
    }()
    
    let noParkShowingButton = UIButton()
    let safeParkShowingButton = UIButton()
    let illegalExplanationButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViewHierarchy()
        configureViewConstraints()
        configureViewDetails()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //MARK: - Be cautious that this 'safeAreaInsets.top' is not gettable before superview have layout displayed. this is why the code is written in layoutSubviews().
        let topInset = safeAreaInsets.top
        
        stackView.snp.updateConstraints {
            $0.top.equalToSuperview().offset(topInset)
            $0.horizontalEdges.equalToSuperview().inset(8)
            $0.bottom.equalToSuperview().inset(8)
        }
    }
    
    private func configureViewHierarchy() {
        addSubview(blurView)
        addSubview(stackView)
        [noParkShowingButton, safeParkShowingButton, illegalExplanationButton].forEach {
            stackView.addArrangedSubview($0)
        }
    }
    
    private func configureViewConstraints() {
        let topInset = safeAreaInsets.top
        
        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        stackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(topInset)
            $0.horizontalEdges.equalToSuperview().inset(8)
            $0.bottom.equalToSuperview().inset(8)
        }
    }
    
    private func configureViewDetails() {
        
        backgroundColor = Color.Back.main.ui.withAlphaComponent(0.5)
        
        noParkShowingButton.configuration = UIButton.Configuration.verticalStyle(title: "서울시 전체\n불법주정차구역", imageName: "eye.fill")
        
        safeParkShowingButton.configuration  = UIButton.Configuration.verticalStyle(title: "서울시 전체\n공영 주차장", imageName: "car.2.fill")
        
        illegalExplanationButton.configuration = UIButton.Configuration.verticalStyle(title: "불법\n주정차벌금", imageName: "person.crop.square.filled.and.at.rectangle.fill")
    }
}

