//
//  SearchResultView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/14.
//

import SwiftUI

struct SearchResultView: View, HolidayColor {
	
	@EnvironmentObject var scheduleController: ScheduleModelController
	@EnvironmentObject var settingController: SettingController
	@Binding var searchRequest: (text: String, priority: Int)
	@State private var searchedSchedules = [Schedule]()
	@State private var searchedHolidays = [HolidayGather.Holiday]()
	var colorPalette: SettingKey.ColorPalette {
		settingController.palette
	}
	
	private func query() {
		withAnimation {
			searchedSchedules = scheduleController.querySchedulesTitle(by: searchRequest.text)
			if let language = LanguageDetector.detect(for: searchRequest.text) {
				searchedHolidays = scheduleController.queryHoliday(
					by: searchRequest.text, for: language)
					.sorted{ lhs, rhs in
						lhs.dateInt < rhs.dateInt
					}
			}
		}
	}
	
    var body: some View {
		List {
			if !searchedHolidays.isEmpty {
				Section(header: holidayHeader) {
					ForEach(searchedHolidays, id: \.self) {
						drawRow(for: $0)
					}
				}
				.listRowBackground(rowBackgroundColor)
			}
			if !searchedSchedules.isEmpty {
				Section(header: scheduleHeader) {
					ForEach(searchedSchedules) {
						drawRow(for: $0)
					}
				}
				.listRowBackground(rowBackgroundColor)
			}
			if searchedHolidays.isEmpty, searchedSchedules.isEmpty {
				Section {
					emptyResultPlaceHolder
				}
				.listRowBackground(rowBackgroundColor)
			}
		}
		.onAppear(perform: query)
		.onChange(of: searchRequest.text) { _ in
			query()
		}
	}
	
	private var rowBackgroundColor: Color {
		Color(settingController.palette.quaternary.withAlphaComponent(0.5))
	}
	
	private var scheduleHeader: some View {
		Group {
			if settingController.language == .korean {
				Text("\(searchRequest.text)로 찾은 스케쥴")
			}else {
				Text("Scheduls found by \(searchRequest.text)")
			}
		}
	}
	
	private var holidayHeader: some View {
		Group {
			if settingController.language == .korean {
				Text("\(searchRequest.text)로 찾은 휴일")
			}else {
				Text("Holidays found by \(searchRequest.text)")
			}
		}
	}
	
	private var emptyResultPlaceHolder: some View {
		Group {
			if settingController.language == .korean {
				Text("\(searchRequest.text)의 검색 결과가 없습니다")
			}else {
				Text("\(searchRequest.text) is not found")
			}
		}
	}
	
	private func drawRow(for schedule: Schedule) -> some View {
		VStack {
			Text(schedule.title)
				.font(.title2)
			Text(schedule.time.getDescription(for: settingController.language))
		}
	}
	
	private func drawRow(for holiday: HolidayGather.Holiday) -> some View {
		VStack {
			Text(holiday.translateTitle(to: settingController.language))
				.font(.title2)
			Text(holiday.getDateString(for: settingController.language))
		}
	}
}
