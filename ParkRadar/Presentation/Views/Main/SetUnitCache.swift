//
//  SetUnitCache.swift
//  ParkRadar
//
//  Created by marty.academy on 4/11/25.
//

import Foundation
import MapKit

final class SetUnitCache {
    private var safeAreaSet: [String: [SafeParkingArea]]?
    private var dangerAreaSet: [String: [NoParkingArea]]?
    
    private var safeSetSummaries: [SafeSetAnnotation]?
    private var dangerSetSummaries: [DangerSetAnnotation]?
    
    private let repository: RepositoryProtocol
    private let precision: Int
    
    init(repository: RepositoryProtocol, precision: Int = 5) {
        self.repository = repository
        self.precision = precision
    }
    
    func getSafeSummaries() -> [SafeSetAnnotation] {
        if let summaries = safeSetSummaries {
            return summaries
        }
        
        let grouped = getSafeCluster()
        let summaries = grouped.map { (hash, group) in
            let latAvg = group.compactMap { $0.latitude }.average
            let lngAvg = group.compactMap { $0.longitude }.average
            return SafeSetAnnotation(
                identifier: "safeSet",
                coordinate: CLLocationCoordinate2D(latitude: latAvg, longitude: lngAvg),
                count: group.count
            )
        }
        
        self.safeSetSummaries = summaries
        return summaries
    }
    
    func getDangerSummaries() -> [DangerSetAnnotation] {
        if let summaries = dangerSetSummaries {
            return summaries
        }
        
        let grouped = getDangerCluster()
        let summaries = grouped.map { (hash, group) in
            let latAvg = group.compactMap { $0.latitude }.average
            let lngAvg = group.compactMap { $0.longitude }.average
            return DangerSetAnnotation(
                identifier: "dangerSet",
                coordinate: CLLocationCoordinate2D(latitude: latAvg, longitude: lngAvg),
                count: group.count
            )
        }
        
        self.dangerSetSummaries = summaries
        return summaries
    }
    
    private func getSafeCluster() -> [String: [SafeParkingArea]] {
        if let cluster = safeAreaSet { return cluster }
        
        let all = repository.getSafeAreaCluster()
        let clustered = Dictionary(grouping: all) {
            $0.geohash?.prefix(precision).string ?? ""
        }
        
        self.safeAreaSet = clustered
        return clustered
    }
    
    private func getDangerCluster() -> [String: [NoParkingArea]] {
        if let cluster = dangerAreaSet { return cluster }
        
        let all = repository.getDangerAreaCluster()
        let clustered = Dictionary(grouping: all) {
            $0.geohash.prefix(precision).string
        }
        
        self.dangerAreaSet = clustered
        return clustered
    }
}

extension Substring {
    var string: String { return String(self) }
}
