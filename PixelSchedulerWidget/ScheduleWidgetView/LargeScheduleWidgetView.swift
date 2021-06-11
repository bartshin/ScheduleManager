//
//  LargeScheduleWidgetView.swift
//  PixelSchedulerWidgetExtension
//
//  Created by bart Shin on 09/06/2021.
//

import SwiftUI

struct LargeScheduleWidgetView: View {
	
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
	private var scheduleTable: [Int: [Schedule]]
	private var scheduleUpComming: Schedule?
	private var schedulesForDay: [Schedule]
	private var dateIntInWeek: [Int]
	
	private var characterView: some View {
		Image(uiImage: config.character.staticImage)
			.resizable()
			.frame(width: 100,
						 height: 100)
			.rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
	}
	
	var body: some View {
		GeometryReader { geometryProxy in
			characterView
				.position(x: geometryProxy.size.width * 0.9,
									y: geometryProxy.size.height * 0.1)
			if dateIntInWeek.filter({
				scheduleTable.keys.contains($0) && !scheduleTable[$0]!.isEmpty
			}).isEmpty {
				Dayoff(config: config,
							 in: geometryProxy.size)
					.frame(width: geometryProxy.size.width,
								 height: geometryProxy.size.height)
					.position(x: geometryProxy.size.width * 0.5, y: geometryProxy.size.height * 0.5)
			}else {
				VStack {
					ForEach(dateIntInWeek, id: \.self) { dateInt in
						if let schedules = scheduleTable[dateInt], !schedules.isEmpty {
							ScheduleOfDayInWeek(
								for: schedules,
								at: dateInt.toDate!,
								holiday: holidayTable[dateInt],
								palette: config.palette)
								.frame(width: geometryProxy.size.width,
											 alignment: .leading)
							Divider()
						}
					}
				}
				.padding(10)
			}
		}
	}
	
	
	init(date: Date, config: UserConfig, holidayTable: [Int: HolidayGather.Holiday], stickerTable: [Int: Sticker],
			 scheduleTable: [Int: [Schedule]], dateIntInWeek: [Int], scheduleUpComming: Schedule?, schedulesForDay: [Schedule]) {
		self.date = date
		self.config = config
		self.holidayTable = holidayTable
		self.stickerTable = stickerTable
		self.scheduleUpComming = scheduleUpComming
		self.schedulesForDay = schedulesForDay
		self.scheduleTable = scheduleTable
		self.dateIntInWeek = dateIntInWeek
	}
}

