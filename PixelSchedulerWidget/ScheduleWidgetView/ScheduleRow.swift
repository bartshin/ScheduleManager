//
//  ScheduleRowView.swift
//  PixelSchedulerWidgetExtension
//
//  Created by Shin on 4/17/21.
//

import SwiftUI

struct ScheduleRow: View {
	
	private let palette: SettingKey.ColorPalette
	private let date: Date
	private let schedule: Schedule
	
	var timeLabel: some View {
		switch schedule.time {
		case .spot(let date):
			return Text(date, style: .time)
		case .period(start: let startDate, end: let endDate):
			return Text(startDate...endDate)
		case .cycle(since: let date, _, _):
			return Text(date, style: .time)
		}
		
	}
	var iconSet: some View {
		return Group {
			if schedule.alarm != nil {
				Image(systemName: schedule.isAlarmOn ? "alarm.fill" : "alarm")
					.foregroundColor(schedule.isDone(for: date.toInt) ? Color(.lightGray): (schedule.isAlarmOn ? .red : Color(palette.secondary)))
					.scaleEffect(CGSize(width: 0.8, height: 0.8))
			}
			if schedule.location != nil {
				Image(systemName: "location.viewfinder")
					.foregroundColor(schedule.isDone(for: date.toInt) ? Color(.lightGray): Color(palette.secondary))
					.scaleEffect(CGSize(width: 0.8, height: 0.8))
			}
			if schedule.contact != nil {
				Image(systemName: "person.crop.circle")
					.foregroundColor(schedule.isDone(for: date.toInt) ? Color(.lightGray): Color(palette.secondary))
					.scaleEffect(CGSize(width: 0.8, height: 0.8))
			}
		}
	}
	
	private func addZero(to number: Int) -> String {
		if number < 10 {
			return "0" + String(number)
		}else {
			return String(number)
		}
	}
	
	var body: some View {
		GeometryReader{ geometryProxy in
			Circle()
				.size(width: 10, height: 10)
				.foregroundColor(schedule.isDone(for: date.toInt) ? Color(.lightGray) : Color.byPriority(schedule.priority))
			HStack (alignment: .center) {
				timeLabel
					.foregroundColor(schedule.isDone(for: date.toInt) ? Color(.lightGray) : Color(palette.secondary))
					.font(.caption2)
				Text(schedule.title)
					.font(.footnote)
					.bold()
					.lineLimit(1)
					.padding(.trailing, 10)
					.foregroundColor(schedule.isDone(for: date.toInt) ? Color(.lightGray) : Color(palette.primary))
				iconSet
			}
			.offset(x: 20, y: -5)
		}
	}
	
	init(for schedule: Schedule, at date: Date, palette: SettingKey.ColorPalette) {
		self.schedule = schedule
		self.date = date
		self.palette = palette
	}
}
