//
//  Color + Extension.swift
//  ParkRadar
//
//  Created by marty.academy on 4/1/25.
//

import UIKit

/*
 UIColor Extension for converting HEX value to RGB value
 
 Background : Given Color Input is HEX, so it is required to make have initiator with hex in UIColor.
 
 Explain : HEX is hexadecimal value, in string. The color displacement in aspect of number is as below
 
 - in hexadecimal : red ( F  F) X green ( F  F ) X blue ( F  F )
 - in binary : red ( 0000 0000 ) X grean ( 0000 0000 ) X blue ( 0000 0000 )
 
 so this convenience init work to convert string into decimal int, and bit-operation with each part of Color hexadecimal value.
 */
extension UIColor {
    convenience init(hex: String) {
        let colorInString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        var rgbColorValue: UInt64 = 0
        Scanner(string: colorInString).scanHexInt64(&rgbColorValue)
        
        self.init(
            red: CGFloat((rgbColorValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbColorValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbColorValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
}

