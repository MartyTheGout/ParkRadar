//
//  DIContainer.swift
//  ParkRadar
//
//  Created by marty.academy on 4/9/25.
//

import Foundation

class DIContainer {
    let repository = Repository()
    let geoCodingService = GeocodingService()
    let imageHandler = ImageHandler()
    
    private init() {}
    
    static let shared = DIContainer()
    
    func makeMapViewModel() -> MapViewModel {
        return MapViewModel(repository: repository, geocodingService: geoCodingService)
    }
    
    func makeParkLocationViewModel(with presentable : ParkedLocationPresentable) -> ParkLocationViewModel {
        return ParkLocationViewModel(parkedLocation: presentable, repository: repository, imageHandler: imageHandler)
    }    
}
