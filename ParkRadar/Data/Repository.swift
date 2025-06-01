//
//  Repository.swift
//  ParkRadar
//
//  Created by marty.academy on 3/30/25.
//

import Foundation
import RealmSwift
import CoreLocation

protocol RepositoryProtocol {
    func getSafeArea(latitude : Double, longitude: Double, altitude: CLLocationDistance) -> Results<SafeParkingArea>
    func getDangerArea(latitude : Double, longitude: Double, altitude: CLLocationDistance) -> Results<NoParkingArea>
    func getParkedLocation() -> Results<ParkedLocation>
    func getSafeAreaCluster() -> Results<SafeParkingArea>
    func getDangerAreaCluster() -> Results<NoParkingArea>
    func saveParkedLocation(_ location: ParkedLocation) -> Void
    func deleteParkedLocation() -> Void
    func isCurrentLocationDangerous(latitude : Double, longitude: Double) -> Bool
}

final class Repository: RepositoryProtocol {
    
    private let realm: Realm = try! Realm()
    
    func checkVersionAndPath() {
        let realmPath = realm.configuration.fileURL!
        let version = try! schemaVersionAtURL(realm.configuration.fileURL!)
        print(version, realmPath)
        
    }
    
    private var lastCheckedLatRange: ClosedRange<Int>?
    private var lastCheckedLngRange: ClosedRange<Int>?
    
    private var lastKnownResult: Bool?
    
    func getSafeArea(latitude : Double, longitude: Double, altitude: CLLocationDistance ) -> Results<SafeParkingArea> {
        let delta = dynamicLatLngDelta(from: altitude)
        let latMin = Int((latitude - delta) * 10000)
        let latMax = Int((latitude + delta) * 10000)
        let lngMin = Int((longitude - delta) * 10000)
        let lngMax = Int((longitude + delta) * 10000)
        
        let safeObjects = self.realm.objects(SafeParkingArea.self)
            .where {
                $0.latIndex >= latMin && $0.latIndex <= latMax &&
                $0.lngIndex >= lngMin && $0.lngIndex <= lngMax
            }
        
        return safeObjects
    }
    
    func getDangerArea(latitude : Double, longitude: Double, altitude: CLLocationDistance) -> Results<NoParkingArea> {
        let delta = dynamicLatLngDelta(from: altitude)
        let latMin = Int((latitude - delta) * 10000)
        let latMax = Int((latitude + delta) * 10000)
        let lngMin = Int((longitude - delta) * 10000)
        let lngMax = Int((longitude + delta) * 10000)
        
        let dangerObjects = self.realm.objects(NoParkingArea.self)
            .where {
                $0.latInt >= latMin && $0.latInt <= latMax &&
                $0.lngInt >= lngMin && $0.lngInt <= lngMax
            }
        
        return dangerObjects
    }
    
    func getClosestParkingAreas(latitude : Double, longitude: Double) -> [SafeParkingArea] {
        let fixedDelta = 0.02
        let latMin = Int((latitude - fixedDelta) * 10000)
        let latMax = Int((latitude + fixedDelta) * 10000)
        let lngMin = Int((longitude - fixedDelta) * 10000)
        let lngMax = Int((longitude + fixedDelta) * 10000)
        
        let centerLatIndex = Int(latitude * 10000)
        let centerLngIndex = Int(longitude * 10000)
        
        let safeObjects = self.realm.objects(SafeParkingArea.self)
            .where {
                $0.latIndex >= latMin && $0.latIndex <= latMax &&
                $0.lngIndex >= lngMin && $0.lngIndex <= lngMax
            }
        
        let sortedNearbyObjects = safeObjects
            .filter { obj in
                obj.latIndex != nil && obj.latIndex != nil
            }
            .map { obj -> (object: SafeParkingArea, distance: Int) in
                let dLat = obj.latIndex! - centerLatIndex
                let dLng = obj.lngIndex! - centerLngIndex
                let distance = dLat * dLat + dLng * dLng // 유클리디안 거리 제곱
                return (object: obj, distance: distance)
            }
            .sorted(by: { $0.distance < $1.distance })
            .prefix(20)
            .map { $0.object }
        
        return sortedNearbyObjects
    }
    
    func getSafeAreaCluster() -> Results<SafeParkingArea> {
        self.realm.objects(SafeParkingArea.self)
    }
    
    func getDangerAreaCluster() -> Results<NoParkingArea> {
        self.realm.objects(NoParkingArea.self)
    }
    
    func getParkedLocation() -> Results<ParkedLocation> {
        self.realm.objects(ParkedLocation.self)
    }
    
    func saveParkedLocation(_ location: ParkedLocation) {
        try! self.realm.write {
            self.realm.add(location, update: .modified)
        }
    }
    
    func deleteParkedLocation() {
        let record = getParkedLocation()
        
        try! self.realm.write {
            self.realm.delete(record)
        }
    }
    
    func isCurrentLocationDangerous(latitude : Double, longitude: Double) -> Bool {
        
        let (latDelta, lngDelta) = metersToLatLngDelta(60, at: latitude)
        
        let baseLat = Int(latitude * 10000)
        let deltaLat = Int(latDelta * 10000)
        let latMin = baseLat - deltaLat
        let latMax = baseLat + deltaLat
        
        let baseLng = Int(longitude * 10000)
        let deltaLng = Int(lngDelta * 10000)
        let lngMin = baseLng - deltaLng
        let lngMax = baseLng + deltaLng
        
        if let lastLat = lastCheckedLatRange, lastLat.contains(latMin) && lastLat.contains(latMax),
           let lastLng = lastCheckedLngRange, lastLng.contains(lngMin) && lastLng.contains(lngMax) {
            return lastKnownResult! // cached value
        }
        
        let roughMatches = realm.objects(NoParkingArea.self)
            .where {
                $0.latInt >= latMin && $0.latInt <= latMax &&
                $0.lngInt >= lngMin && $0.lngInt <= lngMax
            }
        
        let currentLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        let finalMatches = roughMatches.first(where: { obj in
            let lat = obj.latitude, lng = obj.longitude
            let targetLocation = CLLocation(latitude: lat, longitude: lng)
            let distance = currentLocation.distance(from: targetLocation)
            return distance <= 50
        })
        
        let result = (finalMatches != nil)
        
        lastCheckedLatRange = latMin...latMax
        lastCheckedLngRange = lngMin...lngMax
        lastKnownResult = result
        
        return result
    }
}

extension Repository {
    private func dynamicLatLngDelta(from altitude: CLLocationDistance) -> Double {
        switch altitude {
        case 0..<1000:
            return 0.002
        case 1000..<3000:
            return 0.005
        case 3000..<7000:
            return 0.01
        case 7000..<15000:
            return 0.02
        default:
            return 0.04
        }
    }
    
    private func metersToLatLngDelta(_ meters: CLLocationDistance, at latitude: CLLocationDegrees) -> (latDelta: Double, lngDelta: Double) {
        let latDelta = meters / 111_000
        let lngDelta = meters / (111_000 * cos(latitude * .pi / 180))
        return (latDelta, lngDelta)
    }
}
