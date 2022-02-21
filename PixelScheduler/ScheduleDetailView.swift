//
//  ScheduleDetailView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/01/08.
//

import SwiftUI
import ContactsUI

struct ScheduleDetailView: View {
	
	@EnvironmentObject var states: ViewStates
	@EnvironmentObject var scheduleController: ScheduleModelController
	@EnvironmentObject var settingController: SettingController
	private let hapticGenerator = UIImpactFeedbackGenerator()
	let scheduleId: Schedule.ID
	private var schedule: Schedule {
		scheduleController.getSchedule(by: scheduleId)!
	}
	@Binding var isPresenting: Bool
	var showingDateInt: Int {
		states.scheduleViewDate.toInt
	}
	@State private var presentingContact: CNContact?
	@State private var isEditing = false
	private var isDone: Bool {
		schedule.isDone(for: showingDateInt)
	}
	@State private var dateDragging: (control: DateDragPostion, offset: CGFloat)? = nil
	
	private enum DateDragPostion {
		case spot
		case start
		case end
	}
	
	init(schedule: Schedule,
			 isPresenting: Binding<Bool>) {
		self.scheduleId = schedule.id
		_isPresenting = isPresenting
	}
	
	var body: some View {
		if isPresenting {
			ScrollView(showsIndicators: false) {
				VStack (alignment: .leading, spacing: 20) {
					titleLabel
					dateLabel
					progressLabel
					alarmLabel
					contactLabel
					locationLabel
					descriptionBox
					deleteButton
				}
				.padding(20)
				.background(
					roundedBackground
				)
				.overlay(
					GeometryReader { geometry in
						if isDone {
							drawCompletedSchedule(in: geometry.size)
						}
					}
				)
			}
			.sheet(isPresented: $isEditing, onDismiss: nil) {
				EditScheduleView(scheduleToEdit: schedule,
												 selectedDate: showingDateInt.toDate)
			}
			.sheet(item: $presentingContact, onDismiss: {}, content: presentContactSheet(for:))
			.onChange(of: schedule.isDone(for: showingDateInt)) { isDone in
				if isDone {
					hapticGenerator.generateFeedback(for: settingController.hapticMode)
				}
			}
		}
	}
	
	private var titleLabel: some View {
		HStack(spacing: 5) {
			priorityPicker
				.opacity(0.1)
				.background(
					priorityLabel
				)
				.frame(width: 30)
			Text(schedule.title)
				.fontWeight(.bold)
				.withCustomFont(size: .title3, for: settingController.language)
				.layoutPriority(1)
			Spacer()
			editButton
		}
		
	}
	
	private var priorityLabel: some View {
		Image(systemName: "star.circle.fill")
			.renderingMode(.template)
			.foregroundColor(Color.byPriority(schedule.priority))
	}
	
	private var priorityPicker: some View {
		Picker("Priority", selection: .init(get: {
			schedule.priority
		}, set: {
			changePriority(to: $0)
		})) {
			ForEach(1..<6) { priority in
				Text(String(priority))
					.foregroundColor(Color.byPriority(priority))
					.tag(priority)
			}
		}
		.pickerStyle(.menu)
		.labelsHidden()
	}
	
	private func changePriority(to newValue: Int) {
		let newSchedule = schedule.modify(priority: newValue)
		let isSuccess = scheduleController.replaceSchedule(schedule, to: newSchedule, alarmCharacter: settingController.character)
		if !isSuccess {
			showFailToChangeAlert()
		}
	}
	
	private func showFailToChangeAlert() {
		let title: String
		let message: String
		let cancel: String
		switch settingController.language {
		case .english:
			title = "Fail to change"
			message = "Use Edit mode instead"
			cancel = "OK"
		case .korean:
			title = "변경 실패"
			message = "수정 모드를 이용해주세요"
			cancel = "확인"
		}
		states.alert = .init(title: title, message: message, action: {}) {
			Text(cancel)
		}
	}
	
	
	private var editButton: some View {
		let text: String
		
		switch settingController.language {
		case .korean:
			text = "수정하기"
		case .english:
			text = "Edit"
		}
		
		return Button {
			isEditing = true
		} label: {
			Text(text)
				.withCustomFont(size: .caption, for: settingController.language)
		}
	}
	
	private var dateLabel: some View {
		Group {
			switch schedule.time {
			case .spot(let date):
				drawSpotDateLabel(for: date)
			case .period(let startDate, let endDate):
				drawPeriodDateLabel(from: startDate, to: endDate)
			case .cycle(let date, _, _):
				drawSpotDateLabel(for: date)
			}
		}
		.clipShape(RoundedRectangle(cornerRadius: 20))
		.background(
			RoundedRectangle(cornerRadius: 20)
				.fill(Color(settingController.palette.quaternary))
		)
		.frame(minHeight: 70, maxHeight: 100)
	}
	
	private func drawSpotDateLabel(for date: Date) -> some View {
		GeometryReader { geometry in
			
			let widthForOneMinute = geometry.size.width / (60 * CGFloat(4))
			ZStack {
			
				drawTimebar(date: date, in: geometry.size)
				.zIndex(1)
				.disabled(schedule.isDone(for: showingDateInt))
				drawSharpHours(around: date,
											 in: geometry.size)
					.offset(x: -CGFloat(date.minute ) * widthForOneMinute)
			}
		}
	}
	
	private func drawTimebar(date: Date, in size: CGSize) -> some View {
		let dragOffset: CGFloat? = dateDragging?.control == .spot ? dateDragging!.offset: nil
		let color: Color = dragOffset != nil ? .blue: .gray
		let showingDate = calcMovedDate(from: date, hours: 4, in: size.width)
		return VStack(spacing: 0) {
			Text(showingDate.trimTimeString())
				.fontWeight(.bold)
				.padding(3)
				.background(
					RoundedRectangle(cornerRadius: 10)
						.fill(color)
				)
			RoundedRectangle(cornerRadius: 10, style: .circular)
				.fill(color)
				.frame(width: 10, height: size.height * 0.7)
				.overlay(
					Group {
						if dragOffset == nil {
							HStack {
								Image(systemName: "chevron.left")
								Image(systemName: "chevron.right")
							}
						}
					}
				)
		}
		.position(x: size.width/2 + (dragOffset ?? 0), y: size.height * 0.5)
		.gesture(
			DragGesture(minimumDistance: 0)
				.onChanged { gestureValue in
					dateDragging = (control: .spot, offset: gestureValue.translation.width)
					
				}
				.onEnded { gestureValue in
					let newDate = calcMovedDate(from: date, hours: 4, in: size.width)
					dateDragging = nil
					
					let newSchedule = schedule.modify(time: .spot(newDate))
					let isSuccess = scheduleController.replaceSchedule(schedule, to: newSchedule, alarmCharacter: settingController.character)
					if !isSuccess {
						showFailToChangeAlert()
					}
				}
		)
	}
	
	private func calcMovedDate(from date: Date, hours: Int, in width: CGFloat) -> Date {
		let widthForOneMinute = width / (60 * CGFloat(hours))
		let offsetMinute: CGFloat? = dateDragging?.offset != nil ? dateDragging!.offset * 60 / widthForOneMinute : nil
		return date + (offsetMinute ?? 0)
	}
	
	private func drawSharpHours(around date: Date, in size: CGSize) -> some View {
		let leftMostHour = Calendar.current.date(byAdding: .hour, value: -2, to: date)!
		let rightMostHour = Calendar.current.date(byAdding: .hour, value: 6, to: date)!
		return drawSharpHours(from: leftMostHour, to: rightMostHour, in: CGSize(width: size.width * 2, height: size.height))
	}
	
	private func drawSharpHours(from start: Date, to end: Date, in size: CGSize) -> some View {
		
		let startHour = start.hour
		let gap = Int(((end - start) / (60 * 60)).rounded())
		let endHour = startHour + gap
		let horizontalCenter = size.width/2
		let widthForOneMinute = size.width / (60 * CGFloat(endHour + 1 - startHour))
		return Group {
			if gap < 24 {
				ForEach(startHour..<endHour + 1) { hour in
					VStack {
						if gap < 10 {
							Text(getMeridiemString(for: hour) + "\(hour%12):00")
								.font(.caption2)
								.background(
									RoundedRectangle(cornerRadius: 10)
										.fill(Color(.systemBackground))
								)
						}
						Rectangle()
							.fill(.gray)
							.frame(width: 2, height: size.height * 0.6)
					}
					.position(x: horizontalCenter + CGFloat(hour - (startHour + endHour)/2) * widthForOneMinute * 60.0, y: size.height * 0.5)
				}
			}
		}
	}
	
	private func drawPeriodDateLabel(from startDate: Date, to endDate: Date) -> some View {
		GeometryReader { geometry in
			let hoursBetween = (endDate - startDate) / (60 * 60)
			let centralDate = startDate.addingTimeInterval((endDate - startDate)/2)
			let widthForOneMinute = geometry.size.width / (60 * (hoursBetween+2))
			ZStack {
				drawSharpHours(from: Calendar.current.date(byAdding: .hour, value: -1, to: startDate)!, to: Calendar.current.date(byAdding: .hour, value: 1, to: endDate)!, in: geometry.size)
				ZStack {
					RoundedRectangle(cornerRadius: 10)
						.fill(Color(settingController.palette.primary.withAlphaComponent(0.8)))
						.frame(width: hoursBetween * geometry.size.width / (hoursBetween + 2), height: geometry.size.height * 0.5)
					VStack {
						Text(startDate.trimTimeString() + " ~ " + endDate.trimTimeString())
							.font(.headline)
							.fontWeight(.bold)
						Text((endDate - startDate).getString(for: settingController.language))
							.font(.subheadline)
					}
					.foregroundColor(.white)
				}
				.position(x: geometry.size.width/2 + CGFloat(centralDate.minute) * widthForOneMinute, y: geometry.size.height * 0.6)
			}
			.offset(x: -CGFloat(centralDate.minute) * widthForOneMinute)
		}
	}
	
	
	
	private var progressLabel: some View {
		HStack {
			completeButton
			Group {
				switch settingController.language {
				case .english:
					Text(isDone ? "Schedule is completed": "Not completed yet")
				case .korean:
					Text(isDone ? "스케쥴 완료됨": "완료되지 않음")
				}
			}
			.foregroundColor(isDone ? Color(settingController.palette.secondary): Color(settingController.palette.primary))
		}
	}
	
	private var completeButton: some View {
		Button {
			var newSchedule = schedule
			newSchedule.toggleIsDone(for: showingDateInt)
			if newSchedule.isDone(for: showingDateInt) { SoundEffect.playSound(.coinBonus)
			}
			let isSuccess = scheduleController.replaceSchedule(schedule, to: newSchedule, alarmCharacter: settingController.character)
			if !isSuccess {
				states.alert = failToggleCompleteAlert
			}
		} label: {
			HStack {
				Image(systemName: isDone ? "checkmark.seal.fill": "checkmark.seal")
					.foregroundColor(isDone ? Color(settingController.palette.secondary): .green)
				if isDone {
					Group {
						switch settingController.language {
						case .english:
							Text("Undo")
						case .korean:
							Text("완료 취소")
						}
					}
					.foregroundColor(.red)
				}else {
					Group {
						switch settingController.language {
						case .english:
							Text("Complete")
						case .korean:
							Text("완료하기")
						}
					}
					.foregroundColor(.green)
				}
			}
			.padding(5)
			.background(
				RoundedRectangle(cornerRadius: 20)
					.stroke(isDone ? Color(settingController.palette.secondary): .green, lineWidth: 2)
			)
		}
	}
	
	private var failToggleCompleteAlert: CharacterAlert<Text, Text> {
		let title: String
		let message: String
		let cancel: String
		switch settingController.language {
		case .english:
			title = "Fail to toggle complete"
			message = "Please make new schedule"
			cancel = "Close"
		case .korean:
			title = " 완료 변경 실패"
			message = "스케쥴을 새로 생성해 주세요"
			cancel = "닫기"
		}
		return CharacterAlert(title: title,
													message: message,
													action: {},
													label: {
			Text(cancel)
		})
	}
	
	private var alarmLabel: some View {
		HStack {
			alarmOnOffButton
				.disabled(schedule.alarm == nil)
			if let alarm = schedule.alarm {
				HStack(spacing: 10) {
					Text(getMeridiemString(for: alarm.date.hour) + " " + alarm.date.trimTimeString())
						.withCustomFont(size: .subheadline, for: settingController.language)
				}
			}else {
				emptyAlarmLabel
			}
		}
	}
	
	private func getMeridiemString(for hour: Int) -> String {
		switch settingController.language {
		case .english:
			return hour >= 12 ? "PM": "AM"
		case .korean:
			return hour >= 12 ? "오후": "오전"
		}
	}
	
	private var alarmOnOffButton: some View {
		Button {
			var newSchedule = schedule
			newSchedule.isAlarmOn = !schedule.isAlarmOn
			let isSucess = scheduleController.replaceSchedule(schedule, to: newSchedule, alarmCharacter: settingController.character)
			if !isSucess {
				states.alert = failToggleAlarmAlert
			}
		} label: {
			HStack {
				Image(systemName: "alarm.fill")
				switch settingController.language {
				case .english:
					Text("Alarm")
				case .korean:
					Text("알람")
				}
			}
			.font(.title3)
			.padding(5)
			.foregroundColor(Color(schedule.isAlarmOn ? .orange: settingController.palette.secondary))
			.background(
				RoundedRectangle(cornerRadius: 20)
					.stroke(Color(schedule.isAlarmOn ? .orange: settingController.palette.secondary), lineWidth: 2)
			)
		}
	}
	
	private var failToggleAlarmAlert: CharacterAlert<Text, Text> {
		let title: String
		let message: String
		let openSettings: String
		let cancel: String
		switch settingController.language {
		case .english:
			title = "Fail to toggle alarm"
			message = "Please enable notification in settings"
			openSettings = "Open settings"
			cancel = "Cancel"
		case .korean:
			title = "알람 설정 실패"
			message = "설정에서 알람 권한을 허용해 주세요"
			openSettings = "설정열기"
			cancel = "취소"
		}
		
		return CharacterAlert(title: title,
													message: message,
													primaryAction: settingController.openSystemSetting, primaryLabel: { Text(openSettings) },
													secondaryAction: {},
													secondaryLabel: { Text(cancel) })
	}
	
	private var emptyAlarmLabel: some View {
		Group {
			switch settingController.language {
			case .korean:
				Text("알림이 없습니다")
					.baselineOffset(5)
			case .english:
				Text("No alarm is set")
			}
		}
		.foregroundColor(Color(settingController.palette.secondary))
	}
	
	private var locationLabel: some View {
		 HStack (spacing: 10) {
			locationButton
				 .disabled(schedule.location == nil)
			if let location = schedule.location {
				VStack (alignment: .leading) {
					Text(location.title)
						.font(.headline)
					Text(location.address)
						.font(.body)
				}
			}else {
				Group {
					switch settingController.language {
					case .english:
						Text("No location is set")
					case .korean:
						Text("위치가 없습니다")
					}
				}
				.foregroundColor(Color(settingController.palette.secondary))
			}
		}
	}
	
	private var locationButton: some View {
		Button {
			guard let location = schedule.location else {
				return
			}
			showOpenMapAlert(to: location)
		} label: {
			let color = Color(schedule.location != nil ? .systemGreen: settingController.palette.secondary)
			HStack {
				Image(systemName: schedule.location != nil ? "location.fill": "location")
				switch settingController.language {
				case .english:
					Text("Location")
				case .korean:
					Text("위치")
				}
			}
			.foregroundColor(color)
			.font(.title3)
			.padding(5)
			.background(
				RoundedRectangle(cornerRadius: 20)
					.stroke(color, lineWidth: 2)
			)
		}
	}
	
	private func showOpenMapAlert(to location: Schedule.Location) {
		let title: String
		let message: String
		let openMap: String
		let cancel: String
		
		switch settingController.language {
		case .english:
			title = "Open Apple map"
			message = "Find route to \(location.title)"
			openMap = "Open"
			cancel = "Cancel"
		case .korean:
			title = "애플 맵으로 이동"
			message = "\(location.title)의 위치를 보기 위해 애플 지도를 이용합니다"
			openMap = "열기"
			cancel = "취소"
		}
		states.alert = .init(title: title,
									message: message,
									primaryAction: {LocationManager.showLocationInAppleMap(for: schedule)},
									primaryLabel: {
			Text(openMap)
		}, secondaryAction: {}, secondaryLabel: {
			Text(cancel)
		})
	}

	private var contactLabel: some View {
		HStack {
			contactButton
				.disabled(schedule.contact == nil)
			if let contact = schedule.contact{
				VStack(alignment: .leading) {
					Text(contact.name)
						.font(.headline)
					Text(contact.phoneNumber)
						.font(.body)
				}
			}else {
				emptyContactLabel
			}
		}
	}
	
	private var emptyContactLabel: some View {
		Group {
			switch settingController.language {
			case .english:
				Text("No contact")
			case .korean:
				Text("연락처가 없습니다")
			}
		}
		.foregroundColor(Color(settingController.palette.secondary))
	}
	
	private var contactButton: some View {
		let color = Color(schedule.contact != nil ? UIColor(red: 0, green: 178/255, blue: 255, alpha: 1): settingController.palette.secondary)
		
		return Button {
			guard let contact = schedule.contact else {
				return
			}
			presentContactView(for: contact)
		} label: {
			HStack {
				HStack {
					Image(systemName: schedule.contact != nil ? "phone.fill": "phone")
					switch settingController.language{
					case .english:
						Text("Contact")
					case .korean:
						Text("연락처")
					}
				}
				.font(.title3)
				.padding(5)
				.background(
					RoundedRectangle(cornerRadius: 20)
						.stroke(color, lineWidth: 2)
				)
				.foregroundColor(color)
			}
		}
	}
	
	private func presentContactSheet(for contact: CNContact) -> some View {
		GeometryReader { geometry in
			ZStack {
				ContactVCRepresentation(contact: contact)
				Button {
					presentingContact = nil
				} label: {
					ZStack {
						Spacer()
						Image(systemName: "chevron.down")
							.resizable()
							.frame(width: 30, height: 20)
					}
					.frame(width: 50, height: 50)
				}
				.position(x: geometry.size.width * 0.05, y: 30)
			}
		}
	}
	
	private func presentContactView(for contact: Schedule.Contact) {
		let contactGather = ContactGather()
		
		contactGather.requestPermission {
			do {
				let results = try contactGather.getContacts(by: [contact.contactID], forImage: false)
				if let firstContact = results.first {
					presentingContact = firstContact
				}else {
					showContactErrorAlert(for: .notFound)
				}
			}catch {
				assertionFailure("Fail to fetch contact \n" + error.localizedDescription)
				showContactErrorAlert(for: .internalError)
			}
		} deniedHandler: {
			showContactErrorAlert(for: .unAuthorized)
		}
	}
	
	private func showContactErrorAlert(for error: ContactGather.Error) {
		if case .unAuthorized = error {
			let title: String
			let message: String
			let openSetting: String
			let cancel: String
			switch settingController.language {
			case .english:
				title = "Fail to open contact"
				message = "Please authorize PixelScheduler for contact in settings"
				openSetting = "Open settings"
				cancel = "Cancel"
			case .korean:
				title = "연락처를 가져오기 실패"
				message = "설정에서 연락처에 대한 권한을 허용해 주세요"
				openSetting = "설정 열기"
				cancel = "취소"
			}
			states.alert = .init(title: title,
										message: message,
										primaryAction: {
				settingController.openSystemSetting()
			},
										primaryLabel: { Text(openSetting) },
										secondaryAction: {},
										secondaryLabel: { Text(cancel) })
		}
	}
	
	private var descriptionBox: some View {
		Group {
			if !schedule.description.isEmpty {
				ScrollView {
					VStack(spacing: 10) {
						HStack {
							Image(systemName: "square.and.pencil")
							Group {
								switch settingController.language {
								case .english:
									Text("Memo")
										.underline()
										.withCustomFont(size: .subheadline, for: settingController.language)
								case .korean:
									Text("메모")
										.underline()
										.withCustomFont(size: .subheadline, for: settingController.language)
								}
							}
						}
						Text(schedule.description)
							.font(.headline)
							.lineLimit(nil)
							.padding(.horizontal, 10)
					}
				}
				.frame(height: schedule.description.count > 50 ? 300: 200)
				.background(
					RoundedRectangle(cornerRadius: 20)
						.fill(Color(settingController.palette.quaternary))
				)
			}
		}
	}
	
	private var deleteButton: some View {
		Button (action: showDeleteAlert) {
			HStack {
				Image(systemName: "trash")
				switch settingController.language{
				case .english:
					Text("Delete")
				case .korean:
					Text("지우기")
				}
			}
			.font(.title3)
			.padding(5)
			.background(
				RoundedRectangle(cornerRadius: 20)
					.stroke(.red, lineWidth: 2)
			)
			.foregroundColor(.red)
		}
	}

	private func showDeleteAlert() {
		let title: String
		let message: String
		let delete: String
		let cancel: String
		switch settingController.language {
		case .korean:
			title = "지우기"
			message = "스케쥴을 삭제합니다"
			delete = "삭제"
			cancel = "취소"
		case .english:
			title = "Delete"
			message = "Remove this schedule?"
			delete = "Delete"
			cancel = "Cancel"
		}
		states.alert = .init(title: title,
									message: message,
									primaryAction: {
			DispatchQueue.main.async {
				withAnimation {
					isPresenting = false
				}
				scheduleController.deleteSchedule(schedule)
			}
		}, primaryLabel: {
			Text(delete)
				.foregroundColor(.red)
		}, secondaryAction: {}, secondaryLabel: {
			Text(cancel)
				.foregroundColor(.gray)
		})
	}
	
	private func drawCompletedSchedule(in size: CGSize) -> some View {
		ZStack {
			showBackgroundBlur()
				.cornerRadius(20)
				.opacity(0.8)
			VStack {
				drawCompletedSeal(for: size)
				completeButton
					.background(
						RoundedRectangle(cornerRadius: 20)
							.fill( Color(settingController.palette.quaternary))
					)
			}
		}
	}
	
	private func drawCompletedSeal(for size: CGSize) -> some View {
		let minLength = min(size.width, size.height)
		return Image("completed_stamp\(Int.random(in: 1...4))")
				.resizable()
				.aspectRatio(1, contentMode: .fit)
				.padding()
				.frame(width: minLength, height: minLength)
				.opacity(0.5)
	}
	
	private var roundedBackground: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 30)
				.fill(Color(settingController.palette.quaternary.withAlphaComponent(0.9)))
				.padding(3)
			RoundedRectangle(cornerRadius: 50)
				.stroke(schedule.isDone(for: showingDateInt) ? .gray: Color.byPriority(schedule.priority), lineWidth: 5)
		}
	}
}

#if DEBUG
struct ScheduleDetailView_Previews: PreviewProvider {
	
	static var previews: some View {
		ScheduleDetailView(schedule: Schedule.dummy,
											 isPresenting: .constant(true))
			.previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/300.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/500.0/*@END_MENU_TOKEN@*/))
			.environmentObject(ScheduleModelController.dummyController)
			.environmentObject(SettingController())
			.environmentObject(ViewStates())
			.environment(\.sizeCategory, .medium)
	}
}
#endif
