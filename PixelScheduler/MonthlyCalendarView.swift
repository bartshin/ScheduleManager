//
//  MonthlyCalendarView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/07.
//

import SwiftUI


struct MonthlyCalendarView: View {
	
	@EnvironmentObject var states: ViewStates
	@EnvironmentObject var scheduleController: ScheduleModelController
	@EnvironmentObject var settingController: SettingController
	@State private var hoveredCellDateInt: Int?
	private let hapticGenerator = UIImpactFeedbackGenerator()
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
			columns: Array(
				repeating: GridItem(
					.adaptive(minimum: size.width / 8),
					spacing: nil,
					alignment: .center), count: 7)) {
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
			.contentShape(Rectangle())
			.onTapGesture {
				guard date.month == referenceDate.month else {
					
					return
				}
				hapticGenerator.generateFeedback(for: settingController.hapticMode)
				SoundEffect.playSound(.paper)
				tapCalendarCell(day)
			}
			.opacity(date.month == referenceDate.month ? 1: 0.2)
			.background(
				Group {
					if hoveredCellDateInt == day {
						RoundedRectangle(cornerRadius: 15)
							.stroke(Color(settingController.palette.primary), lineWidth: 2)
							.padding(-5)
					}
				}
			)
			.onDrop(of: [.plainText],
							isTargeted: createBindingIsHover(for: day)) { providers in
					loadDroppedItem(from: providers, to: day)
			}

	}
	
	private func createBindingIsHover(for dateInt: Int) -> Binding<Bool> {
		Binding<Bool> {
			hoveredCellDateInt == dateInt
		} set: { isHover in
			if isHover {
				hoveredCellDateInt = dateInt
			}else {
				hoveredCellDateInt = nil
			}
		}
	}
	
	private func loadDroppedItem(from providers: [NSItemProvider], to dateInt: Int) -> Bool {
		
		guard let item = providers.first,
					item.canLoadObject(ofClass: String.self) else {
						return false
					}
		_ = item.loadObject(ofClass: String.self) { object, error in
			guard let json = object,
						error == nil,
						let data = json.data(using: .utf8),
						let dict = data.toJsonDictionary() as? [String: String] else{
							assertionFailure("Fail to parse json from dropeed item.")
							return
						}
			if dict["itemType"] == "schedule",
				 let id = dict["id"],
				 let scheduleId = UUID(uuidString: id){
				moveSchedule(scheduleId: scheduleId, to: dateInt)
			}
			else if dict["itemType"] == "sticker",
							let id = dict["id"]{
				let sticker = Sticker(from: id)
				setSticker(sticker, to: dateInt)
			}
		}
		return true
	}
	
	private func moveSchedule(scheduleId: Schedule.ID, to dateInt: Int) {
		guard let schedule = scheduleController.getSchedule(by: scheduleId) else {
						assertionFailure()
						return
					}
		let newTime = schedule.time.setDate(dateInt: dateInt)
		let newSchedule = schedule.modify(time: newTime)
		DispatchQueue.main.async {
			let isSuccess = scheduleController.replaceSchedule(schedule, to: newSchedule, alarmCharacter: settingController.character)
			if !isSuccess {
					showFailMovingScheduleAlert()
			}
		}
	}
	
	private func showFailMovingScheduleAlert() {
		let title: String
		let message: String
		let dismiss: String
		
		switch settingController.language {
		case .english:
			title = "Fail to move schedule"
			message = "Use edit schedule feature instead"
			dismiss = "OK"
		case .korean:
			title = "스케쥴 이동 실패"
			message = "스케쥴 변경 기능을 이용하세요"
			dismiss = "확인"
		}
		
		states.alert = .init(title: title,
												 message: message,
												 action: {},
												 label: {
			Text(dismiss)
		})
	}
	
	private func setSticker(_ sticker: Sticker, to dateInt: Int) {
		DispatchQueue.main.async {
			scheduleController.setSticker(sticker, to: dateInt)
		}
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
