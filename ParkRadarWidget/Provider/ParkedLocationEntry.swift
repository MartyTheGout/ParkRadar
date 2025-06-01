//
//  ParkedLocationEntry.swift
//  ParkRadarWidgetExtension
//
//  Created by marty.academy on 6/1/25.
//

import Foundation
import WidgetKit
import UIKit
import MapKit

struct ParkedLocationEntry: TimelineEntry {
    let date: Date
    let title: String
    let address: String
    
    let timeElapsedText: String
    let coordinate: CLLocationCoordinate2D?
    let hasParkedLocation: Bool
    let mapSnapshot: UIImage?
}
