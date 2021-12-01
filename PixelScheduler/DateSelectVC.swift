//
//  DateSelectVC.swift
//  Schedule_B
//
//  Created by Shin on 2/28/21.
//

import SwiftUI

class DateSelectVC: UIViewController {
	
	// MARK: Controller
	let cyclePicker = UIHostingController(rootView: CyclePickerView(language: .korean, currentSegmentType: .weekly))
	var recievedDate: Date?
	var recievedEndDate: Date?
	var recievedCycle: (Schedule.CycleFactor, [Int])?
	
	// MARK:- Properties
	
	var dateLanguage: SettingKey.Language = .korean
	
	@IBOutlet private weak var spotPickerView: UIView!
	@IBOutlet private(set) weak var spotDatePicker: UIDatePicker!
	@IBOutlet private weak var periodPickerView: UIView!
	@IBOutlet private(set) weak var startDatePicker: UIDatePicker!
	@IBOutlet private weak var endDatePicker: UIDatePicker!
	@IBOutlet private weak var cyclePickerView: UIView!
	
	/// [ 0: spot, 1: period, 2: cycle]
	var viewIndexPresenting = 0 {
		didSet {
			spotPickerView.isHidden = viewIndexPresenting != 0
			periodPickerView.isHidden = viewIndexPresenting != 1
			cyclePickerView.isHidden = viewIndexPresenting != 2 && viewIndexPresenting != 3
			if viewIndexPresenting == 2 {
				// Weekly cycle
				cyclePicker.rootView.currentSegmentType = .weekly
			}else if viewIndexPresenting == 3 {
				// Monthly cycle
				cyclePicker.rootView.currentSegmentType = .monthly
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		addChild(cyclePicker)
		let locale = Locale(identifier: dateLanguage.locale)
		spotDatePicker.locale = locale
		startDatePicker.locale = locale
		endDatePicker.locale = locale
		cyclePicker.view.frame = cyclePickerView.frame
		cyclePickerView.addSubview(cyclePicker.view)
		cyclePicker.didMove(toParent: self)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if recievedDate != nil {
			spotDatePicker.date = recievedDate!
			startDatePicker.date = recievedDate!
		}
		if recievedEndDate != nil {
			endDatePicker.date = recievedEndDate!
		}
		if recievedCycle != nil {
			cyclePicker.rootView.selected.selectedIndices = recievedCycle!.0 == .weekday ? Set(recievedCycle!.1.compactMap { $0 - 1 }): Set(recievedCycle!.1)
		}
	}
	
	func getDatePicked() -> Schedule.DateType? {
		switch viewIndexPresenting {
		case 0:
			return .spot(spotDatePicker.date)
		case 1:
			if startDatePicker.date < endDatePicker.date {
				return .period(start: startDatePicker.date, end: endDatePicker.date)
			}else {
				return nil
			}
		case 2:
			return .cycle(since: spotDatePicker.date, for: .weekday, every: cyclePicker.rootView.selected.selectedIndices.compactMap{$0 + 1})
		case 3:
			return .cycle(since: spotDatePicker.date, for: .day, every: cyclePicker.rootView.selected.selectedIndices.compactMap{$0})
		default:
			return nil
		}
	}
	
}
