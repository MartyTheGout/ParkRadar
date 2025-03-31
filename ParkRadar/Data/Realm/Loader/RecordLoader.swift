//
//  RecordLoader.swift
//  ParkRadar
//
//  Created by marty.academy on 3/31/25.
//

import Foundation
import RealmSwift

enum RecordLoader {
    static func loadNoParkingDataIfNeeded() {
        let realm = try! Realm()
        
        guard realm.objects(NoParkingArea.self).isEmpty else {
            print("NoParkingArea already exsits")
            return
        }
        
        print("Realm Seed: 불법주정차 영역 데이터 불러오는 중...")
        let start = Date()
        
        do {
            let paths = Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil)
            let filtered = paths.filter { $0.contains("OpendataFixedcctv") }
            let filenames = filtered.map { URL(fileURLWithPath: $0) }
            
            for url in filenames {
                let data = try Data(contentsOf: url)
                let response = try JSONDecoder().decode(NoParkingAreaResponse.self, from: data)
                let rows = response.rows
                let objects = rows.map { $0.toRealmObject() }
                
                try realm.write {
                    realm.add(objects)
                }
                
                print("✅ 저장 완료: \(url.lastPathComponent)")
            }
            
            let elapsed = Date().timeIntervalSince(start)
            print("⏱️ 불법주정차 데이터 로딩 완료 - 소요 시간: \(String(format: "%.2f", elapsed))초")
            
        } catch {
            print("Realm Seed 로딩 에러: \(error)")
        }
    }
    
    static func loadSafeParkingAreaIfNeeded() {
        let realm = try! Realm()
        
        guard realm.objects(SafeParkingArea.self).isEmpty else { return }
        
        print("Realm Seed: 공영주차 영역 데이터 불러오는 중...")
        let start = Date()
        
        do {
            let paths = Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil)
            let filtered = paths.filter { $0.contains("GetParkInfo") }
            let filenames = filtered.map { URL(fileURLWithPath: $0) }
            
            for url in filenames {
                let data = try Data(contentsOf: url)
                let response = try JSONDecoder().decode(SafeParkingResponse.self, from: data)
                let decoded = response.GetParkInfo.row
                
                let objects = decoded.map { $0.toRealmObject() }
                
                try realm.write {
                    realm.add(objects)
                }
                
                print("✅ SafeParkingArea Seed 완료: \(decoded.count)건")
            }
            
            let elapsed = Date().timeIntervalSince(start)
            print("⏱️ 공영주차장 데이터 로딩 완료 - 소요 시간: \(String(format: "%.2f", elapsed))초")
        } catch {
            print("Realm Seed 로딩 에러: \(error)")
        }
    }
}
