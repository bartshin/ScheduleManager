//
//  ScheduleOfDayInWeek.swift
//  PixelSchedulerWidgetExtension
//
//  Created by Shin on 4/19/21.
//

import SwiftUI
import WidgetKit

struct ScheduleOfDayInWeek: View {
	
	private let date: Date
	private let holiday: HolidayGather.Holiday?
	private let schedules: [Schedule]
	private let palette: SettingKey.ColorPalette
	
	static let scheduleLabelHeight: CGFloat = 30
	
	private var dateFontColor: Color {
		if holiday != nil {
			if date.weekDay == 1 || holiday!.type == .national {
				return Color.red
			}else if date.weekDay == 7 {
				return Color.blue
			}else {
				return Color(palette.tertiary)
			}
		}else {
			if date.weekDay == 1 {
				return Color.pink
			}else if date.weekDay == 7 {
				return Color.blue
			}else {
				return Color(palette.primary)
			}
		}
	}
	
	var body: some View {
		HStack (alignment: .top){
			Link(destination: CustomWidgetURL.create(for: .date, at: date, objectID: nil), label: {
				VStack{
					Text(date.monthDayTimeKoreanString)
					if holiday != nil {
						Text(holiday!.title)
							.font(.caption)
					}
				}
			})
			.font(.custom("RetroGaming", size: 14))
			.padding(5)
			.foregroundColor(dateFontColor)
			.background(LinearGradient(
										gradient: Gradient(
											colors: [
												Color(palette.tertiary.withAlphaComponent(0.5)),
												Color(palette.tertiary.withAlphaComponent(0.4)),Color(palette.tertiary.withAlphaComponent(0.1))]), startPoint: .leading, endPoint: .trailing))
			.cornerRadius(10)
			.offset(y: 5)
			VStack(alignment: .leading) {
				ForEach(schedules){ schedule in
					Link(destination: CustomWidgetURL.create(for: .schedule, at: date, objectID: schedule.id), label: {
						ScheduleDetail(
							for: schedule,
							at: date,
							palette: palette)
					})
					.padding(.top, 10)
				}
			}
		}
	}
	
	init(for schedules: [Schedule],
			 at date: Date,
			 holiday: HolidayGather.Holiday?,
			 palette: SettingKey.ColorPalette) {
		self.date = date
		self.holiday = holiday
		self.schedules = schedules
		self.palette = palette
	}
}

struct ScheduleOfDayInWeek_Previews: PreviewProvider {
	static var previews: some View {
		ScheduleOfDayInWeek(
			for: ScheduleEntry.Dummy.firstSchedules,
			at: Date(),
			holiday: HolidayGather.Holiday(
				dateInt: Date().toInt,
				title: "some holiy day",
				description: "holiday description",
				type: .national),
			palette: .basic)
			.previewContext(WidgetPreviewContext(family: .systemLarge))
	}
}
