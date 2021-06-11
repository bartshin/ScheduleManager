//
//  MonthlyVC.swift
//  PixelScheduler
//
//  Created by bart Shin on 07/06/2021.
//

import UIKit
import Combine
import AVFoundation

class MonthlyVC: UIViewController, PlaySoundEffect, ColorBackground {
	
	// MARK: Controller
	var settingController: SettingController!
	var modelController: ScheduleModelController!
	
	// MARK:- Properties
	
	private var observeScheduleCancellable: AnyCancellable?
	var showDailyViewSegue: (Int) -> Void = { _ in}
	private let today = Date()
	var yearAndMonth: Int! = nil{
		didSet{
			updateCalendar()
		}
	}
	
	var searchRequest = SearchRequest(priority: nil, text: nil) {
		didSet {
			calendarView.reloadData()
		}
	}
	
	@IBOutlet private weak var calendarView: UICollectionView!
	let hapticGenerator = UIImpactFeedbackGenerator()
	var squaresInCalendarView = [Int?]()
	var player: AVAudioPlayer!
	let gradient = CAGradientLayer()
	let blurEffect = UIBlurEffect()
	@IBOutlet weak var backgroundView: UIView!
	let blurEffectView = UIVisualEffectView()
	
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
		calendarView.isScrollEnabled = false
		calendarView.dataSource = self
		calendarView.delegate = self
		initBackground()
	}
	
	fileprivate func observeSchedules() {
		observeScheduleCancellable = modelController.objectWillChange.sink
		{ [weak weakSelf = self] in
			weakSelf?.calendarView.reloadData()
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		updateBackground()
	}
	
	struct SearchRequest {
		var priority: Int?
		var text: String?
		static var empty = SearchRequest(priority: nil, text: nil)
	}
}

extension MonthlyVC:  UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		squaresInCalendarView.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		var cell = calendarView.dequeueReusableCell(
			withReuseIdentifier: CalendarCell.reuseID,
			for: indexPath) as! CalendarCell
		cell = drawCell(cell, at: indexPath, calendarView: calendarView, with: settingController.palette)
		if !isEmptyCell(cell) {
			cell.calendarCellView.searchRequest = searchRequest
		}
		if let dateInt = squaresInCalendarView[indexPath.item] {
			cell.calendarCellView.sticker = modelController.stickerTable[dateInt]
		}
		cell.calendarCellHC.view.backgroundColor = .clear
		cell.calendarCellView.labelLanguage = settingController.dateLanguage
		return cell
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
			numRows = 6
		}else {
			numRows = 5
		}
		return CalendarCell.size(in: calendarView.bounds.size, with: numRows)
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		hapticGenerator.prepare()
		if let dateToShow = squaresInCalendarView[indexPath.row]{
			showDailyViewSegue(dateToShow)
			hapticGenerator.generateFeedback(for: settingController.hapticMode)
			playSound(AVAudioPlayer.paper)
		}
	}
	
	fileprivate func isEmptyCell(_ cell: CalendarCell) -> Bool {
		return cell.calendarCellView.date == nil
	}
	
	fileprivate func drawCell(_ cell: CalendarCell, at indexPath: IndexPath, calendarView: UICollectionView, with palette: SettingKey.ColorPalette) -> CalendarCell {
		
		let dateInt = squaresInCalendarView[indexPath.item]
		if dateInt != nil {
			// toss data to cell
			cell.calendarCellView.date = dateInt!.toDate
			cell.calendarCellView.colorPalette = palette
			cell.calendarCellView.holiday = modelController.holidayTable[dateInt!]
			cell.calendarCellView.schedules = modelController.getSchedules(for: dateInt!)
			// adjust swift ui view
			cell.calendarCellHC.view.translatesAutoresizingMaskIntoConstraints = false
			cell.calendarCellHC.view.frame = cell.contentView.frame
			cell.contentView.addSubview(cell.calendarCellHC.view)
		}else {
			cell.calendarCellHC.rootView.date = nil
			cell.calendarCellHC.view.removeFromSuperview()
		}
		return cell
	}
	
}
