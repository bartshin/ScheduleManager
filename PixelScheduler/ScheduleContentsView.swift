//
//  DailyCellContentsView.swift
//  Schedule_B
//
//  Created by Shin on 2/27/21.
//

import SwiftUI

struct DailyScheduleContentsView: View {
    
    // MARK: Data
    var schedule: Schedule
    @ObservedObject var dataSource: ScrollviewDataSource
    
    // MARK:- View properties
    private let colorPalette: SettingController.ColorPalette
    private var titleColor: Color {
        Color(colorPalette.primary)
    }
    private var descriptionColor: Color {
        Color(colorPalette.secondary)
    }
    private var appendixButtonColor: Color {
        Color.accentColor
    }
    private let maxHeight: CGFloat = 200
    private let minHeight: CGFloat = 100
    
    var body: some View {
        GeometryReader { geometry in
            ZStack (alignment: .top) {
                Rectangle()
                    .size(width: 10, height: geometry.size.height)
                    .foregroundColor(Color.byPriority(schedule.priority))
                if let contact = schedule.contact {
                    ContactImageView(
                        name: contact.name,
                        priority: schedule.priority,
                        image: dataSource.profileImages[schedule.id] ,
                        palette: colorPalette)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: min(geometry.size.width * 0.5, 80))
                        .offset(y: -50)
                }
                VStack (alignment: .leading) {
                    Text(schedule.title)
                        .font(schedule.title.count > 10 ?
                                .custom("YANGJIN", size: 12)
                                : .custom("YANGJIN", size: 15))
                        .baselineOffset(10)
                        .bold()
                        .lineLimit(1)
                        .foregroundColor(titleColor)
                    HStack(spacing: 20) {
                        Text(schedule.description)
                            .font(schedule.description.count > 10 ? .caption : .body)
                            .foregroundColor(descriptionColor)
                            .frame(width: geometry.size.width * 0.5)
                        if schedule.alarm != nil {
                            Image(systemName: schedule.isAlarmOn ? "alarm.fill" : "alarm")
                                .foregroundColor(schedule.isAlarmOn ? appendixButtonColor : .gray)
                        }
                        if schedule.location != nil {
                            Image(systemName: "location.viewfinder")
                                .foregroundColor(appendixButtonColor)
                        }
                    }
                }
                .frame(width: geometry.size.width,
                       height: geometry.size.height,
                       alignment: .leading)
                .offset(x: 20)
            }
        }
    }
    init(for schedule: Schedule, with pallete: SettingController.ColorPalette, watch dataSource: ScrollviewDataSource) {
        self.schedule = schedule
        colorPalette = pallete
        self.dataSource = dataSource
    }
    
}

struct DailyScheduleContentsView_Previews: PreviewProvider {
    static var previews: some View {
        DailyScheduleContentsView(
            for: Schedule(
                title: "타이틀",
                description: "상세 설명 상세 설명  상세 설명\n 상세 설명",
                priority: 1,
                time: .spot(Date()),
                alarm: .once(Date())),
            with: .basic,
            watch: ScrollviewDataSource())
            .frame(width: 200,
                   height: 150)
            .position(x: 200, y: 300)
    }
}
