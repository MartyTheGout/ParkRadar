//
//  UpperTabView.swift
//  ParkRadar
//
//  Created by marty.academy on 3/31/25.
//

import UIKit
import SnapKit

final class UpperTabView : UIView {
    
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
    
    private func configureViewHierarchy() {
        addSubview(stackView)
        [noParkShowingButton, safeParkShowingButton, illegalExplanationButton].forEach {
            stackView.addArrangedSubview($0)
        }
    }
    
    private func configureViewConstraints() {
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func configureViewDetails() {
        noParkShowingButton.configuration = UIButton.Configuration.verticalStyle(title: "서울시 전체\n불법주정차구역", imageName: "eye.fill")
        
        safeParkShowingButton.configuration  = UIButton.Configuration.verticalStyle(title: "서울시\n공영 주차장", imageName: "car2.fill")
        
        illegalExplanationButton.configuration = UIButton.Configuration.verticalStyle(title: "불법\n주정차벌금", imageName: "person.crop.square.filled.and.at.rectangle.fill")
    }
}

#Preview {
    UpperTabView()
}
