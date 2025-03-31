//
//  Parkinglot.swift
//  ParkRadar
//
//  Created by marty.academy on 3/30/25.
//

import Foundation
import RealmSwift

/**
 Extenal Data Example :
 
 "PKLT_NM": "초안산근린공원주차장(구)",  // 이름
 "ADDR": "도봉구 창동 24-0", // 주소
 "PKLT_CD": "1010089", // 주차장 넘
 "PKLT_KND": "NW",
 "PKLT_KND_NM": "노외 주차장", // 주차장 종류
 "OPER_SE": "1",
 "OPER_SE_NM": "시간제 주차장", // 주차장 운영 종류
 "TELNO": "",
 "PRK_NOW_INFO_PVSN_YN": "0", // 데이터 연계 여부
 "PRK_NOW_INFO_PVSN_YN_NM": "미연계중",
 "TPKCT": 71,
 "CHGD_FREE_SE": "Y", // 유무료
 "CHGD_FREE_NM": "유료",
 "NGHT_FREE_OPN_YN": "N", // 야간 개방 여부
 "NGHT_FREE_OPN_YN_NAME": "야간 미개방",
 "WD_OPER_BGNG_TM": "0900", // 평일시작
 "WD_OPER_END_TM": "1900", // 평일 끝
 "WE_OPER_BGNG_TM": "0900", // 평일 시작
 "WE_OPER_END_TM": "1900", // 평일 끝
 "LHLDY_BGNG": "0900", // 공휴일 시작
 "LHLDY": "1900", // 공휴일 끝
 "LAST_DATA_SYNC_TM": "2022-01-12 15:16:35",
 "SAT_CHGD_FREE_SE": "N",
 "SAT_CHGD_FREE_NM": "무료", // 토요일 무료
 "LHLDY_YN": "N",
 "LHLDY_NM": "무료", // 공휴일 무료
 "MNTL_CMUT_CRG": "0",
 "CRB_PKLT_MNG_GROUP_NO": "",
 "PRK_CRG": 0, // 기본주차
 "PRK_HM": 0,
 "ADD_CRG": 300, // 추가주차
 "ADD_UNIT_TM_MNT": 10,
 "BUS_PRK_CRG": 0,
 "BUS_PRK_HM": 0,
 "BUS_PRK_ADD_HM": 0,
 "BUS_PRK_ADD_CRG": 0,
 "DLY_MAX_CRG": 0,
 "LAT": 0, // 위도
 "LOT": 0 // 경도
 **/
final class SafeParkingArea: Object {
    @Persisted(primaryKey: true) var id: ObjectId
    
    @Persisted var name: String           // 주차장 이름
    @Persisted var address: String        // 주소
    @Persisted var code: String           // 주차장 고유 코드
    
    @Persisted var placeKind : String     // 노외 주차장 / 실내주차장
    @Persisted var operationKind : String // 시간제 주차장
    
    @Persisted var isPaid: Bool           // 유료 여부
    @Persisted var isNightFree: Bool      // 야간 개방 여부
    @Persisted var isHolidayFree: Bool    // 공휴일 무료 여부
    
    @Persisted var weekdayStart: String?  // 평일 시작 시간 (ex. "0900")
    @Persisted var weekdayEnd: String?    // 평일 종료 시간
    @Persisted var weekendStart: String?  // 주말 시작 시간
    @Persisted var weekendEnd: String?    // 주말 종료 시간
    @Persisted var holidayStart: String?  // 공휴일 시작 시간
    @Persisted var holidayEnd: String?    // 공휴일 종료 시간
    
    @Persisted var baseCharge: Int?       // 기본 요금
    @Persisted var baseTime: Int?         // 기본 시간 (분 단위)
    @Persisted var extraCharge: Int?      // 추가 요금
    @Persisted var extraUnitMinutes: Int? // 추가 요금 단위 시간 (분)
    @Persisted var dailyMaxCharge: Int?   // 1일 최대 요금
    
    // Coordinate
    @Persisted var latitude: Double?
    @Persisted var longitude: Double?
    
    @Persisted(indexed: true) var latIndex: Int?  // for index based searching
    @Persisted(indexed: true) var lngIndex: Int?
    
    @Persisted var geohash: String? // for clustering
}

extension SafeParkingArea {
    func prepareIndexing() {
        guard let lat = latitude, let lng = longitude else { return }
        latIndex = Int(lat * 1_000)
        lngIndex = Int(lng * 1_000)
        geohash = Geohash.encode(latitude: lat, longitude: lng, length: 5)
    }
}


struct SafeParkingAreaDTO: Codable {
    let name: String
    let address: String
    let code: String
    
    let placeKind: String
    let operationKind: String
    
    let isPaid: String
    let isNightFree: String
    let isHolidayFree: String
    
    let weekdayStart: String?
    let weekdayEnd: String?
    let weekendStart: String?
    let weekendEnd: String?
    let holidayStart: String?
    let holidayEnd: String?
    
    let baseCharge: Int?
    let baseTime: Int?
    let extraCharge: Int?
    let extraUnitMinutes: Int?
    let dailyMaxCharge: Int?
    
    let latitude: Double?
    let longitude: Double?
    
    enum CodingKeys: String, CodingKey {
        case name = "PKLT_NM"
        case address = "ADDR"
        case code = "PKLT_CD"
        
        case placeKind = "PKLT_KND_NM"
        case operationKind = "OPER_SE_NM"
        
        case isPaid = "CHGD_FREE_SE"
        case isNightFree = "NGHT_FREE_OPN_YN"
        case isHolidayFree = "LHLDY_YN"
        
        case weekdayStart = "WD_OPER_BGNG_TM"
        case weekdayEnd = "WD_OPER_END_TM"
        case weekendStart = "WE_OPER_BGNG_TM"
        case weekendEnd = "WE_OPER_END_TM"
        case holidayStart = "LHLDY_BGNG"
        case holidayEnd = "LHLDY"
        
        case baseCharge = "PRK_CRG"
        case baseTime = "PRK_HM"
        case extraCharge = "ADD_CRG"
        case extraUnitMinutes = "ADD_UNIT_TM_MNT"
        case dailyMaxCharge = "DLY_MAX_CRG"
        
        case latitude = "LAT"
        case longitude = "LOT"
    }
    
    func toRealmObject() -> SafeParkingArea {
        let obj = SafeParkingArea()
        obj.name = name
        obj.address = address
        obj.code = code
        
        obj.placeKind = placeKind
        obj.operationKind = operationKind
        
        obj.isPaid = (isPaid == "Y")
        obj.isNightFree = (isNightFree == "Y")
        obj.isHolidayFree = (isHolidayFree == "Y")
        
        obj.weekdayStart = weekdayStart
        obj.weekdayEnd = weekdayEnd
        obj.weekendStart = weekendStart
        obj.weekendEnd = weekendEnd
        obj.holidayStart = holidayStart
        obj.holidayEnd = holidayEnd
        
        obj.baseCharge = baseCharge
        obj.baseTime = baseTime
        obj.extraCharge = extraCharge
        obj.extraUnitMinutes = extraUnitMinutes
        obj.dailyMaxCharge = dailyMaxCharge
        
        obj.latitude = latitude
        obj.longitude = longitude
        
        obj.prepareIndexing()
        
        return obj
    }
}

struct SafeParkingResponse: Codable {
    let GetParkInfo: SafeParkingWrapper
}

struct SafeParkingWrapper: Codable {
    let list_total_count: Int
    let row: [SafeParkingAreaDTO]
}
