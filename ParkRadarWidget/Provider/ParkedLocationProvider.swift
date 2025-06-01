//
//  ParkedLocationProvider.swift
//  ParkRadarWidgetExtension
//
//  Created by marty.academy on 6/1/25.
//

import Foundation
import WidgetKit
import MapKit

struct ParkedLocationWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ParkedLocationEntry {
        ParkedLocationEntry(
            date: Date(),
            title: "나의 주차위치",
            address: "서울특별시 강남대로 324-131",
            
            timeElapsedText: "20분 경과",
            coordinate: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            hasParkedLocation: true,
            mapSnapshot: nil
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ParkedLocationEntry) -> Void) {
        fetchParkedLocationEntry { entry in
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ParkedLocationEntry>) -> Void) {
        fetchParkedLocationEntry { entry in
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    private func fetchParkedLocationEntry(completion: @escaping (ParkedLocationEntry) -> Void) {
        guard let realm = RealmProvider.makeAppGroupRealm(),
              let location = realm.objects(ParkedLocation.self).sorted(byKeyPath: "savedDate", ascending: false).first else {
            
            let entry = ParkedLocationEntry(
                date: Date(),
                title: "나의 주차위치",
                address: "",
                timeElapsedText: "",
                coordinate: nil,
                hasParkedLocation: false,
                mapSnapshot: nil
            )
            completion(entry)
            return
        }
        
        
        let elapsed = Int(Date().timeIntervalSince(location.savedDate)) / 60
        let elapsedText: String
        
        if elapsed < 60 {
            elapsedText = "\(elapsed)분경과"
        } else {
            let hours = elapsed / 60
            let minutes = elapsed % 60
            if minutes == 0 {
                elapsedText = "\(hours)시간경과"
            } else {
                elapsedText = "\(hours)시간 \(minutes)분경과"
            }
        }
        
        let coordinate: CLLocationCoordinate2D?
        if let lat = location.value(forKey: "latitude") as? Double,
           let lon = location.value(forKey: "longitude") as? Double {
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            coordinate = nil
        }
        
        if let coord = coordinate {
            MapSnapshotHelper.generateMapSnapshot(coordinate: coord) { mapSnapshot in
                let entry = ParkedLocationEntry(
                    date: Date(),
                    title: "나의 주차위치",
                    address: location.title,
                    timeElapsedText: elapsedText,
                    coordinate: coordinate,
                    hasParkedLocation: true,
                    mapSnapshot: mapSnapshot
                )
                completion(entry)
            }
        } else {
            let entry = ParkedLocationEntry(
                date: Date(),
                title: "나의 주차위치",
                address: location.title,
                timeElapsedText: elapsedText,
                coordinate: coordinate,
                hasParkedLocation: true,
                mapSnapshot: nil
            )
            completion(entry)
        }
    }
}
