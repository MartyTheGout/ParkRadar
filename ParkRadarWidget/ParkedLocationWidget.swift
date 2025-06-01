//
//  ParkedLocationWidget.swift
//  ParkRadarWidgetExtension
//
//  Created by marty.academy on 4/22/25.
//

import WidgetKit
import SwiftUI
import RealmSwift
import CoreLocation

struct ParkedLocationWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ParkedLocationWidget", provider: ParkedLocationWidgetProvider()) { entry in
            ParkedLocationWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    if let mapSnapshot = entry.mapSnapshot {
                        Image(uiImage: mapSnapshot)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.clear
                    }
                }
        }
        .configurationDisplayName("주차 위치 위젯")
        .description("최근 주차 위치를 지도로 보여줍니다.")
        .supportedFamilies([.systemMedium])
    }
}
