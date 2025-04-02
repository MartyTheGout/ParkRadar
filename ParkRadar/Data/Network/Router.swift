//
//  Router.swift
//  ParkRadar
//
//  Created by marty.academy on 3/30/25.
//

import Foundation

import Foundation

enum HTTPMethod: String {
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case delete  = "DELETE"
}

protocol APIRouter {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryParameters: [String: String]? { get }
    var body: Data? { get }

    func asURLRequest() throws -> URLRequest
}

extension APIRouter {
    func asURLRequest() throws -> URLRequest {
        var url = baseURL.appendingPathComponent(path)
        
        if let queryParameters = queryParameters {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            if let finalURL = components?.url {
                url = finalURL
            }
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        headers?.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        return request
    }
}

