//
//  UpCommingSchedule.swift
//  PixelSchedulerWidgetExtension
//
//  Created by Shin on 4/17/21.
//

import SwiftUI

struct UpCommingSchedule: View {
    
    private let palette: UserConfig.ColorPalette
    private let schedule: Schedule
    private let date: Date
    
    private var startDate: Date {
        switch schedule.time {
        case .spot(let date):
            return date
        case .period(start: let startDate, _):
            return startDate
        case .cycle(since: let baseDate, _ , _):
            var baseComponents =  Calendar.current.dateComponents([.calendar, .hour, .minute], from: baseDate)
            baseComponents.year = date.year
            baseComponents.month = date.month
            baseComponents.day = date.day
            return baseComponents.date!
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let labelSize = CGSize(width: geometry.size.width, height: 30)
            ZStack (alignment: .leading) {
                Rectangle()
                    .size(width: labelSize.width, height: labelSize.height)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color(palette.tertiary.withAlphaComponent(0.5)), Color(palette.quaternary.withAlphaComponent(0.5))]), startPoint: .topLeading, endPoint: .bottomTrailing))
                HStack {
                    Rectangle()
                        .size(width: 15, height: labelSize.height)
                        .fill(Color.byPriority(schedule.priority))
                        .frame(width: 20, height: labelSize.height)
                    Text(schedule.title)
                        .foregroundColor(Color(palette.primary))
                    
                    Text(startDate, style: .offset)
                        .font(.caption)
                        .foregroundColor(Color(palette.primary))
                    
                }
            }
            .cornerRadius(10)
            .frame(width: labelSize.width,
                   height: labelSize.height,
                   alignment: .leading)
        }
        
    }
    init(schedule: Schedule, palette: UserConfig.ColorPalette, at date: Date) {
        self.schedule = schedule
        self.palette = palette
        self.date = date
    }
}
