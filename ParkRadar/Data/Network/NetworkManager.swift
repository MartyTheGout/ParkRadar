//
//  NetworkManager.swift
//  ParkRadar
//
//  Created by marty.academy on 3/30/25.
//

import Foundation
import Combine

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    func callRequest<T: Decodable>(_ router: APIRouter, decodeType: T.Type) -> AnyPublisher<T, Error> {
        do {
            let request = try router.asURLRequest()
            return URLSession.shared.dataTaskPublisher(for: request)
                .tryMap { result -> Data in
                    guard let httpResponse = result.response as? HTTPURLResponse,
                          200..<300 ~= httpResponse.statusCode else {
                        throw URLError(.badServerResponse)
                    }
                    return result.data
                }
                .decode(type: T.self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }
}

