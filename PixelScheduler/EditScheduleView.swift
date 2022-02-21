//
//  EditScheduleView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/29.
//

import SwiftUI

struct EditScheduleView: View {
	
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
				return language == .korean ? "시점": "Moment"
			case .weeklyCycle:
				return language == .korean ? "매주 반복": "Weekly"
			case .monthlyCycle:
				return language == .korean ? "매달 반복": "Monthly"
			case .period:
				return language == .korean ? "기간": "Period"
			}
		}
	}
	
	@EnvironmentObject var scheduleController: ScheduleModelController
	@EnvironmentObject var settingController: SettingController
	@Environment(\.presentationMode) var presentationMode
	private let scheduleToEdit: Schedule?
	@State private var scheduleTitle: String
	@State private var priority: Int
	/// Actual date picked for schedule
	@State private var scheduleDate: Schedule.DateType
	/// Currently date type UI showing
	@State private var showingDateType: DateType
	@StateObject private var cycleSelections = CyclePickerView.Selected()
	private let selectedDate: Date?
	@State private var alarm: Schedule.Alarm?
	@State private var contact: Schedule.Contact?
	@State private var selectedLocation: Schedule.Location?
	@State private var isShowingContactPicker = false
	@State private var isShowingLocationPicker: Bool
	@State private var description: String
	@State private var alertMessage: CharacterAlert<Text, Text>?
	
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
		_alarm = .init(initialValue: scheduleToEdit.alarm)
		_contact = .init(initialValue: scheduleToEdit.contact)
		self.selectedDate = selectedDate
		_isShowingLocationPicker = .init(initialValue: false)
		_selectedLocation = .init(initialValue: scheduleToEdit.location)
		_description = .init(initialValue: scheduleToEdit.description)
	}
	
	init(selectedDate: Date) {
		self.scheduleToEdit = nil
		self.selectedDate = selectedDate
		_scheduleTitle = .init(initialValue: "")
		_priority = .init(initialValue: 1)
		_scheduleDate = .init(initialValue: .spot(selectedDate))
		_showingDateType = .init(initialValue: .spot)
		_contact = .init(initialValue: nil)
		_alarm = .init(initialValue: nil)
		_isShowingLocationPicker = .init(initialValue: false)
		_selectedLocation = .init(initialValue: nil)
		_description = .init(initialValue: String())
	}
	
	var body: some View {
		GeometryReader{ geometry in
			ScrollViewReader{ scrollView in
				ScrollView(.vertical, showsIndicators: false) {
					ZStack{
						Color(settingController.palette.quaternary.withAlphaComponent(0.2))
							.onTapGesture(perform: hideKeyboard)
						VStack(spacing: 20) {
							navigationBar
							drawTitleInput(in: geometry.size)
							priorityPicker
							dateTypePicker
							datePicker
							alarmPicker
							contactPicker
								.sheet(isPresented: $isShowingContactPicker) {
									ContactPickerRepresentable { contact = $0 }
								}
							drawLocationBar(scrollView: scrollView)
							drawDescriptionInput(scrollView: scrollView)
							if #available(iOS 15.0, *) {
								Spacer()
									.frame(height: 50)
									.id("descriptionInputKeyboardArea")
							}
						}
					}
				}
			}
		}
		.navigationTitle(navigationTitle)
	}
	
	private var navigationBar: some View {
		VStack {
			HStack {
				Button {
					presentationMode.wrappedValue.dismiss()
				} label: {
					Image(systemName: "xmark")
						.foregroundColor(.pink)
				}
				Spacer()
				switch settingController.language {
				case .korean:
					Text(scheduleToEdit == nil ? "새로운 스케쥴": "스케쥴 수정")
				case .english:
					Text(scheduleToEdit == nil ? "New Schedule": "Edit Schedule")
				}
				Spacer()
				Button {
					hideKeyboard()
					if checkValidate() {
						let schedule = Schedule(title: scheduleTitle,
																		description: description,
																		priority: priority,
																		time: scheduleDate,
																		alarm: alarm,
																		storeAt: .localDevice,
																		with: scheduleToEdit?.id,
																		location: selectedLocation,
																		contact: contact)
						let isSuccess: Bool
						if let scheduleToReplace = scheduleToEdit {
							isSuccess = scheduleController.replaceSchedule(scheduleToReplace, to: schedule, alarmCharacter: settingController.character)
						}else {
							isSuccess = scheduleController.addNewSchedule(schedule, alarmCharacter: settingController.character)
						}
						if !isSuccess {
							showAlarmAlertMessage()
						}else {
							presentationMode.wrappedValue.dismiss()
						}
					}
				} label: {
					Image(systemName: "checkmark")
						.foregroundColor(.blue)
				}
			}
			.padding()
			.background(Color(settingController.palette.tertiary.withAlphaComponent(0.3)))
		}
	}
	
	private func checkValidate() -> Bool {
		if let message = getValidateAlertMessage() {
			
			switch settingController.language {
			case .english:
				alertMessage = .init(
					title: scheduleToEdit == nil ? "Fail to create schedule": "Fail to edit schedule", message: message,
					action: {},
					label: {
						Text("Confirm")
							.font(.title3)
							.foregroundColor(.blue)
					})
			case .korean:
				alertMessage = .init(
					title: scheduleToEdit == nil ? "스케쥴 만들기 실패": "스케쥴 수정 실패",
					message: message,
					action: {},
					label: {
						Text("확인")
							.font(.title3)
							.foregroundColor(.blue)
					})
			}
			
			return false
		}else {
			return true
		}
	}
	
	private func getValidateAlertMessage() -> String? {
		if scheduleTitle.isEmpty {
			switch settingController.language {
			case .korean:
				return "스케쥴 제목을 입력해주세요"
			case .english:
				return "Please input title of schedule"
			}
		}
		else {
			return nil
		}
	}
	
	private func showAlarmAlertMessage() {
		withAnimation {
			switch settingController.language {
			case .english:
				alertMessage = CharacterAlert(
					title: "Fail to register alarm",
					message: "You need to authorize PixelScheduler for notification",
					primaryAction: settingController.openSystemSetting, primaryLabel: {
						Text("Go to setting")
							.foregroundColor(.blue)
					}, secondaryAction: {}, secondaryLabel: {
						Text("Cancel")
							.foregroundColor(.secondary)
					})
			case .korean:
				alertMessage = CharacterAlert(
					title: "알람 설정 실패",
					message: "픽셀 스케쥴러에게 알람을 설정할 권한이 없습니다",
					primaryAction: settingController.openSystemSetting, primaryLabel: {
						Text("설정으로")
							.foregroundColor(.blue)
					}, secondaryAction: {}, secondaryLabel: {
						Text("취소")
							.foregroundColor(.secondary)
					})
			}
		}
	}
	
	private func drawTitleInput(in size: CGSize) -> some View {
		VStack {
			HStack {
				drawCharacter(in: size)
					.frame(width: 80, height: 80)
					.zIndex(1)
				TextField(settingController.language == .korean ? "제목을 입력하세요": "Schedule Title", text: $scheduleTitle)
					.textFieldStyle(.roundedBorder)
					.frame(maxWidth: 200)
				Spacer()
					.frame(width: 50)
			}
			.zIndex(1)
			Divider()
		}
		.zIndex(1)
	}
	
	private func drawCharacter(in size: CGSize) -> some View {
		CharacterHelperView<Text, Text>(
			character: settingController.character,
			guide: .editSchedule,
			alertToPresent: $alertMessage ,
			helpWindowSize: CGSize(width: size.width * 0.8, height: size.height * 0.8),
			balloonStartPosition: CGPoint(x: 50, y: 100))
	}
	
	private var priorityPicker: some View {
		Group {
			Picker("Schedule Priority", selection: $priority) {
				ForEach(1..<6) { priority in
					Text(Color.PriorityButton.by(priority))
						.tag(priority)
				}
			}
			.pickerStyle(.segmented)
			.padding(.horizontal, 50)
			Divider()
		}
	}
	
	private var dateTypePicker: some View {
		Group {
			Picker("Schedule date type", selection: .init(get: {
				showingDateType
			}, set: { newValue in
				withAnimation {
					showingDateType = newValue
				}
			})) {
				ForEach(DateType.allCases) { type in
					Text(type.getDescription(for: settingController.language))
						.withCustomFont(size: .caption, for: settingController.language)
						.tag(type)
				}
			}
			.pickerStyle(.segmented)
			.padding(.horizontal, 40)
		}
	}
	
	@State private var previousDateType: DateType = .spot
	
	private var datePickerTransition: AnyTransition {
		let insertionDirection: Edge
		switch showingDateType {
		case .spot:
			insertionDirection = .leading
		case .period:
			insertionDirection = previousDateType == .spot ? .trailing: .leading
		case .weeklyCycle:
			insertionDirection = previousDateType == .monthlyCycle ? .leading: .trailing
		case .monthlyCycle:
			insertionDirection = .trailing
		}
		// Avoiding update state during updating view
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			previousDateType = showingDateType
		}
		return .asymmetric(insertion: .move(edge: insertionDirection), removal: .opacity)
	}
	
	private var datePicker: some View {
		Group {
			if showingDateType == .spot {
				spotDatePicker
					.transition(datePickerTransition)
			}
			else if showingDateType == .period {
				periodDatePicker
					.transition(datePickerTransition)
			}
			else {
				CyclePickerView(
					selected: cycleSelections,
					language: settingController.language,
					segmentType: showingDateType == .weeklyCycle ? .weekly: .monthly)
					.padding(.vertical, 20)
					.fixedSize(horizontal: false, vertical: true)
					.transition(datePickerTransition)
			}
			Divider()
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
	
	private var alarmPicker: some View {
		Group {
			HStack(spacing: 20) {
				Button {
					if alarm != nil {
						alarm = nil
					}else {
						switch scheduleDate {
						case .spot(let date), .period(let date, _):
							alarm = .once(date)
						case .cycle(let date, _, _):
							alarm = .periodic(date)
						}
					}
				} label: {
					let buttonColor: Color = alarm == nil ? .gray: .pink
					HStack {
						Image(systemName: "alarm")
							.resizable()
							.renderingMode(.template)
							.frame(width: 30, height: 30)
						Text(settingController.language == .korean ? "알람": "Alarm")
					}
					.foregroundColor(buttonColor)
					.padding(5)
					.overlay(RoundedRectangle(cornerRadius: 10)
										.stroke(buttonColor, lineWidth: 3)
					)
				}
				if alarm != nil {
					DatePicker(selection: .init(get: {
						if let alarmSet = alarm {
							switch alarmSet {
							case .periodic(let date):
								return date
							case .once(let date):
								return date
							}
						}else {
							return selectedDate ?? Date()
						}
					}, set: { newDate in
						switch scheduleDate {
						case .spot(_), .period(_, _):
							alarm = .once(newDate)
						case .cycle(_, _, _):
							alarm = .periodic(newDate)
						}
					}), displayedComponents: [.hourAndMinute], label: {})
						.datePickerStyle(.wheel)
						.frame(width: 200, height: 80)
						.fixedSize()
						.clipped()
				}else {
					Text(settingController.language == .korean ? "알람을 켜주세요": "Alarm is off")
						.font(.body)
						.foregroundColor(.gray)
				}
				Spacer()
			}
			.font(.title2)
			.padding(.leading, 30)
			Divider()
		}
	}
	
	private var contactPicker: some View {
		Group {
			HStack(spacing: 20) {
				Button {
					if contact == nil {
						isShowingContactPicker = true
					}else {
						withAnimation {
							contact = nil
						}
					}
				} label: {
					let buttonColor: Color = contact == nil ? .gray: .blue
					HStack {
						Image(systemName: "person.crop.circle")
							.resizable()
							.frame(width: 30, height: 30)
						Text(settingController.language == .korean ? "연락처": "Contact")
					}
					.foregroundColor(buttonColor)
					.padding(5)
					.overlay(RoundedRectangle(cornerRadius: 10)
										.stroke(buttonColor, lineWidth: 3)
					)
				}
				if let contact = contact {
					VStack {
						Text(contact.name)
						Text(contact.phoneNumber)
							.font(.caption)
					}
				}else {
					Text(settingController.language == .korean ? "연락처가 없습니다": "No contact")
						.font(.body)
						.foregroundColor(.gray)
				}
				Spacer()
			}
			.font(.title2)
			.padding(.leading, 30)
			Divider()
		}
	}
	
	private func drawLocationBar(scrollView: ScrollViewProxy) -> some View {
		Group {
			if isShowingLocationPicker {
				LocationPickerView(
					isPresenting: $isShowingLocationPicker,
					location: scheduleToEdit?.location,
					selectLocation: { location in
						self.selectedLocation = location
					})
					.frame(height: 350)
			}else {
				drawLocationLabel(scrollView: scrollView)
			}
			Divider()
				.id("LocationBarDivider")
		}
	}
	
	private func drawLocationLabel(scrollView: ScrollViewProxy) -> some View {
		HStack(spacing: 20) {
			Button {
				if selectedLocation == nil {
					withAnimation {
						isShowingLocationPicker = true
						scrollView.scrollTo("LocationBarDivider", anchor: nil)
					}
				}else {
					selectedLocation = nil
				}
			} label: {
				let buttonColor: Color = selectedLocation == nil ? .gray: .green
				HStack {
					Image(systemName: "location.fill")
						.resizable()
						.frame(width: 30, height: 30)
					Text(settingController.language == .korean ? "위치": "Location")
				}
				.foregroundColor(buttonColor)
				.padding(5)
				.overlay(RoundedRectangle(cornerRadius: 10)
									.stroke(buttonColor, lineWidth: 3)
				)
			}
			if let selectedLocation = selectedLocation {
				VStack {
					Text(selectedLocation.title)
						.font(.title)
						.foregroundColor(Color(settingController.palette.primary))
					Text(selectedLocation.address)
						.font(.caption)
						.foregroundColor(Color(settingController.palette.secondary))
				}
			}else {
				Text(settingController.language == .korean ? "위치가 없습니다": "No location is selected")
					.font(.body)
					.foregroundColor(.gray)
			}
			Spacer()
		}
		.padding(.leading, 30)
	}
	
	@available (iOS 15.0, *)
	@FocusState private var isTypingDescription: Bool
	
	private func drawDescriptionInput(scrollView: ScrollViewProxy) -> some View {
		let editor = TextEditor(text: $description)
			.foregroundColor(.primary)
			.frame(minHeight: 100)
			.background(
				RoundedRectangle(cornerRadius: 20)
					.stroke(Color.secondary)
			)
			.padding(.horizontal)
			.onAppear {
				UITextView.appearance().backgroundColor = .clear
			}
		return Group {
			if #available(iOS 15.0, *) {
				editor
					.focused($isTypingDescription)
					.onChange(of: isTypingDescription) {
						if $0 {
							DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
								withAnimation(.spring()) {
									scrollView.scrollTo("descriptionInputKeyboardArea", anchor: nil)
								}
							}
						}
					}
			} else {
				editor
			}
		}
	}
	
	private var navigationTitle: String {
		if scheduleToEdit != nil {
			return settingController.language == .korean ? "스케쥴 수정": "Edit Schedule"
		}else {
			return settingController.language == .korean ? "스케쥴 추가": "New Schedule"
		}
	}
}

struct EditScheduleView_Previews: PreviewProvider {
	static var previews: some View {
		EditScheduleView(selectedDate: Date())
			.environmentObject(ScheduleModelController())
			.environmentObject(SettingController())
	}
}
