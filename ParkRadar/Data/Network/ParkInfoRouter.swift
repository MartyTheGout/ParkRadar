//
//  ParkInfoRouter.swift
//  ParkRadar
//
//  Created by marty.academy on 3/30/25.
//

import Foundation

enum ParkInfoRouter : APIRouter {
    
    case jongro
    
    var baseURL: URL  {
        URL(string: "")!
    }
    
    var path: String {
        return ""
    }
    
    var method: HTTPMethod {
        .get
    }
    
    var headers: [String : String]? {
        return ["":""]
    }
    
    var queryParameters: [String : String]? {
        return ["":""]
    }
    
    var body: Data? { return nil}
}
