//
//  SmallWidgetView.swift
//  PixelScheduler
//
//  Created by Shin on 4/15/21.
//

import SwiftUI
import WidgetKit

struct ScheduleWidgetView: View {
	
	@Environment(\.widgetFamily) var family: WidgetFamily
	@State private var firstIndexShowing = 0
	
	private let date: Date
	private let config: UserConfig
	private let holidayTable: [Int: HolidayGather.Holiday]
	private var holiday: HolidayGather.Holiday? {
		holidayTable[date.toInt]
	}
	private let stickerTable: [Int: Sticker]
	private var sticker: Sticker? {
		stickerTable[date.toInt]
	}
	private var numCompleted: Int
	private var scheduleTable: [Int: [Schedule]]
	private var scheduleUpComming: Schedule?
	private var schedulesForDay: [Schedule]
	private var dateIntInWeek: [Int]
	
	var body: some View {
		Group{
			if family == .systemMedium {
				MediumScheduleWidgetView(date: date,
																 config: config,
																 holidayTable: holidayTable,
																 stickerTable: stickerTable,
																 scheduleUpComming: scheduleUpComming,
																 schedulesForDay: schedulesForDay)
			}else if family == .systemLarge {
				LargeScheduleWidgetView(
					date: date,
					config: config,
					holidayTable: holidayTable,
					stickerTable: stickerTable,
					scheduleTable: scheduleTable,
					dateIntInWeek: dateIntInWeek,
					scheduleUpComming: scheduleUpComming,
					schedulesForDay: schedulesForDay)
			}
		}
		.background(Color(config.palette.quaternary.withAlphaComponent(0.3)))
	}
	
	fileprivate static func pickOutUpcomingSchedule(in schedules: inout [Schedule]) -> Schedule? {
		var nextSchedule: Schedule? = nil
		schedules.forEach { schedule in
			let startOfSchedule: Date
			let now = Date()
			switch schedule.time {
			case .spot(let date):
				startOfSchedule = date
			case .period(start: let startDate, _):
				startOfSchedule = startDate
			case .cycle(since: let baseDate, _, _):
				var baseComponents =  Calendar.current.dateComponents([.calendar, .hour, .minute], from: baseDate)
				baseComponents.year = now.year
				baseComponents.month = now.month
				baseComponents.day = now.day
				startOfSchedule = baseComponents.date!
			}
			
			if startOfSchedule > now ,
				 startOfSchedule - now < TimeInterval(60 * 60) {
				if nextSchedule == nil {
					nextSchedule = schedule
				}else if nextSchedule! < schedule {
					nextSchedule = schedule
				}
			}
		}
		if nextSchedule != nil,
			 let duplicatedIndex = schedules.firstIndex(of: nextSchedule!){
			schedules.remove(at: duplicatedIndex)
		}
		return nextSchedule
	}
	
	init(for entry: ScheduleEntry) {
		date = entry.date
		stickerTable = entry.stickerTable
		holidayTable = entry.holidayTable
		config = UserConfig()
		var scheduleNotcompleted = [Schedule]()
		var scheduleCompleted = [Schedule]()
		entry.schedules.forEach {
			if $0.isDone(for: entry.date.toInt) {
				scheduleCompleted.append($0)
			}else {
				scheduleNotcompleted.append($0)
			}
		}
		numCompleted = scheduleCompleted.count
		scheduleUpComming = ScheduleWidgetView.pickOutUpcomingSchedule(in: &scheduleNotcompleted)
		
		// sort schedule
		schedulesForDay = scheduleNotcompleted.sorted(by: { lhs, rhs in
			lhs < rhs
		}) + scheduleCompleted.sorted(by: { lhs, rhs in
			lhs > rhs
		})
		scheduleTable = entry.scheduleTable
		dateIntInWeek = [Int]()
		for day in stride(from: date, to: Calendar.current.date(byAdding: .day, value: 7, to: date)!, by: TimeInterval.forOneDay) {
			dateIntInWeek.append(day.toInt)
		}
	}
}

struct ScheduleWidgetView_Previews: PreviewProvider {
	static var previews: some View {
		ScheduleWidgetView(for:
												ScheduleEntry(
													date: Date(),
													holidayTable: [Int : HolidayGather.Holiday](), stickerTable: [Date().toInt: ScheduleEntry.Dummy.sticker],
													scheduleTable:
														[
															Date().toInt: ScheduleEntry.Dummy.firstSchedules,
															Calendar.current.date(byAdding: .day, value: 2, to: Date())!.toInt: ScheduleEntry.Dummy.firstSchedules
														])
		).previewContext(WidgetPreviewContext(family: .systemMedium))
	}
}

