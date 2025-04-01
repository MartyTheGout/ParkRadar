//
//  HorizontalAlignmentButton.swift
//  ParkRadar
//
//  Created by marty.academy on 3/31/25.
//

import UIKit

extension UIButton.Configuration {
    static func verticalStyle(title: String, imageName: String) -> UIButton.Configuration {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: imageName)
        config.imagePlacement = .top
        config.imagePadding = 6
        config.baseForegroundColor = .label

        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributedTitle = NSAttributedString(string: title, attributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .paragraphStyle: paragraphStyle
        ])
        
        config.attributedTitle = AttributedString(attributedTitle)

        return config
    }
    
    static func horizontalStyle(title: String, imageName: String, tintColor: UIColor) -> UIButton.Configuration {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: imageName)?.withTintColor(tintColor)
        config.imagePlacement = .leading
        config.imagePadding = 6
        config.baseForegroundColor = tintColor

        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let attributedTitle = NSAttributedString(string: title, attributes: [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .paragraphStyle: paragraphStyle,
            .foregroundColor : UIColor.black
        ])
        
        config.attributedTitle = AttributedString(attributedTitle)

        return config
    }
}
