//
//  CalendarView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/05.
//

import SwiftUI

struct CalendarView: View {
	
	@EnvironmentObject var states: ViewStates
	@EnvironmentObject var scheduleController: ScheduleModelController
	@EnvironmentObject var settingController: SettingController

	@State private var showingDatePicker = false
	@State private var showingSearchBar = false
	@State private var searchSheetState: SheetView<SearchResultView>.CardState = .hide
	@State private var searchRequest = (text: "", priority: 0)
	@GestureState var dateLabelScrollX: CGFloat = 0

	
	private let today = Date().toInt
	private var calendarLanguage: SettingKey.Language {
		settingController.language
	}
	
	private var weeklyNavigationBinding: Binding<Bool> {
		.init(get: {
			states.weeklyViewDateInt != nil
		}, set: { active in
			if !active {
				states.presentingScheduleId = nil
				states.weeklyViewDateInt = nil
			}
		})
	}
	
	init(states: EnvironmentObject<ViewStates>) {
		_states = states
		_adjacentMonth = .init(initialValue: (-6...6).reduce(into: []) { array, addedMonth in
			array.append(Calendar.current.date(byAdding: .month, value: addedMonth, to: states.wrappedValue.scheduleViewDate)!)
		})
	}
	
	var body: some View {
		GeometryReader { geometry in
			ZStack {
				weeklyViewNavigationLink
				VStack {
					drawTopBar(in: geometry.size)
					if settingController.calendarPaging == .scroll{
						drawCalendarScrollView(in: geometry.size)
					}else {
						drawCalendarPagecurl(in: geometry.size)
					}
					Spacer()
				}
				showDatePickerPopup(in: geometry.size)
				if searchSheetState == .top {
					showBackgroundBlur {
						searchSheetState = .hide
					}
				}
				SheetView(cardState: $searchSheetState,
									handleColor: Color(settingController.palette.primary),
									backgroundColor: Color(settingController.palette.quaternary), cardStatesAvailable: [.hide, .middle, .top]) {
					SearchResultView(
						searchRequest: $searchRequest,
						selectSchedule: { schedule in
						 hideKeyboard()
							withAnimation {
								states.presentingScheduleId = schedule.id
							}
						},
						selectDate: { date in
							states.weeklyViewDateInt = date.toInt
						})
				}
									.onChange(of: searchSheetState) {
										if $0 == .hide {
											withAnimation {
												showingSearchBar = false
												searchRequest = (text: "", priority: 0)
											}
										}
									}
				showScheduleDetailIfPresenting(in: geometry.size)
			}
		}
	}
	
	private var weeklyViewNavigationLink: some View {
		NavigationLink("Weekly schedule", isActive: weeklyNavigationBinding) {
			Group {
				if states.weeklyViewDateInt != nil {
					WeeklyView(selectedDateInt: $states.weeklyViewDateInt)
				}
			}
		}
		.hidden()
	}
	
	private func drawTopBar(in size: CGSize) -> some View {
		ZStack {
			HStack(spacing: 30) {
				Spacer()
					.frame(width: 30)
				dateLabel
					.zIndex(1)
				calendarButton
				searchButton
			}
			.frame(height: 60)
			if showingSearchBar {
				Group {
					showBackgroundBlur {
						showingSearchBar = false
					}
					SearchBarPopup(isPresented: $showingSearchBar,
												 searchRequest: $searchRequest,
												 changeShowingResult: { isShowing in
						withAnimation(.interpolatingSpring(stiffness: 300.0, damping: 30.0)) {
							searchSheetState = isShowing ? .middle: .hide
						}
					},
												 language: settingController.language)
				}
				.frame(height: size.height * 0.2)
			}
		}
	}
	
	private var dateLabel: some View {
		let isScrolling = dateLabelScrollX != 0
		return HStack {
			if !isScrolling {
				Image(systemName: "chevron.left")
					.foregroundColor(Color(settingController.palette.primary))
			}
			drawDateLabel(for: states.scheduleViewDate)
				.offset(x: dateLabelScrollX)
				.gesture(
					DragGesture(minimumDistance: 20)
						.updating($dateLabelScrollX) { gestureValue, dateLabelScrollX, _ in
							if abs(gestureValue.translation.width) < 100 {
								dateLabelScrollX = gestureValue.translation.width
							}
						}
						.onEnded { gestureValue in
							withAnimation {
								guard abs(gestureValue.translation.width) > 20 else {
									return
								}
								let toNextMonth = gestureValue.translation.width < 0
								states.scheduleViewDate = toNextMonth ? states.scheduleViewDate.aMonthAfter : states.scheduleViewDate.aMonthAgo
							}
						}
				)
				.opacity(isScrolling ? 1.0 - abs(dateLabelScrollX/100): 1)
				.overlay(
					HStack {
						drawDateLabel(for: states.scheduleViewDate.aMonthAgo)
							.frame(width: dateLabelScrollX > 0 ? 100: 0)
							.opacity(abs(dateLabelScrollX/100))
						Spacer()
							.frame(width: 200)
						drawDateLabel(for: states.scheduleViewDate.aMonthAfter).frame(width: dateLabelScrollX < 0 ? 100: 0)
							.opacity(abs(dateLabelScrollX/100))
					}
						.offset(x: dateLabelScrollX)
				)
			if !isScrolling {
				Image(systemName: "chevron.right")
					.foregroundColor(Color(settingController.palette.primary))
			}
		}
	}
	
	private func drawDateLabel(for date: Date) -> some View {
		let isScrolling = dateLabelScrollX != 0
		return HStack {
			if calendarLanguage == .korean {
				Text(String(date.year) + "년 " +  String(date.month) + "월")
					.withCustomFont(size: isScrolling ? .body: .subheadline, for: settingController.language)
			}else {
				Text(DateFormatter().monthSymbols[date.month - 1])
					.withCustomFont(size: isScrolling ? .body: .subheadline, for: settingController.language)
				Text(String(date.year))
					.withCustomFont(size: isScrolling ? .body: .subheadline, for: settingController.language)
			}
		}	
	}
	
	private var searchButton: some View {
		Image(systemName: "magnifyingglass")
			.resizable()
			.frame(width: 30, height: 30)
			.onTapGesture {
				withAnimation {
					showingSearchBar = true
				}
			}
	}
	
	private var calendarButton: some View {
		Image(systemName: "calendar")
			.resizable()
			.frame(width: 30, height: 30)
			.onTapGesture {
				withAnimation {
					showingDatePicker = true
				}
			}
			.onChange(of: states.scheduleViewDate) { _ in
				withAnimation {
					showingDatePicker = false
				}
			}
	}
	
	@State private var adjacentMonth: [Date]
	
	private func drawCalendarScrollView(in size: CGSize) -> some View {
		HStack(alignment: .top, spacing: 0) {
			TabView(selection: $states.scheduleViewDate) {
				ForEach(adjacentMonth, id: \.self) { date in
					VStack(spacing: 10) {
						drawWeekLabelBar(in: size)
						MonthlyCalendarView(
							referenceDate: date,
							searchRequest: $searchRequest,
							size: CGSize(width: size.width,
													 height: size.height * 0.7)) {
														 states.weeklyViewDateInt = $0
													 }
													 .frame(maxHeight: size.height * 0.8)
						Spacer()
					}
					.frame(width: size.width,
								 height: size.height * 0.9)
					.tag(date)
				}
			}
			.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
			.onChange(of: states.scheduleViewDate) { date in
				if states.scheduleViewDate == adjacentMonth.first ||
						states.scheduleViewDate == adjacentMonth.last ||
						!adjacentMonth.contains(states.scheduleViewDate){
					adjacentMonth = (-6...6).reduce(into: []) { array, addedMonth in
						array.append(Calendar.current.date(byAdding: .month, value: addedMonth, to: states.scheduleViewDate)!)
					}
				}
			}
		}
	}
	
	private func drawCalendarPagecurl(in size: CGSize) -> some View {
		VStack(spacing: 10) {
			drawWeekLabelBar(in: size)
			CalendarViewControllerRepresentation(
				scheduleController: scheduleController,
				settingController: settingController,
				states: states,
				searchRequest: $searchRequest) { dateInt in
					states.weeklyViewDateInt = dateInt
				}
			Spacer()
		}
		.frame(width: size.width,
					 height: size.height * 0.95)
	}
	
	private func getColorForWeekday(_ weekday: Int) -> Color {
		if weekday == 0 {
			return .pink
		}else if weekday == 6 {
			return .blue
		}else {
			return .black
		}
	}
	
	private func drawWeekLabelBar(in size: CGSize) -> some View {
		HStack(spacing: 0) {
			ForEach(0..<7) { weekday in
				Text(calendarLanguage == .korean ? Calendar.koreanWeekDays[weekday]: Calendar.englishWeekDays[weekday])
					.withCustomFont(size: .subheadline, for: settingController.language)
					.frame(width: size.width / 7, height: 40)
					.foregroundColor(getColorForWeekday(weekday))
			}
		}
		.background(Color(settingController.palette.tertiary.withAlphaComponent(0.5)))
	}
	
	private func showDatePickerPopup(in size: CGSize) -> some View {
		ZStack {
			if showingDatePicker  {
				showBackgroundBlur {
					showingDatePicker = false
				}
			}
			if showingDatePicker {
				DatePickerPopup(date: $states.scheduleViewDate, language: settingController.language)
					.background(Color(settingController.palette.quaternary.withAlphaComponent(0.5))
												.cornerRadius(30))
					.position(x: size.width/2,
										y: size.height * 0.4)
					.transition(.move(edge: .top))
			}
		}
	}
	
	private func showScheduleDetailIfPresenting(in size: CGSize) -> some View {
		ZStack {
			showBackgroundBlur {
				states.presentingScheduleId = nil
			}
			.opacity(states.presentingScheduleId != nil && states.weeklyViewDateInt == nil ? 1: 0)
			.allowsHitTesting(states.presentingScheduleId != nil)
			if states.presentingScheduleId != nil, states.weeklyViewDateInt == nil {
				ScheduleDetailView(
					schedule: scheduleController.getSchedule(by: states.presentingScheduleId!)!,
					isPresenting: .init(get: {
						states.presentingScheduleId != nil
					}, set: { presenting in
						if !presenting {
							withAnimation {
								states.presentingScheduleId = nil
							}
						}
					}))
					.frame(width: size.width * 0.9)
					.frame(minHeight: size.height * 0.7, idealHeight: size.height * 0.8,
								 maxHeight: size.height * 0.9)
					.fixedSize()
					
					.transition(.move(edge: .bottom))
			}
		}
	}
	
	private struct CalendarViewControllerRepresentation: UIViewControllerRepresentable {
		
		let states: ViewStates
		let scheduleController: ScheduleModelController
		let settingController: SettingController
		@Binding var searchRequest: (text: String, priority: Int)
		private let tapCalendarCell: (Int) -> Void
		
		private let coordinator: Coordinator
		
		func makeUIViewController(context: Context) -> UIPageViewController {
			let pageViewController = UIPageViewController(transitionStyle: .pageCurl, navigationOrientation: .vertical)
			pageViewController.dataSource = coordinator
			pageViewController.delegate = coordinator
			pageViewController.setViewControllers([coordinator.secondCalendar], direction: .forward, animated: true)
			if let tapGesture = pageViewController.gestureRecognizers.first(where: {
				$0 is UITapGestureRecognizer
			}) {
				pageViewController.view.removeGestureRecognizer(tapGesture)
			}
			coordinator.pageViewController = pageViewController
			return pageViewController
		}
		
		func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
			let yearAndMonth = states.scheduleViewDate.year * 100 + states.scheduleViewDate.month
			guard let presentedYearAndMonth = context.coordinator.currentCalendar?.yearAndMonth,
						yearAndMonth != presentedYearAndMonth else {
							return
						}
			let direction: UIPageViewController.NavigationDirection = yearAndMonth > presentedYearAndMonth ? .forward: .reverse
			uiViewController.setViewControllers([direction == .forward ? context.coordinator.nextCalendar : context.coordinator.prevCalendar], direction: direction, animated: true, completion: nil)
			context.coordinator.setDate(states.scheduleViewDate)
		}
		
		func makeCoordinator() -> Coordinator {
			coordinator
		}
		
		init(scheduleController: ScheduleModelController, settingController: SettingController,
				 states: ViewStates,
				 searchRequest: Binding<(text: String, priority: Int)>, tapCalendarCell: @escaping (Int) -> Void) {
			self.scheduleController = scheduleController
			self.settingController = settingController
			self.states = states
			_searchRequest = searchRequest
			self.tapCalendarCell = tapCalendarCell
			
			let firstCalendar =
			MonthlyVC(scheduleController: scheduleController, settingController: settingController, searchRequest: searchRequest, tapCell: tapCalendarCell)
			let secondCalendar =
			MonthlyVC(scheduleController: scheduleController, settingController: settingController, searchRequest: searchRequest, tapCell: tapCalendarCell)
			let thirdCalendar =
			MonthlyVC(scheduleController: scheduleController, settingController: settingController, searchRequest: searchRequest, tapCell: tapCalendarCell)
			[firstCalendar, secondCalendar, thirdCalendar].forEach {
				$0.loadViewIfNeeded()
			}
			coordinator = Coordinator(firstCalendar: firstCalendar, secondCalendar: secondCalendar, thirdCalendar: thirdCalendar, referenceDate: .init(get: {
				states.scheduleViewDate
			}, set: {
				states.scheduleViewDate = $0
			}))
			coordinator.setDate(states.scheduleViewDate)
		}
		
		class Coordinator: NSObject, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
			
			let firstCalendar: MonthlyVC
			let secondCalendar: MonthlyVC
			let thirdCalendar: MonthlyVC
			var pageViewController: UIPageViewController?
			@Binding var currentReferenceDate: Date
			var currentCalendar: MonthlyVC? {
				pageViewController?.viewControllers!.first as? MonthlyVC
			}
			var prevCalendar: MonthlyVC {
				if currentCalendar == firstCalendar {
					return thirdCalendar
				}else if currentCalendar == secondCalendar {
					return firstCalendar
				}else {
					return secondCalendar
				}
			}
			var nextCalendar: MonthlyVC {
				if currentCalendar == firstCalendar {
					return secondCalendar
				}else if currentCalendar == secondCalendar {
					return thirdCalendar
				}else {
					return firstCalendar
				}
			}
			
			func setDate(_ date: Date) {
				if currentCalendar?.yearAndMonth != date.year * 100 + date.month {
					currentCalendar?.yearAndMonth = date.year * 100 + date.month
				}
				prevCalendar.yearAndMonth = (date.aMonthAgo.year * 100) + date.aMonthAgo.month
				nextCalendar.yearAndMonth = (date.aMonthAfter.year * 100) + date.aMonthAfter.month
			}
			
			func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
				if viewController == secondCalendar {
					return firstCalendar
				}else if viewController == thirdCalendar {
					return secondCalendar
				}else {
					return thirdCalendar
				}
			}
			
			func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
				if viewController == firstCalendar {
					return secondCalendar
				}else if viewController == secondCalendar {
					return thirdCalendar
				}else {
					return firstCalendar
				}
			}
			
			func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
				guard let currentCalendar = currentCalendar,
					let previousCalendar = previousViewControllers.first as? MonthlyVC else {
					return
				}
				let monthAlter = currentCalendar.yearAndMonth > previousCalendar.yearAndMonth ? 1 :  -Int(1)
				if let newReferenceDate = Calendar.current.date(byAdding: .month, value: monthAlter, to: currentReferenceDate) {
					setDate(newReferenceDate)
				}else {
					var arbitaryDate = Calendar.current.date(bySetting: .year, value: currentCalendar.yearAndMonth / 100, of: currentReferenceDate)!
					arbitaryDate = Calendar.current.date(bySetting: .month, value: currentCalendar.yearAndMonth % 100, of: arbitaryDate)!
					arbitaryDate = Calendar.current.date(bySetting: .day, value: 15, of: arbitaryDate)!
					setDate(arbitaryDate)
				}
				
			}
			
			init(firstCalendar: MonthlyVC, secondCalendar: MonthlyVC, thirdCalendar: MonthlyVC, referenceDate: Binding<Date>) {
				self.firstCalendar = firstCalendar
				self.secondCalendar = secondCalendar
				self.thirdCalendar = thirdCalendar
				_currentReferenceDate = referenceDate
			}
			
		}
	}
}

struct CalendarView_Previews: PreviewProvider {
	static var previews: some View {
		CalendarView(states: .init())
			.environmentObject(SettingController())
			.environmentObject(ScheduleModelController())
	}
}
