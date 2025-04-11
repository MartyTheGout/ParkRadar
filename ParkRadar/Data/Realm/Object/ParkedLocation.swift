//
//  ParkingLocation.swift
//  ParkRadar
//
//  Created by marty.academy on 4/5/25.
//

import Foundation
import RealmSwift

final class ParkedLocation: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var latitude: Double
    @Persisted var longitude: Double
    @Persisted var title: String
    @Persisted(indexed: true) var latInt: Int
    @Persisted(indexed: true) var lngInt: Int
    @Persisted var imagePath: String?
    @Persisted var savedDate: Date
    
    convenience init(latitude: Double, longitude: Double, title: String, imagePath: String?, date: Date = Date()) {
        self.init()
        self.latitude = latitude
        self.longitude = longitude
        self.title = title
        self.imagePath = imagePath
        self.savedDate = date
        
        self.latInt = Int((latitude * 10000).rounded())
        self.lngInt = Int((longitude * 10000).rounded())
    }
}
