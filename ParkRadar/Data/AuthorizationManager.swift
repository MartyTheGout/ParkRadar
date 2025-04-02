//
//  AuthorizationManager.swift
//  ParkRadar
//
//  Created by marty.academy on 4/2/25.
//

import Foundation

enum AuthorizationManager: String {
    case app = "app"
    
    var appKey: String? {
        return Bundle.main.infoDictionary?["APP_KEY"] as? String
    }
    
    var apiKey: String? {
        return Bundle.main.infoDictionary?["REST_API_KEY"] as? String
    }
    
    var url: String? {
        let url = Bundle.main.infoDictionary?["LOCATION_BASE_URL"] as? String
        
        print(url)
        
        return url
    }
}

