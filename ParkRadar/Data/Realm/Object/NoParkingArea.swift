//
//  NoParkingArea.swift
//  ParkRadar
//
//  Created by marty.academy on 3/30/25.
//

import Foundation
import RealmSwift

/**
 Extenal Data Example :
 
 "FIX_CCTV_ADDR": "개포동 1231",                                      // 감시카메라 주소
 "LAT": "37.47867",
 "LOT": "127.04732",
 "CGG_CD": "강남구",                                                             // 자치구
 "CRDN_BRNCH_NM": "[개포4-102] KB(개포남지점) 주변",     // 카메라 설명
 "GRNDS_SE": "불법주정차구역"                                              // 생략
 
 **/

class NoParkingArea : Object {
    @Persisted(primaryKey: true) var id: ObjectId
    
    @Persisted var address: String             // 감시카메라 주소 (FIX_CCTV_ADDR)
    @Persisted var latitude: Double            // 위도 (LAT)
    @Persisted var longitude: Double           // 경도 (LOT)
    @Persisted var district: String            // 자치구 (CGG_CD)
    @Persisted var descriptionText: String     // 카메라 설명 (CRDN_BRNCH_NM)
    
    // Indice for Zoom-in Situation Searching
    @Persisted(indexed: true) var latInt: Int
    @Persisted(indexed: true) var lngInt: Int
    
    // For Clustering
    @Persisted(indexed: true) var geohash: String
    
    convenience init(
        address: String,
        latitude: Double,
        longitude: Double,
        district: String,
        descriptionText: String
    ) {
        self.init()
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.district = district
        self.descriptionText = descriptionText
        
        self.latInt = Int((latitude * 1000).rounded())
        self.lngInt = Int((longitude * 1000).rounded())
        
        self.geohash = Geohash.encode(latitude: latitude, longitude: longitude, length: 5)
    }
    
    func prepareIndexing() {
        latInt = Int((latitude * 1000).rounded())
        lngInt = Int((longitude * 1000).rounded())
        geohash = Geohash.encode(latitude: latitude, longitude: longitude, length: 5)
    }
}

struct NoParkingAreaDTO: Codable {
    let address: String
    let latitudeRaw: StringOrDouble
    let longitudeRaw: StringOrDouble
    
    var latitude: Double { latitudeRaw.value ?? 0 }
    var longitude: Double { longitudeRaw.value ?? 0 }
    let district: String
    let descriptionText: String
    
    enum CodingKeys: String, CodingKey {
        case address = "FIX_CCTV_ADDR"
        case latitudeRaw = "LAT"
        case longitudeRaw = "LOT"
        case district = "CGG_CD"
        case descriptionText = "CRDN_BRNCH_NM"
    }
    
    func toRealmObject() -> NoParkingArea {
        let obj = NoParkingArea()
        obj.address = address
        obj.latitude = latitude
        obj.longitude = longitude
        obj.district = district
        obj.descriptionText = descriptionText
        obj.prepareIndexing()
        return obj
    }
}

//NoParking데이터의 경우, JSON구조는 동일하지만, 파일 내부의 최상위 키가 계속 달라지는 상황 -> Dynamic Key 
struct NoParkingAreaResponse: Decodable {
    let rows: [NoParkingAreaDTO]

    struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }

        var intValue: Int? { nil }
        init?(intValue: Int) { return nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        guard let firstKey = container.allKeys.first else {
            throw DecodingError.dataCorrupted(.init(codingPath: [],
                debugDescription: "No top-level key found"))
        }

        let nestedContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: firstKey)
        self.rows = try nestedContainer.decode([NoParkingAreaDTO].self, forKey: .row)
    }

    enum CodingKeys: String, CodingKey {
        case row
    }
}


enum StringOrDouble: Codable {
    case string(String)
    case double(Double)
    
    var value: Double? {
        switch self {
        case .string(let str):
            return Double(str)
        case .double(let dbl):
            return dbl
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let dbl = try? container.decode(Double.self) {
            self = .double(dbl)
        } else if let str = try? container.decode(String.self) {
            self = .string(str)
        } else {
            throw DecodingError.typeMismatch(
                StringOrDouble.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected Double or String")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .double(let dbl):
            try container.encode(dbl)
        case .string(let str):
            try container.encode(str)
        }
    }
}
