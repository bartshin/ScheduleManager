//
//  DailyTableScheduleBackground.swift
//  PixelScheduler
//
//  Created by Shin on 2/28/21.
//

import SwiftUI

struct DailyTableScheduleBackground: View {
    
    private let date: Date?
    private let schedule: Schedule
    private let width: CGFloat
    private let height: CGFloat
    
    var body: some View {
        Rectangle()
            .frame(
                width: width,
                height: height)
            .foregroundColor(schedule.isDone(for: date!.toInt) == false ? Color.backgroundByPriority(schedule.priority): .gray)
            .opacity(0.8)
    }
    init(for schedule: Schedule, width: CGFloat, height: CGFloat, date: Date) {
        self.schedule = schedule
        self.width = width
        self.height = height
        self.date = date
    }
}
