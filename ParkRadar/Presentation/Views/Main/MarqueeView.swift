//
//  MarqueeView.swift
//  ParkRadar
//
//  Created by marty.academy on 4/7/25.
//

import UIKit

final class DangerMarqueeView: UIView {

    private let marqueeLabel: UILabel = {
        let label = UILabel()
        label.text = "현재 위험구역에 진입해있습니다"
        label.textColor = .red
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()

    private var animationDuration: TimeInterval = 5.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        setupView()
        startMarqueeAnimation()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(marqueeLabel)
        marqueeLabel.sizeToFit()

        // 최초 위치: 왼쪽 바깥
        marqueeLabel.frame.origin = CGPoint(x: bounds.width, y: 0)
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
}
