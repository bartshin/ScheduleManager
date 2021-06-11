//
//  ScheduleDetail.swift
//  PixelSchedulerWidgetExtension
//
//  Created by Shin on 4/19/21.
//

import SwiftUI

struct ScheduleDetail: View {
	
	private let date: Date
	private let schedule: Schedule
	private let palette: SettingKey.ColorPalette
	
	var body: some View {
		VStack(alignment: .leading) {
			let rowComponents = ScheduleRow(for: schedule, at: date, palette: palette)
			HStack (alignment: .bottom) {
				let markerSize = CGSize(width: 5, height: 15)
				Rectangle()
					.size(markerSize)
					.frame(width: markerSize.width , height: markerSize.height)
					.cornerRadius(3)
					.foregroundColor(schedule.isDone(for: date.toInt) ? Color(.lightGray): Color.byPriority(schedule.priority))
				Text(schedule.title)
					.font(.caption)
					.foregroundColor(schedule.isDone(for: date.toInt) ? Color(.lightGray): Color(palette.primary))
					.bold()
				rowComponents.timeLabel
					.font(.caption2)
			}
			.padding(.bottom , -5)
			HStack {
				Text(schedule.description)
					.lineLimit(1)
					.font(.caption2)
					.foregroundColor(schedule.isDone(for: date.toInt) ? Color(.lightGray): Color(palette.secondary))
					.padding(.leading, 20)
				rowComponents.iconSet
			}
			.padding(.leading, 20)
		}
		.frame(height: ScheduleOfDayInWeek.scheduleLabelHeight)
	}
	
	init(for schedule: Schedule, at date: Date, palette: SettingKey.ColorPalette) {
		self.schedule = schedule
		self.date = date
		self.palette = palette
	}
}
