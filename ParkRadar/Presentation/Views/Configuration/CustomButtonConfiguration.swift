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

        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributedTitle = NSAttributedString(string: title, attributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .paragraphStyle: paragraphStyle
        ])
        
        config.attributedTitle = AttributedString(attributedTitle)

        return config
    }
    
    static func horizontalStyle(title: String, imageName: String) -> UIButton.Configuration {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: imageName)
        config.imagePlacement = .leading
        config.imagePadding = 6
        config.baseForegroundColor = .label

        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let attributedTitle = NSAttributedString(string: title, attributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .paragraphStyle: paragraphStyle
        ])
        
        config.attributedTitle = AttributedString(attributedTitle)

        return config
    }
}
