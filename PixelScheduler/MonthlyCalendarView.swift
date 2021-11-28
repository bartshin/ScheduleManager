//
//  MonthlyCalendarView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/07.
//

import SwiftUI

struct MonthlyCalendarView: View {
	
	@EnvironmentObject var scheduleController: ScheduleModelController
	@EnvironmentObject var settingController: SettingController
	@Binding var searchRequest: (text: String, priority: Int)
	private let referenceDate: Date
	private let size: CGSize
	private let tapCalendarCell: (Int) -> Void
	private let numberOfWeeksInMonth: Int
	private var datesInMonth: [Int] {
		var datesInMonth = [Int]()
		let yearAndMonth = referenceDate.year * 10000 + referenceDate.month * 100
		let firstDate = (yearAndMonth + 1).toDate!
		var numberOfDayCarriedForward = firstDate.weekDay - 1
		while numberOfDayCarriedForward >= 1 {
			datesInMonth.append(Calendar.current.date(byAdding: .day, value: -numberOfDayCarriedForward, to: firstDate)!.toInt)
			numberOfDayCarriedForward -= 1
		}
		let daysInMonth = Calendar.getDaysInMonth(yearAndMonth)
		for day in 1...daysInMonth {
			datesInMonth.append(yearAndMonth + day)
		}
		let lastDate = (yearAndMonth + daysInMonth).toDate!
		var numberOfDayToAdd = 1
		while numberOfDayToAdd < 8 - lastDate.weekDay {
			datesInMonth.append(Calendar.current.date(byAdding: .day, value: numberOfDayToAdd, to: lastDate)!.toInt)
			numberOfDayToAdd += 1
		}
		return datesInMonth
	}
	
    var body: some View {
		LazyVGrid(
			columns: [GridItem(.adaptive(
				minimum: size.width / 8,
				maximum: size.width / 8),
							   spacing: nil,
							   alignment: .center)]) {
								   ForEach(datesInMonth, id: \.self) { day in
									   drawCalendarCell(for: day)
										   .frame(height: size.height / CGFloat(numberOfWeeksInMonth))
								   }
							   }
    }
	
	private func drawCalendarCell(for day: Int) -> some View{
		let date = day.toDate!
		return CalendarCellView(
			date: date,
			schedules: scheduleController.getSchedules(for: day),
			sticker: scheduleController.stickerTable[day],
			searchRequest: $searchRequest,
			holiday: scheduleController.holidayTable[day],
			colorPalette: settingController.palette)
			.onTapGesture {
				tapCalendarCell(day)
			}
			.opacity(date.month == referenceDate.month ? 1: 0.2)
	}
	
	init(referenceDate: Date, searchRequest: Binding<(text: String, priority: Int)>, size: CGSize, tapCalendarCell: @escaping (Int) -> Void) {
		self.referenceDate = referenceDate
		_searchRequest = searchRequest
		self.size = size
		self.tapCalendarCell = tapCalendarCell
		let yearAndMonth = referenceDate.year * 10000 + referenceDate.month * 100
		let firstDate = (yearAndMonth + 1).toDate!
		let daysInMonth = Calendar.getDaysInMonth(yearAndMonth)
		if (firstDate.weekDay == 7 && daysInMonth >= 30) || (firstDate.weekDay == 6 && daysInMonth == 31) {
			numberOfWeeksInMonth = 6
		}else if referenceDate.month == 2,
				 firstDate.weekDay == 7 {
			numberOfWeeksInMonth = 4
		}else {
			numberOfWeeksInMonth = 5
		}
	}
}
