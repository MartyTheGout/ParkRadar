//
//  NoParkingArea.swift
//  ParkRadar
//
//  Created by marty.academy on 3/30/25.
//

import Foundation
import RealmSwift

//    "FIX_CCTV_ADDR": "개포동 1231", // 감시카메라 주소
//    "LAT": "37.47867",
//    "LOT": "127.04732",
//    "CGG_CD": "강남구", // 자치구
//    "CRDN_BRNCH_NM": "[개포4-102] KB(개포남지점) 주변",
//    "GRNDS_SE": "불법주정차구역" // not required.

class NoParkingArea : Object {
    @Persisted var address : String
//    @Persisted(indexed: true) var latitude : Double
//    @Persisted(indexed: true) var longitude : Double
    
    
}
        

