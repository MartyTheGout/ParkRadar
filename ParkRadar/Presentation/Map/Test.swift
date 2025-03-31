//
//  Test.swift
//  ParkRadar
//
//  Created by marty.academy on 3/26/25.
//

import MapKit


final class BlinkingCircleRenderer: MKCircleRenderer {
    private var displayLink: CADisplayLink?
    private var increasingAlpha = true
    private var currentAlpha: CGFloat = 0.3

    override init(circle: MKCircle) {
        super.init(circle: circle)
        fillColor = UIColor.red.withAlphaComponent(currentAlpha)
        startBlinking()
    }

    private func startBlinking() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateAlpha))
        displayLink?.add(to: .main, forMode: .default)
    }

    @objc private func updateAlpha() {
        let delta: CGFloat = 0.005
        if increasingAlpha {
            currentAlpha += delta
            if currentAlpha >= 0.6 {
                increasingAlpha = false
            }
        } else {
            currentAlpha -= delta
            if currentAlpha <= 0.3 {
                increasingAlpha = true
            }
        }
        fillColor = UIColor.red.withAlphaComponent(currentAlpha)
        setNeedsDisplay()
    }

    deinit {
        displayLink?.invalidate()
    }
}

final class CircleClusterView: MKAnnotationView {

    static let reuseIdentifier = "CircleClusterView"

    override func prepareForDisplay() {
        super.prepareForDisplay()

        guard let cluster = annotation as? MKClusterAnnotation else { return }

        let count = cluster.memberAnnotations.count

        // 기본 뷰 설정
        frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        backgroundColor = UIColor.systemBlue.withAlphaComponent(0.5)
        layer.cornerRadius = frame.width / 2
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2

        // 레이블 설정
        let countLabel = UILabel(frame: bounds)
        countLabel.text = "\(count)"
        countLabel.textAlignment = .center
        countLabel.textColor = .white
        countLabel.font = UIFont.boldSystemFont(ofSize: 16)
        countLabel.tag = 99 // 중복 방지용

        // 기존 레이블 제거
        subviews.filter { $0.tag == 99 }.forEach { $0.removeFromSuperview() }
        addSubview(countLabel)

        // 간단한 scale-in 애니메이션
        self.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.8,
                       options: [],
                       animations: {
            self.transform = .identity
        }, completion: nil)
    }
}
//
//
//class CircleClusterView: MKAnnotationView {
//    override var annotation: MKAnnotation? {
//        didSet {
//            setup()
//        }
//    }
//
//    private func setup() {
//        frame = CGRect(x: 0, y: 0, width: 40, height: 40)
//        backgroundColor = .blue.withAlphaComponent(0.3)
//        layer.cornerRadius = 20
//        animateAppearance()
//    }
//
//    private func animateAppearance() {
//        transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
//        UIView.animate(withDuration: 0.3,
//                       delay: 0,
//                       usingSpringWithDamping: 0.5,
//                       initialSpringVelocity: 0.5,
//                       options: [],
//                       animations: {
//            self.transform = .identity
//        }, completion: nil)
//    }
//}
