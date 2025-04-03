//
//  MultiStepBottomSheet.swift
//  ParkRadar
//
//  Created by marty.academy on 4/1/25.
//

import UIKit
import SnapKit

final class MultiStepBottomSheet: UIView {
    
    private var panGesture: UIPanGestureRecognizer!
    private var bottomConstraint: Constraint?
    private var superHeight: CGFloat = 0
    
    private var sheetHeights: [CGFloat] = []
    private var currentStep: Int = 2 // 시작은 하단
    
    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .light)
        return UIVisualEffectView(effect: blur)
    }()
    
    private let grabber: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 2.5
        return view
    }()
    
    let locationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        return label
    }()
    
    lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 32, right: 0)
        return collectionView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViewHierarchy()
        configureViewConstraints()
        configureViewDetail()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func configureViewHierarchy() {
        addSubview(blurView)
        addSubview(grabber)
        addSubview(locationLabel)
        addSubview(collectionView)
    }
    
    private func configureViewConstraints() {
        blurView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        grabber.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().inset(16)
            
            $0.width.equalTo(30)
            $0.height.equalTo(5)
        }
        
        locationLabel.snp.makeConstraints{
            $0.top.equalTo(grabber.snp.bottom).offset(16)
            $0.leading.equalToSuperview().inset(16)
        }
        
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(locationLabel.snp.bottom).offset(12)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func configureViewDetail() {
//        backgroundColor = .white.withAlphaComponent(0.7)
        backgroundColor = Color.Back.main.ui.withAlphaComponent(0.7)
        
        layer.cornerRadius = 16
        clipsToBounds = true
        
        locationLabel.text = "현재장소: 서울특별시 도봉대로 231-565"
    }
    
    func attach(to superview: UIView) {
        superview.addSubview(self)
        self.superHeight = superview.bounds.height
        
        // 시트 위치 단계 정의
        sheetHeights = [
            superHeight * 0.1, // bottom 숨김
            superHeight * 0.5, // 중간
            superHeight * 0.85 // 거의 최상단
        ]
        
        self.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            bottomConstraint = $0.top.equalToSuperview().offset(sheetHeights[2]).constraint
            $0.height.equalTo(superHeight)
        }
        
        superview.layoutIfNeeded()
    }
    
    private func setupGesture() {
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        let translation = gesture.translation(in: superview)
        let velocity = gesture.velocity(in: superview)
        
        switch gesture.state {
        case .changed:
            let baseOffset = sheetHeights[currentStep]
            let newOffset = baseOffset + translation.y
            bottomConstraint?.update(offset: max(newOffset, 0))
        case .ended, .cancelled:
            let directionUp = velocity.y < 0
            
            // 방향에 따라 다음 스냅 포인트 결정
            if directionUp {
                currentStep = max(currentStep - 1, 0)
            } else {
                currentStep = min(currentStep + 1, sheetHeights.count - 1)
            }
            
            // 스냅 위치로 애니메이션
            let targetOffset = sheetHeights[currentStep]
            bottomConstraint?.update(offset: targetOffset)
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut]) {
                superview.layoutIfNeeded()
            }
            
        default: break
        }
    }
}

extension MultiStepBottomSheet {
    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, _ in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .estimated(80))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .estimated(80))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16)
            return section
        }
    }
    
    private func setupCollectionView() {
        collectionView.register(ParkingInfoCell.self, forCellWithReuseIdentifier: ParkingInfoCell.reuseIdentifier)
    }
}

extension MultiStepBottomSheet: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true // ***collectionView scroll과 공존 가능하도록
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let gestureView = gestureRecognizer.view else { return false }

         let location = gestureRecognizer.location(in: self)
         let isInsideCollectionView = collectionView.frame.contains(location)

         return !isInsideCollectionView // **collectionView 바깥에서 시작했을 때만 시트 드래그 허용
    }
}

extension MultiStepBottomSheet {
    func updateCurrentAddress(with info: String) {
        locationLabel.text = "현재장소: \(info)"
    }
}
