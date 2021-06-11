//
//  DailyCellAlldaySchedulView.swift
//  Schedule_B
//
//  Created by Shin on 2/27/21.
//

import SwiftUI

struct DailyTableAlldaySchedule: View {
    
    private let schedules: [Schedule]
    @ObservedObject var dataSource: ScrollViewDataSource
    private let tapSchedule: (Schedule) -> Void
    private let colorPalette: SettingKey.ColorPalette
    private let size: CGSize
    private var titleColor: Color {
        Color(colorPalette.primary)
    }
    private var descriptionColor: Color {
        Color(colorPalette.secondary)
    }
    var body: some View {
        VStack {
            Text("All day schedule")
                .font(.custom("RetroGaming", size: 16))
                .bold()
                .foregroundColor(Color(colorPalette.primary))
                .padding(.top, 10)
            ForEach(schedules){ schedule in
                VStack(alignment: .leading) {
                    Text(schedule.title)
                        .font(.custom("YANGJIN", fixedSize: 14))
                        .baselineOffset(7)
                        .foregroundColor(titleColor)
                    Text(schedule.description)
                        .font(.caption)
                        .offset(x: 10)
                        .foregroundColor(descriptionColor)
                }
                .padding(.bottom, 5)
                .offset(x: 5)
                .onTapGesture {
                    tapSchedule(schedule)
                }
            }
            .frame(maxWidth: size.width,
                   maxHeight: size.height * 0.7)
            .padding()
        }
        .background(Color(colorPalette.quaternary.withAlphaComponent(0.7)))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 0)
                    .opacity(0)
                    .border(Color(colorPalette.primary), width: 5)
                    .cornerRadius(10)
                    .frame(width: size.width,
                           height: size.height)
        )
        
    }
    init(schedules: [Schedule], with palette: SettingKey.ColorPalette,
         in size: CGSize,
         watch dataSource: ScrollViewDataSource,
         tapScheduleHandeler: @escaping (Schedule) -> Void) {
        self.schedules = schedules
        self.dataSource = dataSource
        self.colorPalette = palette
        self.size = size 
        self.tapSchedule = tapScheduleHandeler
    }
}



