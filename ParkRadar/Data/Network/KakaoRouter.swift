//
//  ParkInfoRouter.swift
//  ParkRadar
//
//  Created by marty.academy on 3/30/25.
//

import Foundation

enum KakaoRouter : APIRouter {
    
    case transcoord(lat: Double, lot: Double)
    
    var baseURL: URL  {
        URL(string: AuthorizationManager.app.url ?? "")!
    }
    
    var path: String {
        switch self {
        case .transcoord : return "v2/local/geo/transcoord.json"
        }
    }
    
    var method: HTTPMethod {
        .get
    }
    
    var headers: [String : String]? {
        return [
            "content-type" : "application/json;charset=UTF-8",
            "Authorization" : AuthorizationManager.app.apiKey ?? ""
        ]
    }
    
    var queryParameters: [String : String]? {
        switch self {
        case .transcoord(let lat, let lot): return [
            "x":"\(lot)",
            "y":"\(lat)",
            "input_coord":"WGS84",
            "output_coord":"KTM", //** format used in KakaoMap's coordinate
        ]
        }
    }
    
    var body: Data? { return nil}
}


struct CoordConvertResponse: Decodable {
    let documents: [TMCoord]

    struct TMCoord: Decodable {
        let x: Double
        let y: Double
    }
}
