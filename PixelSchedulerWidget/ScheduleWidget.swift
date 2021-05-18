//
//  ScheduleWidget.swift
//  PixelSchedulerWidgetExtension
//
//  Created by Shin on 4/18/21.
//

import SwiftUI
import WidgetKit

struct ScheduleWidget: Widget {
    
    private let kind = "ScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScheduleProvider()) { entry in
            ScheduleWidgetView(for: entry)
        }
        .configurationDisplayName("Upcoming Events")
        .description("일정을 한눈에 볼 수 있어요")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

