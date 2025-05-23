//
//  CircularClusterAnnotation.swift
//  ParkRadar
//
//  Created by marty.academy on 4/10/25.
//

import MapKit

class ClusterAnnotationView: MKAnnotationView {
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        collisionMode = .circle
        centerOffset = CGPoint(x: 0, y: -10) // Offset center point to animate better with marker annotations
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForDisplay() {
        super.prepareForDisplay()

        if let cluster = annotation as? MKClusterAnnotation {
            let totalAnnotation = cluster.memberAnnotations.count
            
            var isSafeSetAnnotation = count(annotationType: SafeSetAnnotation.self) > 0
            var isDangerSetAnnotation = count(annotationType: DangerSetAnnotation.self) > 0
            
            var isSafeAnnotation = count(annotationType: SafeAnnotation.self) > 0
            
            if isSafeSetAnnotation {
                
                guard let cluster = annotation as? MKClusterAnnotation else {
                    return
                }
                
                var count = 0
                cluster.memberAnnotations.forEach { annotation in
                    guard let a = annotation as? SafeSetAnnotation else {
                        return
                    }
                    count += a.count
                }
                
                image = drawCountWithCircle(count: count, color: .safeInfo)
                
                
            } else if isDangerSetAnnotation {
                
                guard let cluster = annotation as? MKClusterAnnotation else {
                    return
                }
                
                var count = 0
                cluster.memberAnnotations.forEach { annotation in
                    guard let a = annotation as? DangerSetAnnotation else {
                        return
                    }
                    count += a.count
                }
                
                image = drawCountWithCircle(count: count, color: .systemRed)
                
                
            } else {
                if isSafeAnnotation {
                    image = drawCountWithCircle(count: totalAnnotation, color: .safeInfo)
                } else {
                    image = drawCountWithCircle(count: totalAnnotation, color: .systemRed)
                }
            }
        }
    }
    
    private func drawCountWithCircle(count: Int, color: UIColor) -> UIImage {
        return drawRatio(0, to: count, fractionColor: nil, wholeColor: color)
    }

    private func drawRatio(_ fraction: Int, to whole: Int, fractionColor: UIColor?, wholeColor: UIColor?) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40))
        return renderer.image { _ in
            // Fill full circle with wholeColor
            wholeColor?.setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 40, height: 40)).fill()

            // Fill pie with fractionColor
            fractionColor?.setFill()
            let piePath = UIBezierPath()
            piePath.addArc(withCenter: CGPoint(x: 20, y: 20), radius: 20,
                           startAngle: 0, endAngle: (CGFloat.pi * 2.0 * CGFloat(fraction)) / CGFloat(whole),
                           clockwise: true)
            piePath.addLine(to: CGPoint(x: 20, y: 20))
            piePath.close()
            piePath.fill()

            // Fill inner circle with white color
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: 8, y: 8, width: 24, height: 24)).fill()

            // Finally draw count text vertically and horizontally centered
            let attributes = [ NSAttributedString.Key.foregroundColor: UIColor.black,
                               NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)]
            let text = "\(whole)"
            let size = text.size(withAttributes: attributes)
            let rect = CGRect(x: 20 - size.width / 2, y: 20 - size.height / 2, width: size.width, height: size.height)
            text.draw(in: rect, withAttributes: attributes)
        }
    }

    private func count<T: RadarAnnotaion>(annotationType type: T.Type) -> Int where T : AnyObject {
        guard let cluster = annotation as? MKClusterAnnotation else {
            return 0
        }
        
        return cluster.memberAnnotations.filter { member -> Bool in
            guard let annotaion = member as? RadarAnnotaion else {
                fatalError("Found unexpected annotation type")
            }
            return annotaion is T
        }.count
    }
}

