//
//  AppDelegate.swift
//  ParkRadar
//
//  Created by marty.academy on 3/26/25.
//

import UIKit
import KakaoSDKCommon
import FirebaseCore
import RealmSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        //AppGroup Migration of App SandBox
        migrateRealmAndAssetsIfNeeded()
        
        //Realm Migration
        RealmSchema.configureMigration()
        
        //KakaoSDK Setting
        KakaoSDK.initSDK(appKey: AuthorizationManager.app.appKey ?? "")
        
        //InitialData Setting
        RecordLoader.loadNoParkingDataIfNeeded()
        RecordLoader.loadSafeParkingAreaIfNeeded()
        
        //FirebaseSDK Setting
        FirebaseApp.configure()
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

private func migrateRealmAndAssetsIfNeeded() {
    let userDefaults = UserDefaults.standard
    let migrationKey = "hasMigratedRealmToAppGroup"

    guard !userDefaults.bool(forKey: migrationKey) else {
        print("Realm itself movement already happended")
        return
    }

    let fileManager = FileManager.default
    let appGroupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.parkRadar")!
    let newRealmURL = appGroupURL.appendingPathComponent("db.realm")
    let newImagesURL = appGroupURL.appendingPathComponent("ParkingImages")

    // 기존 Realm 위치
    let oldRealmURL = Realm.Configuration.defaultConfiguration.fileURL!
    let oldRealmDir = oldRealmURL.deletingLastPathComponent()

    // 기존 이미지 위치
    let oldImagesURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

    print("==== Realm & Asset Migration ====")
    print("oldRealmURL:", oldRealmURL)
    print("newRealmURL:", newRealmURL)
    print("oldImagesURL:", oldImagesURL)
    print("newImagesURL:", newImagesURL)

    // MARK: - Realm 파일 복사 후 삭제
    if fileManager.fileExists(atPath: oldRealmURL.path),
       !fileManager.fileExists(atPath: newRealmURL.path) {
        do {
            try fileManager.copyItem(at: oldRealmURL, to: newRealmURL)
            try fileManager.removeItem(at: oldRealmURL)
            print("✅ Realm migrated and original deleted.")
        } catch {
            print("[Error] Realm migration failed: \(error)")
        }
    }

    // MARK: - 이미지 파일 복사 후 삭제
    do {
        if !fileManager.fileExists(atPath: newImagesURL.path) {
            try fileManager.createDirectory(at: newImagesURL, withIntermediateDirectories: true)
        }

        let files = try fileManager.contentsOfDirectory(atPath: oldImagesURL.path)
        for file in files where file.lowercased().hasSuffix(".jpg") || file.lowercased().hasSuffix(".jpeg") || file.lowercased().hasSuffix(".png") {
            let oldFile = oldImagesURL.appendingPathComponent(file)
            let newFile = newImagesURL.appendingPathComponent(file)

            do {
                try fileManager.copyItem(at: oldFile, to: newFile)
                try fileManager.removeItem(at: oldFile)
                print("✅ Image \(file) migrated and deleted.")
            } catch {
                print("[Error] Failed to copy/delete image \(file): \(error)")
            }
        }
    } catch {
        print("[Error] Image directory access failed: \(error)")
    }

    userDefaults.set(true, forKey: migrationKey)
    print("✅ Migration flag set. Migration complete.")
}
