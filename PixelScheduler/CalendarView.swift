//
//  CalendarView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/05.
//

import SwiftUI

struct CalendarView: View {
	
	@EnvironmentObject var scheduleController: ScheduleModelController
	@EnvironmentObject var settingController: SettingController
	@Binding var currentReferenceDate: Date
	@State private var showingDatePicker = false
	@State private var showingSearchBar = false
	@State private var showingSearchResult = false
	@State private var searchRequest = (text: "", priority: 0)
	@State private var weeklyViewDateInt: Int? = nil
	
	private let today = Date().toInt
	private var calendarLanguage: SettingKey.DateLanguage {
		settingController.dateLanguage
	}
	
	private var weeklyNavigationBinding: Binding<Bool> {
		.init(get: {
			weeklyViewDateInt != nil
		}, set: { active in
			if !active {
				weeklyViewDateInt = nil
			}
		})
	}
	
    var body: some View {
		GeometryReader { geometry in
			ZStack {
				weeklyViewNavigationLink
				VStack {
					drawTopBar(in: geometry.size)
						.fixedSize(horizontal: false, vertical: true)
						.zIndex(1)
					if settingController.calendarPaging == .scroll{
						drawCalendarScrollView(in: geometry.size)
					}else {
						drawCalendarPagecurl(in: geometry.size)
					}
					Spacer()
				}
				showDatePickerPopup(in: geometry.size)
				SheetView(isPresented: $showingSearchResult,
						  handleColor: Color(settingController.palette.primary),
						  backgroundColor: Color(settingController.palette.quaternary)) {
					SearchResultView(searchRequest: $searchRequest)
				}
				.onChange(of: showingSearchResult) {
					if !$0 {
						withAnimation {
							showingSearchBar = false
							searchRequest = (text: "", priority: 0)
						}
					}
				}
			}
		}
    }
	
	private var weeklyViewNavigationLink: some View {
		NavigationLink("Weekly schedule", isActive: weeklyNavigationBinding) {
			Group {
				if weeklyViewDateInt != nil {
					WeeklyView(selectedDateInt: $weeklyViewDateInt)
						.environmentObject(scheduleController)
						.environmentObject(settingController)
				}
			}
		}
		.hidden()
	}
	
	private func drawTopBar(in size: CGSize) -> some View {
		ZStack {
			HStack(spacing: 30) {
				drawCharacterHelper(in: size)
				dateLabel
				calendarButton
				searchButton
			}
			if showingSearchBar {
				showBackgroundBlur {
					showingSearchBar = false
					showingSearchResult = false
					searchRequest = (text: "", priority: 0)
				}
				SearchBarPopup(isPresented: $showingSearchBar,
							 searchRequest: $searchRequest,
							   showingResult: $showingSearchResult,
							   language: settingController.dateLanguage)
			}
		}
	}
	
	private func drawCharacterHelper(in size: CGSize) -> some View {
		 GeometryReader { characterGeometry in
			CharacterHelperView(character: settingController.character,
								guide: .monthlyCalendar,
								helpWindowSize: CGSize(width: size.width * 0.9,
													   height: size.height * 0.7),
								characterLocation: characterGeometry.frame(in: .global).origin)
		}
		 .frame(width: 80, height: 80)
		 .border(.red, width: 4)
	}
	
	private var dateLabel: some View {
		HStack {
			if calendarLanguage == .korean {
				Text(String(currentReferenceDate.year) + "년")
				Text(String(currentReferenceDate.month) + "월")
			}else {
				Text(DateFormatter().monthSymbols[currentReferenceDate.month - 1])
				Text(String(currentReferenceDate.year))
			}
		}
		.font(.custom(calendarLanguage == .korean ? "YANGJIN": "RetroGaming", fixedSize: 18))
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
			.onChange(of: currentReferenceDate) { _ in
				withAnimation {
					showingDatePicker = false
				}
			}
	}
	
	@State private var adjacentMonth: [Date]
	
	private func drawCalendarScrollView(in size: CGSize) -> some View {
		HStack(alignment: .top, spacing: 0) {
			TabView(selection: $currentReferenceDate) {
				ForEach(adjacentMonth, id: \.self) { date in
					VStack(spacing: 10) {
						drawWeekLabelBar(in: size)
						MonthlyCalendarView(referenceDate: date,
											searchRequest: $searchRequest,
											size: CGSize(width: size.width,
														 height: size.height * 0.7)) {
							weeklyViewDateInt = $0
						}
						Spacer()
					}
					.frame(width: size.width,
						   height: size.height * 0.9)
					.tag(date)
				}
			}
			.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
			.onChange(of: currentReferenceDate) { date in
				if currentReferenceDate == adjacentMonth.first ||
					currentReferenceDate == adjacentMonth.last ||
					!adjacentMonth.contains(currentReferenceDate){
					adjacentMonth = (-6...6).reduce(into: []) { array, addedMonth in
						array.append(Calendar.current.date(byAdding: .month, value: addedMonth, to: currentReferenceDate)!)
					}
				}
			}
		}
	}
	
	private func drawCalendarPagecurl(in size: CGSize) -> some View {
		VStack(spacing: 10) {
			drawWeekLabelBar(in: size)
			CalendarViewControllerRepresentation(scheduleController: scheduleController,
												 settingController: settingController,
												 currentReferenceDate: $currentReferenceDate,
												 searchRequest: $searchRequest) { dateInt in
				weeklyViewDateInt = dateInt
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
					Group {
						if calendarLanguage == .korean {
							Text(Calendar.koreanWeekDays[weekday])
								.font(.custom("YANGJIN", size: 17))
						}else {
							Text(Calendar.englishWeekDays[weekday])
								.font(.custom("RatroGaming", size: 17))
						}
					}
					.frame(width: size.width / 7, height: 30)
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
				DatePickerPopup(date: $currentReferenceDate, language: settingController.dateLanguage)
					.background(Color(settingController.palette.quaternary.withAlphaComponent(0.5))
									.cornerRadius(30))
					.position(x: size.width/2,
							  y: size.height * 0.3)
					.transition(.move(edge: .top))
			}
		}
	}
	
	init(referenceDate: Binding<Date>) {
		_currentReferenceDate = referenceDate
		_adjacentMonth = .init(initialValue: (-6...6).reduce(into: []) { array, addedMonth in
			array.append(Calendar.current.date(byAdding: .month, value: addedMonth, to: referenceDate.wrappedValue)!)
		})
	}
	
	private struct CalendarViewControllerRepresentation: UIViewControllerRepresentable {
		
		let scheduleController: ScheduleModelController
		let settingController: SettingController
		@Binding var currentReferenceDate: Date
		@Binding var searchRequest: (text: String, priority: Int)
		private let tapCalendarCell: (Int) -> Void
		
		private let coordinator: Coordinator
		
		func makeUIViewController(context: Context) -> some UIViewController {
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
		func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
			let yearAndMonth = currentReferenceDate.year * 100 + currentReferenceDate.month
			if yearAndMonth != context.coordinator.currentCalendar?.yearAndMonth {
				context.coordinator.setDate(currentReferenceDate)
			}
			
		}
		
		func makeCoordinator() -> Coordinator {
			coordinator
		}
		
		init(scheduleController: ScheduleModelController, settingController: SettingController, currentReferenceDate: Binding<Date>, searchRequest: Binding<(text: String, priority: Int)>, tapCalendarCell: @escaping (Int) -> Void) {
			self.scheduleController = scheduleController
			self.settingController = settingController
			_currentReferenceDate = currentReferenceDate
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
			coordinator = Coordinator(firstCalendar: firstCalendar, secondCalendar: secondCalendar, thirdCalendar: thirdCalendar, referenceDate: currentReferenceDate)
			coordinator.setDate(currentReferenceDate.wrappedValue)
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
			private var prevCalendar: MonthlyVC {
				if currentCalendar == firstCalendar {
					return thirdCalendar
				}else if currentCalendar == secondCalendar {
					return firstCalendar
				}else {
					return secondCalendar
				}
			}
			private var nextCalendar: MonthlyVC {
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
				currentReferenceDate = date
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
				let monthAlter = currentCalendar.yearAndMonth > previousCalendar.yearAndMonth ? 1: -1
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
		CalendarView(referenceDate: .constant(Date()))
			.environmentObject(SettingController())
			.environmentObject(ScheduleModelController())
    }
}
