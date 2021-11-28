//
//  MonthlyVC.swift
//  PixelScheduler
//
//  Created by bart Shin on 07/06/2021.
//

import SwiftUI
import Combine
import AVFoundation

class MonthlyVC: UIViewController, PlaySoundEffect, ColorBackground {
	
	// MARK: Controller
	var settingController: SettingController
	var modelController: ScheduleModelController
	
	// MARK: - Properties
	
	private var observeScheduleCancellable: AnyCancellable?
	var showDailyViewSegue: (Int) -> Void
	private let today = Date()
	var yearAndMonth: Int! = nil{
		didSet{
			updateCalendar()
		}
	}
	
	var searchRequest: Binding<(text: String, priority: Int)>
	
	private var calendarView: UICollectionView!
	let hapticGenerator = UIImpactFeedbackGenerator()
	var squaresInCalendarView = [Int?]()
	var player: AVAudioPlayer!
	let gradient = CAGradientLayer()
	let blurEffect = UIBlurEffect()
	var backgroundView: UIView!
	let blurEffectView = UIVisualEffectView()
	private var droppingCell: UIView?
	
	func updateCalendar() {
		guard yearAndMonth > 190001 && yearAndMonth < 20500101 else {
			assertionFailure("Attemp to update calendar with invaild year")
			return
		}
		squaresInCalendarView.removeAll()
		let totalDays = Calendar.getDaysInMonth(yearAndMonth)
		let firstDay = Calendar.firstDateOfMonth(yearAndMonth)
		let startSqureNumber = firstDay.weekDay - 1
		
		for index in 0...41 {
			if index < startSqureNumber || (index - startSqureNumber + 1) > totalDays{
				squaresInCalendarView.append(nil)
			}else {
				let date = index - startSqureNumber + 1
				squaresInCalendarView.append((yearAndMonth * 100) + date)
			}
		}
		calendarView.reloadData()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		observeSchedules()
		backgroundView = UIView(frame: view.bounds)
		initBackground()
		view.addSubview(backgroundView)
		initCalendarView()
		view.addInteraction(UIDropInteraction(delegate: self))
	}
	
	private func initCalendarView() {
		let flowLayout = UICollectionViewFlowLayout()
		calendarView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
		view.addSubview(calendarView)
		calendarView.translatesAutoresizingMaskIntoConstraints = false
		calendarView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
		calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
		calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
		calendarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
		calendarView.register(CalendarCell.self, forCellWithReuseIdentifier: "CalendarCell")
		calendarView.isScrollEnabled = false
		calendarView.dataSource = self
		calendarView.delegate = self
	}
	
	private func observeSchedules() {
		observeScheduleCancellable = modelController.objectWillChange.sink
		{ [weak weakSelf = self] in
			weakSelf?.calendarView.reloadData()
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		updateBackground()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		calendarView.visibleCells.forEach {
			$0.layoutSubviews()
		}
	}
	
	init(scheduleController: ScheduleModelController,
		 settingController: SettingController,
		 searchRequest: Binding<(text: String, priority: Int)>,
		 tapCell: @escaping (Int) -> Void) {
		self.modelController = scheduleController
		self.settingController = settingController
		self.searchRequest = searchRequest
		self.showDailyViewSegue = tapCell
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

extension MonthlyVC: UIDropInteractionDelegate {
	
	func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
		session.canLoadObjects(ofClass: String.self)
	}
	
	func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
		let location = session.location(in: view)
		if let startView = calendarView.hitTest(location, with: nil) ,
			 let cell = findCalendarCellView(from: startView) {
			if cell != droppingCell {
				droppingCell?.layer.borderColor = UIColor.clear.cgColor
				cell.layer.borderWidth = 2
				cell.layer.cornerRadius = 10
				cell.layer.borderColor = settingController.palette.secondary.withAlphaComponent(0.7).cgColor
				droppingCell = cell
			}
			return UIDropProposal(operation: .move)
		}
		return UIDropProposal(operation: .forbidden)
	}
	
	func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
		droppingCell?.layer.borderColor = UIColor.clear.cgColor
		let location = session.location(in: calendarView)
		guard let startView = calendarView.hitTest(location, with: nil),
					let cell = findCalendarCellView(from: startView) else {
			return
		}
		_ = session.loadObjects(ofClass: String.self) { [weak weakSelf = self] object in
			if let scheduleId = object.first,
				 let uuid = UUID(uuidString: scheduleId) {
				weakSelf?.moveSchedule(uuid, to: cell.tag)
			}
		}
	}
	
	func dropInteraction(_ interaction: UIDropInteraction, sessionDidEnd session: UIDropSession) {
		droppingCell?.layer.borderColor = UIColor.clear.cgColor
	}
	
	private func moveSchedule(_ scheduleId: UUID, to dateInt: Int) {
		guard let schedule = modelController.getSchedule(by: scheduleId) else {
			assertionFailure("Dropped scheuld is not exist \(scheduleId)")
			return
		}
		var newTime: Schedule.DateType?
		if case let .spot(originalDate) = schedule.time,
			 let newDate = originalDate.changeDate(to: dateInt) {
			newTime = .spot(newDate)
		}else if case let .period(startDate, endDate) = schedule.time,
						 let newStartDate = startDate.changeDate(to: dateInt),
						 let newEndDate = endDate.changeDate(to: dateInt){
			newTime = .period(start: newStartDate, end: newEndDate)
			
		}
		guard newTime != nil else {
			assertionFailure("Fail to create new date \(schedule)")
			return
		}
		var newSchedule = Schedule(title: schedule.title,
															 description: schedule.description,
															 priority: schedule.priority,
															 time: newTime!,
															 alarm: schedule.alarm,
															 storeAt: schedule.origin,
															 with: schedule.id,
															 location: schedule.location,
															 contact: schedule.contact)
		newSchedule.isAlarmOn = schedule.isAlarmOn
		newSchedule.copyCompleteHistory(from: schedule)
		if !modelController.replaceSchedule(schedule, to: newSchedule, alarmCharacter: settingController.character) {
			showAlertForDismiss(title: "드래그 오류",
													message: "일정을 옮기는데 실패했습니다. 해당 일정을 직접 수정해 주세요",
													with: settingController.visualMode)
		}
	}
	
	private func findCalendarCellView(from startView: UIView) -> UIView? {
		if startView.tag != 0 {
			return startView
		}else if let superView = startView.superview {
			return findCalendarCellView(from: superView)
		}else {
			return nil
		}
	}
}

extension MonthlyVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		squaresInCalendarView.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		var cell = calendarView.dequeueReusableCell(
			withReuseIdentifier: CalendarCell.reuseID,
			for: indexPath) as! CalendarCell
		cell = drawCell(cell, at: indexPath, calendarView: calendarView, with: settingController.palette)
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		guard let firstCell = squaresInCalendarView.first(where: {
			$0 != nil
		}),
		let firstDate = firstCell?.toDate else {
			return .zero
		}
		let lastDateInt = firstDate.lastDateOfMonth
		let numRows: Int
		if (firstDate.weekDay == 7 && lastDateInt > 29) ||
				(firstDate.weekDay == 6 && lastDateInt > 30){
			numRows = 7
		}else {
			numRows = 6
		}
		return CGSize(width: calendarView.bounds.size.width / 8.5,
					  height: calendarView.bounds.size.height / CGFloat(numRows))
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		hapticGenerator.prepare()
		if let dateToShow = squaresInCalendarView[indexPath.row]{
			showDailyViewSegue(dateToShow)
			hapticGenerator.generateFeedback(for: settingController.hapticMode)
			playSound(AVAudioPlayer.paper)
		}
	}
	
	private func drawCell(_ cell: CalendarCell, at indexPath: IndexPath, calendarView: UICollectionView, with palette: SettingKey.ColorPalette) -> CalendarCell {
		cell.contentView.subviews.forEach {
			$0.removeFromSuperview()
		}
		let dateInt = squaresInCalendarView[indexPath.item]
		if let date = dateInt?.toDate{
			let holiday = modelController.holidayTable[dateInt!]
			// toss data to cell
			let hostingController = UIHostingController(
				rootView: CalendarCellView(
					date: date,
					schedules: modelController.getSchedules(for: dateInt!),
					sticker: modelController.stickerTable[dateInt!],
					searchRequest: searchRequest,
					holiday: holiday,
					colorPalette: settingController.palette))
			cell.contentView.tag = dateInt!
			
			cell.contentView.addSubview(hostingController.view)
			hostingController.view.translatesAutoresizingMaskIntoConstraints = false
			hostingController.view.topAnchor.constraint(equalTo: cell.contentView.topAnchor).isActive = true
			hostingController.view.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor).isActive = true
			hostingController.view.leftAnchor.constraint(equalTo: cell.contentView.leftAnchor).isActive = true
			hostingController.view.rightAnchor.constraint(equalTo: cell.contentView.rightAnchor).isActive = true
			
			
			cell.hostingController = hostingController
			hostingController.view.backgroundColor = .clear
		}else {
			cell.contentView.tag = 0
		}
		return cell
	}
	
}
