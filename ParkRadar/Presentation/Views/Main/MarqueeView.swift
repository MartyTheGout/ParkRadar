//
//  MarqueeView.swift
//  ParkRadar
//
//  Created by marty.academy on 4/7/25.
//

import UIKit

final class DangerMarqueeView: UIView {
    
    
    private var isAnimating = false
    
    private let marqueeLabel: UILabel = {
        let label = UILabel()
        label.text = "위험구역 진입: 감시카메라를 확인하세요"
        label.textColor = .red
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()
    
    private var animationDuration: TimeInterval = 7.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        setupView()
//        startMarqueeAnimation()
        startBlinkingAnimation()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(marqueeLabel)
//        marqueeLabel.sizeToFit()
        
        // 최초 위치: 왼쪽 바깥
        //        marqueeLabel.frame.origin = CGPoint(x: bounds.width, y: 0) // 왼쪽에서 오른쪽 애니메이션 시에 적용
        
        marqueeLabel.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func startMarqueeAnimation() {
        let totalDistance = marqueeLabel.frame.width + bounds.width
        
        marqueeLabel.frame.origin.x = bounds.width
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveLinear], animations: {
            self.marqueeLabel.frame.origin.x = -self.marqueeLabel.frame.width
        }) { [weak self] _ in
            self?.startMarqueeAnimation() // 재귀적으로 무한 반복
        }
    }
    
    private func startBlinkingAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        blink()
    }
    
    private func blink() {
        UIView.animate(withDuration: 0.7,
                       delay: 0,
                       options: [.autoreverse, .repeat, .allowUserInteraction],
                       animations: {
            self.marqueeLabel.alpha = 0
        }, completion: nil)
    }
    
    // 필요 시 중단용
    func stopBlinking() {
        marqueeLabel.layer.removeAllAnimations()
        marqueeLabel.alpha = 1
        isAnimating = false
    }
}

