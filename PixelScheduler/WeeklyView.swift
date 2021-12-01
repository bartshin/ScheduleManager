//
//  WeeklyView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/21.
//

import SwiftUI

struct WeeklyView: View {
	
	@EnvironmentObject var scheduleController: ScheduleModelController
	@EnvironmentObject var settingController: SettingController
	@StateObject private var dailyViewData = DailyViewDataSource()
	@StateObject private var contactGather = ContactGather()
	@Binding var selectedDateInt: Int?
	@State private var currentShowingDateInt: Int
	@State private var datesRepresentOneWeek: [Int]
	
	private func getDatesForWeek(contain dateInt: Int) -> [Date] {
		guard let givenDate = dateInt.toDate else {
				  assertionFailure()
				  return []
			  }
		let givenWeekDay = givenDate.weekDay
		var dateInts = [Date]()
		for offset in (1 - givenWeekDay)...(7 - givenWeekDay) {
			dateInts.append(Calendar.current.date(byAdding: .day, value: offset
												  , to: givenDate)!)
		}
		return dateInts
	}
	
    var body: some View {
		GeometryReader { geometry in
			VStack(spacing: 0) {
				drawTopWeeklyView(in: geometry.size)
				dailyView
			}
			.overlay(floatingView
						.position(x: geometry.size.width * 0.2,
								  y: geometry.size.height * 0.4)
			)
		}
		.navigationBarTitle("Weekly Schedule")
		.navigationBarTitleDisplayMode(.inline)
    }

	private func drawTopWeeklyView(in size: CGSize) -> some View {
		HStack {
			TabView(selection: $currentShowingDateInt) {
				ForEach(datesRepresentOneWeek, id: \.self) { dateInt in
					drawCellsForAWeek(contain: dateInt)
				}
			}
			.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
			.onChange(of: currentShowingDateInt, perform: updateDatesForWeeks(baseOn:))
		}
		.frame(width: size.width,
			   height: max(size.height * 0.2, 150))
	}
	
	private func drawCellsForAWeek(contain dateInt: Int) -> some View {
		HStack (spacing: 0) {
			ForEach(getDatesForWeek(contain: dateInt), id: \.self) { date in
				WeeklyCellView(date: date,
							   holiday: scheduleController.holidayTable[date.toInt],
							   colorPalette: settingController.palette,
							   isSelected: date.toInt == selectedDateInt,
							   schedules: scheduleController.getSchedules(for: date.toInt),
							   labelLanguage: settingController.language)
					.onTapGesture {
						withAnimation {
							selectedDateInt = date.toInt
						}
					}
			}
		}
	}
	
	private func updateDatesForWeeks(baseOn dateInt: Int) {
		if dateInt == datesRepresentOneWeek.first ||
			dateInt == datesRepresentOneWeek.last {
			datesRepresentOneWeek = (-5...5).reduce(into: [Int]()) { dates, index in
				dates.append(Calendar.current.date(byAdding: .day, value: 7*index, to: dateInt.toDate!)!.toInt)
			}
		}
	}
	
	private var floatingView: some View {
		VStack {
			GIFImage(name: settingController.character.idleGif)
				.frame(width: 50, height: 50)
				.scaleEffect(2)
			Group {
				if let dateInt = selectedDateInt,
				   let holiday = scheduleController.holidayTable[dateInt] {
					drawHolidayLabel(holiday)
				}
			}
		}
	}
	
	private func drawHolidayLabel(_ holiday: HolidayGather.Holiday) -> some View {
		ZStack {
			RoundedRectangle(cornerRadius: 20)
				.fill(Color(settingController.palette.quaternary.withAlphaComponent(0.5)))
				.frame(width: 140, height: 75)
			Image("bulletin_board")
				.resizable()
				.frame(width: 150, height: 80)
			Text(holiday.translateTitle(to: settingController.language))
				.font(Font.custom(settingController.language.font, size: 18)
				)
		}
	}
	
	private var dailyView: some View {
		DailyScrollView(data: dailyViewData,
						date: selectedDateInt?.toDate,
						colorPalette: settingController.palette,
						visualMode: settingController.visualMode,
						language: settingController.language)
			.onChange(of: selectedDateInt) {
				guard let newDate = $0?.toDate else {
					return
				}
				updateDailyViewData(date: newDate)
			}
			.onAppear {
				guard let date = selectedDateInt?.toDate else {
					assertionFailure()
					return
				}
				updateDailyViewData(date: date)
			}
	}
	
	private func updateDailyViewData(date: Date) {
		let schedules = scheduleController.getSchedules(for: selectedDateInt!)
		dailyViewData.setNewSchedule(schedules, of: date)
		if contactGather.isContactAvailable {
			getProfileImages(of: schedules)
		}else {
			contactGather.requestPermission(permittedHandler: {
				getProfileImages(of: schedules)
			}, deniedHandler: {})
		}
	}
	
	

	private func getProfileImages(of schedules: [Schedule]) {
		var contactMap = [ String : UUID ]()
		schedules.forEach {
			if let contact = $0.contact, contactMap[contact.contactID] == nil {
				contactMap[contact.contactID] = $0.id
			}
		}
		
		if contactGather.isContactAvailable, !contactMap.isEmpty,
		   let result = try? contactGather.getContacts(
			by: Array(contactMap.keys) , forImage: true){
			result.forEach { contact in
				let scheduleID = contactMap[contact.identifier]!
				if dailyViewData.profileImages[scheduleID] == nil ,
				   let data = contact.thumbnailImageData,
				   let image = UIImage(data: data) {
					dailyViewData.profileImages[scheduleID] = image
				}
			}
		}
	}
	
	init(selectedDateInt: Binding<Int?>) {
		_selectedDateInt = selectedDateInt
		_currentShowingDateInt = .init(initialValue: selectedDateInt.wrappedValue!)
		let middleDate = selectedDateInt.wrappedValue!.toDate!
		_datesRepresentOneWeek = .init(initialValue: (-5...5).reduce(into: [Int]()) { dates, index in
			dates.append(Calendar.current.date(byAdding: .day, value: 7*index, to: middleDate)!.toInt)
		})
	}
}

struct WeeklyView_Previews: PreviewProvider {
    static var previews: some View {
		WeeklyView(selectedDateInt: .constant(Date().toInt))
			.environmentObject(ScheduleModelController())
			.environmentObject(SettingController())
    }
}
