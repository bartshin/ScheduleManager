//
//  WidgetHeader.swift
//  PixelSchedulerWidgetExtension
//
//  Created by Shin on 4/17/21.
//

import SwiftUI
import WidgetKit

struct DateSquare: View {
	
	private let config: UserConfig
	/// Number of today schedules : ( Total, Completed )
	private let scheduleCount: Int
	private let date: Date
	private let holiday: HolidayGather.Holiday?
	private var dateFormatter: DateFormatter
	
	private var dateFontColor: Color {
		if holiday != nil {
			if date.weekDay == 1 || holiday!.type == .national {
				return Color.red
			}else if date.weekDay == 7 {
				return Color.blue
			}else {
				return Color(config.palette.tertiary)
			}
		}else {
			if date.weekDay == 1 {
				return Color.pink
			}else if date.weekDay == 7 {
				return Color.blue
			}else {
				return Color(config.palette.primary)
			}
			
		}
	}
	
	private var month: String {
		dateFormatter.dateFormat = "MMM"
		return dateFormatter.string(from: date)
	}
	
	private var day: String {
		dateFormatter.dateFormat = "d"
		return dateFormatter.string(from: date)
	}
	
	var body: some View {
		ZStack {
			GeometryReader { geometryProxy in
				Image(uiImage: config.character.staticImage)
					.resizable()
					.frame(width: 80,
								 height: 80)
					.position(x: 10,
										y: geometryProxy.size.height * -0.4)
				
				VStack {
					Group {
						Text(day)
							.font(.largeTitle)
						Text(month)
						Text(String(date.year))
							.font(.caption)
					}
					.foregroundColor(dateFontColor)
					if holiday != nil {
						Text(holiday!.translateTitle(to: config.dateLanguage))
							.font(.caption)
							.foregroundColor(Color(config.palette.secondary))
					}
				}
				.position(x: geometryProxy.size.width * 0.5,
									y: geometryProxy.size.height * 0.5)
			}
		}
	}
	
	
	init(date: Date, holiday: HolidayGather.Holiday?, config: UserConfig, scheduleCount: Int) {
		self.date = date
		self.holiday = holiday
		self.config = config
		self.scheduleCount = scheduleCount
		dateFormatter = DateFormatter()
		dateFormatter.locale = .init(identifier: config.dateLanguage.locale)
	}
}

struct DateInformationView_Previews: PreviewProvider {
	static var previews: some View {
		DateSquare(date: Date(),
							 holiday: HolidayGather.Holiday(dateInt:  Date().toInt, title: "Christmas Day", description: "", type: .national),
							 config: UserConfig(),
							 scheduleCount: 3)
			.previewContext(WidgetPreviewContext(family: .systemSmall))
	}
}
