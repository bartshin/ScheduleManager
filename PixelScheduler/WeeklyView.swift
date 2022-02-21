//
//  WeeklyView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/21.
//

import SwiftUI

struct WeeklyView: View {
	
	@EnvironmentObject var states: ViewStates
	@EnvironmentObject var scheduleController: ScheduleModelController
	@EnvironmentObject var settingController: SettingController
	@StateObject private var dailyViewData = DailyViewDataSource()
	@StateObject private var contactGather = ContactGather()
	@Binding var selectedDateInt: Int?
	@State private var currentWeeklyViewShowingDateInt: Int
	@State private var datesRepresentOneWeek: [Int]
	@State private var isShowingQuickHelp = false
	@State private var selectStickerSheetState = SheetView<SelectStickerView>.CardState.hide
	@State private var floatingSchedule: FloatingSchedule?
	private let hapticGenerator = UIImpactFeedbackGenerator()
	
	@State private var hoveringDate: (dateInt: Int, startAt: Date)?
	
	struct FloatingSchedule: Equatable, Identifiable {
		let id: Schedule.ID
		var position: CGPoint?
	}
	
	init(selectedDateInt: Binding<Int?>) {
		_selectedDateInt = selectedDateInt
		_currentWeeklyViewShowingDateInt = .init(initialValue: selectedDateInt.wrappedValue!)
		let middleDate = selectedDateInt.wrappedValue!.toDate!
		_datesRepresentOneWeek = .init(initialValue: (-5...5).reduce(into: [Int]()) { dates, index in
			dates.append(Calendar.current.date(byAdding: .day, value: 7*index, to: middleDate)!.toInt)
		})
	}
	
	private let topWeeklyViewHeight = CGFloat(150)
	
	var body: some View {
		GeometryReader { geometry in
			ZStack {
				VStack(spacing: 0) {
					drawTopWeeklyView(in: geometry.size)
					ZStack {
						VStack {
							if let dateInt = selectedDateInt,
								 let holiday = scheduleController.holidayTable[dateInt] {
								drawHolidayLabel(holiday, in: geometry.size)
							}
							if let dateInt = selectedDateInt,
								 let sticker = scheduleController.stickerTable[dateInt] {
								drawSticker(sticker, in: geometry.size)
							}
						}
						dailyView
						if floatingSchedule != nil {
							drawFloatingSchedule(in: geometry.size)
						}
					}
				}
			}
			drawCharacterView(in: geometry.size)
			drawAddScheduleButton(in: geometry.size)
			drawStickerButton(in: geometry.size)
			if selectStickerSheetState != .hide {
				showBackgroundBlur {
					selectStickerSheetState = .hide
				}
			}
			stickerPickerSheet
		}
		.sheet(isPresented: $states.isShowingNewScheduleSheet, onDismiss: nil) {
			EditScheduleView(selectedDate: selectedDateInt!.toDate!)
		}
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .principal) {
				HStack {
					quickHelpCharacter
					navigationBarTitle
					Spacer()
				}
				.offset(x: -10)
			}
		}
	}
	
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
	
	private func drawTopWeeklyView(in size: CGSize) -> some View {
	
		return HStack {
			TabView(selection: $currentWeeklyViewShowingDateInt) {
				ForEach(datesRepresentOneWeek, id: \.self) { dateInt in
					drawCellsForAWeek(contain: dateInt)
				}
			}
			.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
			.onChange(of: currentWeeklyViewShowingDateInt, perform: updateDatesForWeeks(baseOn:))
		}
		.frame(width: size.width,
					 height: topWeeklyViewHeight)
		.onChange(of: floatingSchedule) {
			if let id = $0?.id,
				 $0!.position == nil{
				moveScheduleIfNeeded(id: id)
			}
			handleHovering(by: $0?.position, in: size)
		}
	}
	
	private func handleHovering(by position: CGPoint?, in size: CGSize) {
		guard let position = position,
					position.y < topWeeklyViewHeight * 1.1 else {
						withAnimation {
							hoveringDate = nil
						}
						return
					}
		
		let widthForOneDay = size.width / 7
		let hoveringWeekDay = min(7, max(1, Int((position.x + widthForOneDay) / widthForOneDay)))
		let currentHoverdateInt = Calendar.current.date(byAdding: .day, value: hoveringWeekDay - (currentWeeklyViewShowingDateInt.toDate?.weekDay ?? 3), to: currentWeeklyViewShowingDateInt.toDate!)!.toInt
		guard position.x > size.width * 0.1,
					position.x < size.width * 0.9
	 else {
		 scrollWeeklViewIfNeeded(toForward: position.x > size.width/2)
		 return
	 }
		DispatchQueue.main.async {
			hoveringDate = (dateInt: currentHoverdateInt, startAt: self.hoveringDate?.dateInt == currentHoverdateInt ? self.hoveringDate!.startAt : Date())
		}
	}
	
	private func scrollWeeklViewIfNeeded(toForward: Bool) {
		guard let hoverStart = hoveringDate?.startAt,
					hoverStart.timeIntervalSinceNow < -0.5 else {
						return
					}
		let newHoveringDateInt = Calendar.current.date(byAdding: .day, value: toForward ? 7: -7, to: hoveringDate!.dateInt.toDate!)!.toInt
		let newWeeklyViewDateInt = Calendar.current.date(byAdding: .day, value: toForward ? 7: -7, to: currentWeeklyViewShowingDateInt.toDate!)!.toInt
		withAnimation {
			currentWeeklyViewShowingDateInt = newWeeklyViewDateInt
			hoveringDate = (dateInt: newHoveringDateInt, startAt: Date() + 0.5)
		}
		
	}
	
	private func moveScheduleIfNeeded(id: Schedule.ID) {
		defer {
			floatingSchedule = nil
		}
		guard let dateInt = hoveringDate?.dateInt,
					let hoveredTime = hoveringDate?.startAt.timeIntervalSinceNow,
					hoveredTime < -0.1,
					let scheduleToMove = scheduleController.getSchedule(by: id),
		scheduleToMove.time.isMovable else {
						return
					}
		let newScheduleTime = scheduleToMove.time.setDate(dateInt: dateInt)
		let newSchedule = scheduleToMove.modify(time: newScheduleTime)
		hapticGenerator.generateFeedback(for: settingController.hapticMode)
		let isSuccess = scheduleController.replaceSchedule(scheduleToMove, to: newSchedule, alarmCharacter: settingController.character)
		if isSuccess {
			SoundEffect.playSound(.post)
			withAnimation {
				selectedDateInt = dateInt
			}
		}else {
			showFailToMoveAlert()
		}
	}
	
	private func showFailToMoveAlert() {
		let title: String
		let message: String
		let cancel: String
		switch settingController.language {
		case .english:
			title = "Fail to move schedule"
			message = "Use edit mode instead"
			cancel = "OK"
		case .korean:
			title = "스케쥴 이동 실패"
			message = "스케쥴 수정기능을 이용해주세요"
			cancel = "확인"
		}
		states.alert = .init(title: title, message: message, action: {}) {
			Text(cancel)
		}
	}
	@State private var dateForUpdateBorder = Date()
	
	private func drawCellsForAWeek(contain dateInt: Int) -> some View {
		HStack (spacing: 0) {
			ForEach(getDatesForWeek(contain: dateInt), id: \.self) { date in
				WeeklyCellView(date: date,
											 holiday: scheduleController.holidayTable[date.toInt],
											 colorPalette: settingController.palette,
											 isSelected: date.toInt == selectedDateInt,
											 schedules: scheduleController.getSchedules(for: date.toInt),
											 labelLanguage: settingController.language)
					.border(
						date.toInt == hoveringDate?.dateInt ? Color(settingController.palette.primary.withAlphaComponent(getBorderOpacity())): Color.clear,
						width: 5
					)
					.onTapGesture {
						states.presentingScheduleId = nil
						withAnimation {
							selectedDateInt = date.toInt
						}
					}
			}
		}
	}
	
	private func getBorderOpacity() -> CGFloat {
		guard let hoverStart = hoveringDate?.startAt else {
			return 0
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			withAnimation {
				dateForUpdateBorder = Date()
			}
		}
		return max( 0.5, 1 - CGFloat(dateForUpdateBorder.timeIntervalSince(hoverStart)))
	}
	
	private func updateDatesForWeeks(baseOn dateInt: Int) {
		if dateInt == datesRepresentOneWeek.first ||
				dateInt == datesRepresentOneWeek.last {
			datesRepresentOneWeek = (-5...5).reduce(into: [Int]()) { dates, index in
				dates.append(Calendar.current.date(byAdding: .day, value: 7*index, to: dateInt.toDate!)!.toInt)
			}
		}
	}
	
	private func drawFloatingSchedule(in size: CGSize) -> some View {
		let size = CGSize(width: size.width * 0.5, height: size.height * 0.3)
		let schedulePostion = floatingSchedule?.position
		return Group {
			if let scheduleId = floatingSchedule?.id,
				 let schedule = scheduleController.getSchedule(by: scheduleId),
				 let date = selectedDateInt?.toDate,
			schedulePostion != nil{
				DailyTableScheduleBackground(
					for: schedule,
						 width: size.width,
						 height: max(size.height, 80.0),
						 date: date)
				// MARK: Schedule Content
				DailyScheduleContentsView(
					for: schedule,
						 with: settingController.palette,
						 watch: dailyViewData)
					.frame(width: size.width,
								 height: max(size.height, 80.0))
			}
		}
		.position(x: floatingSchedule?.position?.x ?? 0,
							y: floatingSchedule?.position?.y ?? 0)
		.offset(y: -topWeeklyViewHeight)
	}
	
	private func drawCharacterView(in size: CGSize) -> some View {
		CharacterHelperView(
			character: settingController.character,
			guide: .weeklyCalendar,
			showingQuickHelp: $isShowingQuickHelp,
			alertToPresent: $states.alert,
			helpWindowSize: CGSize(
				width: size.width * 0.7,
				height: size.height * 0.7),
			balloonStartPosition: CGPoint(
				x: size.width * 0.2,
				y: size.height * 0.1))
			.position(x: size.width * 0.1, y: size.height * -0.05)
	}
	
	private func drawHolidayLabel(_ holiday: HolidayGather.Holiday, in size: CGSize) -> some View {
		ZStack {
			RoundedRectangle(cornerRadius: 20)
				.fill(Color(settingController.palette.quaternary.withAlphaComponent(0.5)))
				.frame(width: size.width * 0.4, height: size.height * 0.3)
				.padding()
				.overlay (
					Image("bulletin_board")
						.resizable()
						.frame(width: size.width * 0.45, height: size.height * 0.35)
				)
			Text(holiday.translateTitle(to: settingController.language))
				.withCustomFont(size: .title, for: settingController.language)
		}
		.opacity(0.3)
		.padding(.leading, size.width * 0.1)
	}
	
	private func drawSticker(_ sticker: Sticker, in size: CGSize) -> some View {
		Image(uiImage: sticker.image)
			.resizable()
			.aspectRatio(1, contentMode: .fit)
			.frame(width: size.width * 0.5)
			.opacity(0.8)
	}
	
	private var dailyView: some View {
		DailyScrollView(data: dailyViewData,
										date: selectedDateInt?.toDate,
										presentingScheduleId: $states.presentingScheduleId,
										floatingSchedule: $floatingSchedule,
										alert: $states.alert)
			.onChange(of: selectedDateInt) {
				guard let newDate = $0?.toDate else {
					return
				}
				updateDailyViewData(date: newDate)
				floatingSchedule = nil
			}
			.onAppear {
				guard let date = selectedDateInt?.toDate else {
					assertionFailure()
					return
				}
				updateDailyViewData(date: date)
			}
			.onReceive(scheduleController.objectWillChange) { _ in
				if let presentingScheduleId = states.presentingScheduleId,
					 scheduleController.getSchedule(by: presentingScheduleId) == nil{
					states.presentingScheduleId = nil
				}
				updateDailyViewData(date: selectedDateInt?.toDate ?? Date())
				floatingSchedule = nil
			}
	}
	
	private func updateDailyViewData(date: Date) {
		let schedules = scheduleController.getSchedules(for: date.toInt)
		DispatchQueue.main.async {
			dailyViewData.setNewSchedule(schedules, of: date)
		}
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
	
	private func drawAddScheduleButton(in size: CGSize) -> some View {
		Button {
			states.isShowingNewScheduleSheet = true
		} label: {
			Image("add_schedule_orange")
				.resizable()
				.frame(width: 50, height: 50)
		}
		.position(x: size.width * 0.9, y: size.height * 0.9)
	}
	
	private func drawStickerButton(in size: CGSize) -> some View {
		Button {
			withAnimation {
				selectStickerSheetState = .middle
			}
		} label: {
			Image("sticker_icon")
				.resizable()
				.frame(width: 50, height: 50)
		}
		.position(x: size.width * 0.1, y: size.height * 0.9)
	}
	
	private var stickerPickerSheet: some View {
		SheetView(cardState: $selectStickerSheetState, handleColor: nil, backgroundColor: nil, cardStatesAvailable: [.hide, .middle])  {
			SelectStickerView(stickerSet: scheduleController.stickerTable[selectedDateInt!]) { sticker in
				scheduleController.setSticker(sticker, to: selectedDateInt!)
			} dismiss: {
				selectStickerSheetState = .hide
			}

		}
	}
	
	private var quickHelpCharacter: some View {
		GIFImage(name: settingController.character.idleGif)
			.onTapGesture {
				isShowingQuickHelp.toggle()
			}
			.frame(width: 80, height: 80)
	}
	
	private var navigationBarTitle: some View {
		Text(navigationBarTitleString)
			.withCustomFont(size: .subheadline, for: settingController.language)
	}
	
	private var navigationBarTitleString: String {
		let weekDay = currentWeeklyViewShowingDateInt.toDate!.weekDay
		let startDate = Calendar.current.date(byAdding: .day, value: -(weekDay - 1), to: currentWeeklyViewShowingDateInt.toDate!)!
		let endDate = Calendar.current.date(byAdding: .day, value: (7 - weekDay), to: currentWeeklyViewShowingDateInt.toDate!)!
		switch settingController.language {
		case .korean:
			return "\(startDate.getMonthDayString(with: settingController.language.locale)) ~ \(endDate.getMonthDayString(with: settingController.language.locale))의 스케쥴"
		case .english:
			return "Schedules from \(startDate.getMonthDayString(with: settingController.language.locale)) to \(endDate.getMonthDayString(with: settingController.language.locale))"
		}
	}
}

#if DEBUG
struct WeeklyView_Previews: PreviewProvider {
	
	static var previews: some View {
		WeeklyView(selectedDateInt: .constant(Date().toInt))
			.environmentObject(ScheduleModelController.dummyController)
			.environmentObject(SettingController())
			.environmentObject(ViewStates())
	}
}
#endif
