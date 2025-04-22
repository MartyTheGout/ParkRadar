//
//  RealmScheme.swift
//  ParkRadar
//
//  Created by marty.academy on 4/11/25.
//

import Foundation
import RealmSwift

enum RealmSchema {
    
    /*
     0: -
     1: latitude / longitude delta recognition level change.
     2: realm's url changed, from app sandbox to appGroup sandbox.
     */
    static let currentVersion: UInt64 = 2
    
    static func configureMigration() {
        
        let fileManager = FileManager.default
        let appGroupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.parkRadar")!
        let realmURL = appGroupURL.appendingPathComponent("db.realm")
        
        let config = Realm.Configuration(
            fileURL: realmURL,
            schemaVersion: currentVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    print("oldSchemaVersion: \(oldSchemaVersion), 0 -> 1 migration is on process ... ")
                    
                    migration.enumerateObjects(ofType: "NoParkingArea") { oldObject, newObject in
                        guard let latitude = oldObject?["latitude"] as? Double,
                              let longitude = oldObject?["longitude"] as? Double else {
                            return
                        }
                        
                        newObject?["latInt"] = Int((latitude * 10_000).rounded())
                        newObject?["lngInt"] = Int((longitude * 10_000).rounded())
                    }
                    
                    migration.enumerateObjects(ofType: "SafeParkingArea") { oldObject, newObject in
                        guard let latitude = oldObject?["latitude"] as? Double,
                              let longitude = oldObject?["longitude"] as? Double else {
                            return
                        }
                        
                        newObject?["latIndex"] = Int((latitude * 10_000).rounded())
                        newObject?["lngIndex"] = Int((longitude * 10_000).rounded())
                    }
                    return
                }
            }
        )
        
        Realm.Configuration.defaultConfiguration = config
    }
}

