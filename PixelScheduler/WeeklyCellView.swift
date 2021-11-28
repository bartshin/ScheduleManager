//
//  WeeklyCellView.swift
//  Schedule_B
//
//  Created by Shin on 2/26/21.
//

import SwiftUI

struct WeeklyCellView: View, HolidayColor {
	
	// MARK: Data
	var date: Date
	var holiday: HolidayGather.Holiday?
	var isSelected = false
	var isToday: Bool {
		return date.isSameDay(with: Date())
	}
	var _schedules = [Schedule]()
	var schedules: [Schedule] {
		set {
			var toSort = newValue
			toSort.sort()
			_schedules = Array(toSort.prefix(5))
		}
		get {
			self._schedules
		}
	}
	var labelLanguage: SettingKey.DateLanguage
	
	
	// MARK:- View properties
	var colorPalette: SettingKey.ColorPalette
	
	fileprivate func calcBarScale(for schedule: Schedule) -> CGFloat{
		switch schedule.time {
		case .period(start: let startDate, end: let endDate):
			let period = endDate - startDate
			return min(CGFloat(period / TimeInterval.forOneDay) * 2, 1)
			
		default:
			return 0.1
		}
	}
	
	fileprivate var weekDayView: some View {
		Text(labelLanguage == .english ? date.weekDayStringEnglish: date.weekDayStringKorean)
			.font(.body)
			.foregroundColor(getFontColor(for: date, with: holiday).opacity(0.7))
	}
	
	fileprivate var todayCircle: some View {
		RoundedRectangle(cornerRadius: 30)
			.fill(Color.red.opacity(0.9))
			.frame(width: 35, height: 35, alignment: .center)
			.padding(.all, -5)
	}
	
	fileprivate var dateNumberView: some View {
		Text("\(date.day)")
			.font(.title2)
			.bold()
			.foregroundColor(isToday ? .white : getFontColor(for: date, with: holiday))
	}
	
	var body: some View {
		GeometryReader { geometry in
			VStack{
				VStack(spacing: 0){
					weekDayView
					ZStack{
						if isToday {
							todayCircle
						}
						dateNumberView
					}
				}
				.frame(maxHeight: geometry.size.height * 0.3)
				.position(x: geometry.size.width / 2,
									y: geometry.size.height * 0.2)
				VStack{
					ForEach(schedules) { schedule in
						RoundedRectangle(cornerRadius: 10)
							.fill(Color.byPriority(schedule.priority))
							.frame(width: geometry.size.width * calcBarScale(for: schedule),
										 height: 20)
					}
				}
				.frame(width: geometry.size.width,
							 height: geometry.size.height * 0.5, alignment: .top)
				.position(x: geometry.size.width / 2,
									y: geometry.size.height * 0.2)
			}
		}
		.background(isSelected ? Color(colorPalette.tertiary).opacity(0.3) : Color(colorPalette.quaternary).opacity(0.3))
	}
	init(date: Date, holiday: HolidayGather.Holiday?, colorPalette: SettingKey.ColorPalette, isSelected: Bool, schedules: [Schedule], labelLanguage: SettingKey.DateLanguage) {
		self.date = date
		self.holiday = holiday
		self.isSelected = isSelected
		self.labelLanguage = labelLanguage
		self.colorPalette = colorPalette
		self.schedules = schedules
		
	}
}

















struct WeeklyCellView_Previews: PreviewProvider {
	static var previews: some View {
		WeeklyCellView(
			date: Date(),
			holiday: nil,
			colorPalette: .basic,
			isSelected: true,
			schedules: [
				Schedule(title: "title",
								 description: "description",
								 priority: 1,
								 time: .period(start: Date().aMonthAgo,
															 end: Date().aMonthAfter),
								 alarm: .once(Date())),
				Schedule(title: "title",
								 description: "description",
								 priority: 2,
								 time: .period(start: Calendar.current.date(byAdding: .hour, value: -8, to: Date())!,
															 end: Date()),
								 alarm: .once(Date())),
				Schedule(title: "title",
								 description: "description",
								 priority: 3,
								 time: .period(start: Calendar.current.date(byAdding: .hour, value: -3, to: Date())!,
															 end: Date()),
								 alarm: .once(Date())),
				Schedule(title: "title",
								 description: "description",
								 priority: 4,
								 time: .period(start: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!,
															 end: Date()), alarm: nil)
			], labelLanguage: .korean)
			.frame(
				width: 200,
				height: 300,
				alignment: .center)
			.border(Color.black)
	}
	
}
