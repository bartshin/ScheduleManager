//
//  TaskWidget.swift
//  PixelScheduler
//
//  Created by Shin on 4/20/21.
//


import SwiftUI
import WidgetKit

struct TaskWidget: Widget {
    
    private let kind = "TaskWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskProvider()) { entry in
            TaskWidgetView(entry: entry)
        }
        .configurationDisplayName("To Do")
        .description("마지막으로 확인한 할일들을 볼 수 있어요")
        .supportedFamilies([.systemMedium])
        
    }
}

