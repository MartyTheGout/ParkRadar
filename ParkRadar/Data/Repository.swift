//
//  Repository.swift
//  ParkRadar
//
//  Created by marty.academy on 3/30/25.
//

import Foundation
import RealmSwift

protocol RepositoryProtocol {
    func getSafeArea(latitude : Double, longitude: Double) -> Results<SafeParkingArea>
    func getDangerArea(latitude : Double, longitude: Double) -> Results<NoParkingArea>
}

final class Repository: RepositoryProtocol {
    
    private let realm: Realm = try! Realm()
    
    func getSafeArea(latitude : Double, longitude: Double ) -> Results<SafeParkingArea> {
        let latMin = Int((latitude - 0.01) * 1000)
        let latMax = Int((latitude + 0.01) * 1000)
        let lngMin = Int((longitude - 0.01) * 1000)
        let lngMax = Int((longitude + 0.01) * 1000)
        
        let safeObjects = self.realm.objects(SafeParkingArea.self)
            .where {
                $0.latIndex >= latMin && $0.latIndex <= latMax &&
                $0.lngIndex >= lngMin && $0.lngIndex <= lngMax
            }
        
        print("lat 범위: \(latMin) ~ \(latMax)")
        print("lng 범위: \(lngMin) ~ \(lngMax)")
        
        return safeObjects
    }
    func getDangerArea(latitude : Double, longitude: Double) -> Results<NoParkingArea> {
        let latMin = Int((latitude - 0.01) * 1000)
        let latMax = Int((latitude + 0.01) * 1000)
        let lngMin = Int((longitude - 0.01) * 1000)
        let lngMax = Int((longitude + 0.01) * 1000)
        
        let dangerObjects = self.realm.objects(NoParkingArea.self)
            .where {
                $0.latInt >= latMin && $0.latInt <= latMax &&
                $0.lngInt >= lngMin && $0.lngInt <= lngMax
            }
        print("lat 범위: \(latMin) ~ \(latMax)")
        print("lng 범위: \(lngMin) ~ \(lngMax)")
        
        return dangerObjects
    }
}
