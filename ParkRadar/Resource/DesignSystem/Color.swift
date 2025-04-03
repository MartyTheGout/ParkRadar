//
//  Color.swift
//  ParkRadar
//
//  Created by marty.academy on 4/1/25.
//

import UIKit

enum Color {
    enum Back : String {
//        case main = "F8F4EC"
        case main = "3A3F4B"
        
        var ui: UIColor {
            UIColor(hex: self.rawValue)
        }
    }
    
    enum Subject : String {
        case safe = "34C759"
        
        var ui: UIColor {
            UIColor(hex: self.rawValue)
        }
    }
}
