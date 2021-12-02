//
//  EditScheduleView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/29.
//

import SwiftUI

struct EditScheduleView: View {
	
	private let scheduleToEdit: Schedule?
	@EnvironmentObject var scheduleController: ScheduleModelController
	@EnvironmentObject var settingController: SettingController
	@State private var scheduleTitle: String
	@State private var priority: Int
	/// Actual date picked for schedule
	@State private var scheduleDate: Schedule.DateType
	/// Currently date type UI showing
	@State private var showingDateType: DateType
	@StateObject private var cycleSelections =  CyclePickerView.Selected()
	private let selectedDate: Date?
	
    var body: some View {
		GeometryReader{ geometry in
			VStack(spacing: 0) {
				HStack {
					drawCharacter(in: geometry.size)
					titleInput
					Spacer(minLength: 50)
				}
				Divider()
				priorityPicker
					.padding(.vertical, 20)
					.padding(.horizontal, 50)
				Divider()
				dateTypePicker
					.padding(.top, 20)
				datePicker
				Divider()
			}
		}
		.navigationTitle(navigationTitle)
    }
	
	private func drawCharacter(in size: CGSize) -> some View {
		CharacterHelperView(
			character: settingController.character,
			guide: .editSchedule,
			helpWindowSize: CGSize(width: size.width * 0.8, height: size.height * 0.6),
			characterLocation: CGPoint(x: size.width * 0.1,
									   y: size.height * 0.1))
	}
	
	private var titleInput: some View {
		TextField(settingController.language == .korean ? "제목을 입력하세요": "Schedule Title", text: $scheduleTitle)
			.textFieldStyle(.roundedBorder)
	}
	
	private var priorityPicker: some View {
		Picker("Schedule Priority", selection: $priority) {
			ForEach(1..<6) { priority in
				Text(Color.PriorityButton.by(priority))
					.tag(priority)
			}
		}
		.pickerStyle(.segmented)
	}
	
	private var dateTypePicker: some View {
		Picker("Schedule date type", selection: $showingDateType) {
			ForEach(DateType.allCases) { type in
				Text(type.getDescription(for: settingController.language))
					.font(.custom(settingController.language.font, size: 15))
					.tag(type)
			}
		}
		.pickerStyle(.segmented)
		.padding(.horizontal, 40)
	}
	
	private var datePicker: some View {
		Group {
			if showingDateType == .spot {
				spotDatePicker
			}
			else if showingDateType == .period {
				periodDatePicker
			}
			else {
				CyclePickerView(
					selected: cycleSelections,
					language: settingController.language,
					segmentType: showingDateType == .weeklyCycle ? .weekly: .monthly)
					.padding(.vertical, 20)
					.fixedSize(horizontal: false, vertical: true)
			}
		}
	}
	
	private var spotDatePicker: some View {
		DatePicker(settingController.language == .korean ? "날짜 선택": "Pick date", selection: .init(get: {
			if case .spot(let date) = scheduleDate {
				return date
			}
			else if case .period(let startDate, _) = scheduleDate {
				return startDate
			}
			else {
				return selectedDate ?? Date()
			}
		}, set: { newDate in
			scheduleDate = .spot(newDate)
		}))
			.environment(\.locale, Locale(identifier: settingController.language.locale))
			.datePickerStyle(.graphical)
			.padding(.horizontal, 30)
	}
	
	private var periodDatePicker: some View {
		let startDate: Date
		if case .spot(let date) = scheduleDate {
			startDate = date
		}
		else if case .period(let scheduleStatDate, _) = scheduleDate {
			startDate = scheduleStatDate
		}else {
			startDate = selectedDate ?? Date()
		}
		let endDate: Date
		if case .period(_, let scheduleEndDate) = scheduleDate {
			endDate = scheduleEndDate
		}else {
			endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
		}
		return VStack {
			DatePicker(settingController.language == .korean ? "시작 날짜": "Start date", selection: .init(get: {
				startDate
			}, set: { newDate in
				if case .period(_, let scheduleEndDate) = scheduleDate,
				scheduleEndDate > newDate{
					scheduleDate = .period(start: newDate, end: scheduleEndDate)
				} else {
					scheduleDate = .period(start: newDate, end: Calendar.current.date(byAdding: .day, value: 1, to: newDate)!)
				}
			}))
			DatePicker(settingController.language == .korean ? "종료 날짜": "End date", selection: .init(get: {
				endDate
			}, set: { newDate in
				if case .period(let scheduleStartDate, _) = scheduleDate,
					 newDate > scheduleStartDate{
					scheduleDate = .period(start: scheduleStartDate, end: newDate)
				}else {
					scheduleDate = .period(start: Calendar.current.date(byAdding: .day, value: -1, to: newDate)!, end: newDate)
				}
			}))
		}
		.environment(\.locale, Locale(identifier: settingController.language.locale))
		.padding(.horizontal, 40)
		.padding(.vertical, 20)
	}
	
	private var navigationTitle: String {
		if scheduleToEdit != nil {
			return settingController.language == .korean ? "스케쥴 수정": "Edit Schedule"
		}else {
			return settingController.language == .korean ? "스케쥴 추가": "New Schedule"
		}
	}
	
	init(scheduleToEdit: Schedule, selectedDate: Date? = nil) {
		self.scheduleToEdit = scheduleToEdit
		_scheduleTitle = .init(initialValue: scheduleToEdit.title)
		_priority = .init(initialValue: scheduleToEdit.priority)
		let dateType: DateType
		switch scheduleToEdit.time {
		case .spot(_):
			dateType = .spot
		case .cycle(_, let fator, _):
			dateType = fator == .weekday ? .weeklyCycle: .monthlyCycle
		case .period(_, _):
			dateType = .period
		}
		_scheduleDate = .init(initialValue: scheduleToEdit.time)
		_showingDateType = .init(initialValue: dateType)
		self.selectedDate = selectedDate
	}
	
	init(selectedDate: Date) {
		self.scheduleToEdit = nil
		self.selectedDate = selectedDate
		_scheduleTitle = .init(initialValue: "")
		_priority = .init(initialValue: 1)
		_scheduleDate = .init(initialValue: .spot(selectedDate))
		_showingDateType = .init(initialValue: .spot)
	}
	
	private enum DateType: Int, CaseIterable, Identifiable {
		
		var id: Int {
			self.rawValue
		}
		case spot
		case period
		case weeklyCycle
		case monthlyCycle
		
		func getDescription(for language: SettingKey.Language) -> String {
			switch self {
			case .spot:
				return language == .korean ? "시점": "Pick moment"
			case .weeklyCycle:
				return language == .korean ? "매주 반복": "Repeat every week"
			case .monthlyCycle:
				return language == .korean ? "매달 반복": "Repeat every month"
			case .period:
				return language == .korean ? "기간": "Pick period"
			}
		}
	}
}

struct AddScheduleView_Previews: PreviewProvider {
    static var previews: some View {
		EditScheduleView(selectedDate: Date())
			.environmentObject(ScheduleModelController())
			.environmentObject(SettingController())
    }
}
