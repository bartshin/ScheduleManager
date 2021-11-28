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
	var imageProvider: DailyViewDataSource?
	/// Change left bar color menually for search result
	var isDone = false
	
	// MARK:- View properties
	private let colorPalette: SettingKey.ColorPalette
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
	
	fileprivate var scheduleTitleView: some View {
		Text(schedule.title)
			.font(schedule.title.count > 10 ?
							.custom("YANGJIN", size: 12)
							: .custom("YANGJIN", size: 15))
			.baselineOffset(10)
			.bold()
			.lineLimit(1)
			.foregroundColor(titleColor)
	}
	
	fileprivate var scheduleDescriptionView: some View {
		Text(schedule.description)
			.font(schedule.description.count > 10 ? .caption : .body)
			.foregroundColor(descriptionColor)
	}
	
	fileprivate var alarmImageView: some View {
		Image(systemName: schedule.isAlarmOn ? "alarm.fill" : "alarm")
			.foregroundColor(schedule.isAlarmOn ? appendixButtonColor : .gray)
	}
	
	var body: some View {
		GeometryReader { geometry in
			ZStack (alignment: .top) {
				Rectangle()
					.size(width: 10, height: geometry.size.height)
					.foregroundColor(isDone ? .gray: Color.byPriority(schedule.priority))
				if let contact = schedule.contact, imageProvider != nil {
					ContactImageView(
						name: contact.name,
						priority: schedule.priority,
						image: imageProvider!.profileImages[schedule.id] ,
						palette: colorPalette)
						.aspectRatio(contentMode: .fit)
						.frame(width: min(geometry.size.width * 0.5, 80))
						.position(x: geometry.size.width * 0.8, y: 30)
				}
				
				VStack (alignment: .leading) {
					scheduleTitleView
					HStack(spacing: 20) {
						scheduleDescriptionView
							.frame(width: geometry.size.width * 0.5)
						if schedule.alarm != nil {
							alarmImageView
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
	init(for schedule: Schedule, with pallete: SettingKey.ColorPalette, watch dataSource: DailyViewDataSource?) {
		self.schedule = schedule
		colorPalette = pallete
		self.imageProvider = dataSource
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
			watch: DailyViewDataSource())
			.frame(width: 200,
						 height: 150)
			.position(x: 200, y: 300)
	}
}
