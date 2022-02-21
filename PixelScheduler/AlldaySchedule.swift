//
//  DailyViewAlldaySchedule.swift
//  PixelScheduler
//
//  Created by Shin on 2/27/21.
//

import SwiftUI

struct DailyViewAlldaySchedule: View {
	
	@EnvironmentObject var scheduleController: ScheduleModelController
	private let scheduleIds: [Schedule.ID]
	private var schedules: [Schedule] {
		scheduleIds.compactMap(scheduleController.getSchedule(by:))
	}
	@ObservedObject var dataSource: DailyViewDataSource
	private let tapSchedule: (Schedule) -> Void
	private let colorPalette: SettingKey.ColorPalette
	private let size: CGSize
	private var titleColor: Color {
		Color(colorPalette.primary)
	}
	var body: some View {
		VStack {
			Text("All day schedule")
				.bold()
				.withCustomFont(size: .title3, for: .english)
				.foregroundColor(Color(colorPalette.primary))
			ForEach(schedules){ schedule in
				Text(schedule.title)
					.font(.body)
					.baselineOffset(5)
					.foregroundColor(Color.byPriority(schedule.priority))
					.offset(x: 5)
					.onTapGesture {
						tapSchedule(schedule)
					}
			}
			.padding(5)
		}
		.frame(maxWidth: size.width,
					 maxHeight: size.height * 0.7)
		.cornerRadius(10)
		.background(RoundedRectangle(cornerRadius: 0)
									.fill(Color(colorPalette.quaternary.withAlphaComponent(0.7)))
									.border(Color(colorPalette.primary), width: 5)
									.cornerRadius(10)
									.frame(width: size.width,
												 height: size.height)
		)
	}
	init(scheduleIds: [Schedule.ID], with palette: SettingKey.ColorPalette,
			 in size: CGSize,
			 watch dataSource: DailyViewDataSource,
			 tapScheduleHandeler: @escaping (Schedule) -> Void) {
		self.scheduleIds = scheduleIds
		self.dataSource = dataSource
		self.colorPalette = palette
		self.size = size
		self.tapSchedule = tapScheduleHandeler
	}
}



