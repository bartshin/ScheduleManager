//
//  MediumScheduleWidgetView.swift
//  PixelScheduler
//
//  Created by bart Shin on 09/06/2021.
//

import SwiftUI

struct MediumScheduleWidgetView: View {
	
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
	private var scheduleUpComming: Schedule?
	private var schedulesForDay: [Schedule]
	
	private var stickerImage: some View {
		Image(uiImage: sticker!.image)
			.resizable()
			.opacity(0.6)
	}
	
	private var dateView: some View {
		Link(destination: CustomWidgetURL.create(for: .date, at: date, objectID: nil), label: {
			DateSquare(date: date,
								 holiday: holiday,
								 config: config,
								 scheduleCount: schedulesForDay.count)
		})
	}
	
	private var scheduleTableView: some View {
		
		VStack {
			if let nextSchedule = scheduleUpComming {
				Link(destination: CustomWidgetURL.create(
							for: .schedule,
							at: date,
							objectID: nextSchedule.id)) {
					UpCommingSchedule(
						schedule: nextSchedule,
						palette: config.palette,
						at: date)
						.padding(.bottom, 40)
				}
			}
			ForEach(schedulesForDay) { schedule in
				Link(destination: CustomWidgetURL.create(for: .schedule, at: date, objectID: schedule.id), label: {
					ScheduleRow(
						for: schedule,
						at: date,
						palette: config.palette)
				})
			}
		}
	}
	
	private var characterView: some View {
		Image(uiImage: config.character.staticImage)
			.resizable()
			.frame(width: 100,
						 height: 100)
			.rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
	}
	var body: some View {
		GeometryReader { geometryProxy in
			HStack{
				ZStack {
					if sticker != nil {
						stickerImage
					}
					dateView
				}
				.frame(width: geometryProxy.size.width * 0.2,
							 height: geometryProxy.size.height * 0.3,
							 alignment: .leading)
				Divider()
				if schedulesForDay.isEmpty, scheduleUpComming == nil {
					Dayoff(config: config, in: geometryProxy.size)
						.padding(.leading, 30)
						.frame(width: geometryProxy.size.width * 0.5)
				}else {
					scheduleTableView
				}
			}
			.padding(20)
			.frame(width: geometryProxy.size.width,
						 height: geometryProxy.size.height)
		}
	}
	
	init(date: Date, config: UserConfig, holidayTable: [Int: HolidayGather.Holiday], stickerTable: [Int: Sticker], scheduleUpComming: Schedule?, schedulesForDay: [Schedule]) {
		self.date = date
		self.config = config
		self.holidayTable = holidayTable
		self.stickerTable = stickerTable
		self.scheduleUpComming = scheduleUpComming
		self.schedulesForDay = schedulesForDay
	}
}

