//
//  PixelSchedulerWidget.swift
//  PixelSchedulerWidget
//
//  Created by Shin on 4/16/21.
//

import WidgetKit
import SwiftUI


@main
struct PixelSchedulerWidgets: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        ScheduleWidget()
        TaskWidget()
    }
}
