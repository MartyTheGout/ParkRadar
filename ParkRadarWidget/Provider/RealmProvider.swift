//
//  RealmProvider.swift
//  ParkRadarWidgetExtension
//
//  Created by marty.academy on 6/1/25.
//

import Foundation
import RealmSwift

struct RealmProvider {
    static func makeAppGroupRealm() -> Realm? {
        let fileManager = FileManager.default
        guard let appGroupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.parkRadar") else {
            print("❌ AppGroup 경로 접근 실패")
            return nil
        }

        let realmURL = appGroupURL.appendingPathComponent("db.realm")
        var config = Realm.Configuration()
        config.fileURL = realmURL
        config.schemaVersion = 2
        
        do {
            let realm = try Realm(configuration: config)
            return realm
        } catch {
            print("❌ Realm 열기 실패: \(error)")
            return nil
        }
    }
}
