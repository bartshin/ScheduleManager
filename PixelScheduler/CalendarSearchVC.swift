//
//  CalendarSearchVC.swift
//  PixelScheduler
//
//  Created by bart Shin on 10/06/2021.
//

import SwiftUI

class CalendarSearchVC: UIViewController {
	
	var settingController: SettingController!
	private let modelController: ScheduleModelController
	private var searchedSchedules: [Schedule]
	private var searchedHolidays: [HolidayGather.Holiday]
	private let searchController: UISearchController
	private var searchString: String {
		didSet {
			title = "\(searchString) 검색 결과"
		}
	}
	private var scheduleFilterPriority: Int? {
		didSet {
			tableView.reloadSections([0], with: .automatic)
		}
	}
	private var filteredSchedules: [Schedule] {
		if let priority = scheduleFilterPriority {
			return searchedSchedules.filter {
				$0.priority == priority
			}
		}else {
			return searchedSchedules
		}
	}
	
	private let tableView: UITableView
	
	//MARK:- User intents
	
	@objc fileprivate func tapCloseButton() {
		dismiss(animated: true)
	}
	
	fileprivate func tapHoliday(_ holiday: HolidayGather.Holiday) {
		guard let dailyVC = UIStoryboard(name: "Schedule", bundle: nil).instantiateViewController(identifier: String(describing: DailyViewController.self)) as? DailyViewController else {
			return
		}
		dailyVC.modelController = modelController
		dailyVC.settingController = settingController
		dailyVC.dateIntShowing = holiday.dateInt
		navigationController?.pushViewController(dailyVC, animated: true)
	}
	
	fileprivate func tapSchedule(_ schedule: Schedule) {
		guard let scheduleVC = UIStoryboard(name: "Schedule", bundle: nil).instantiateViewController(identifier: String(describing: scheduleDetailVC.self)) as? scheduleDetailVC else {
			return
		}
		scheduleVC.settingController = settingController
		scheduleVC.modelController = modelController
		scheduleVC.schedulePresenting = schedule
		scheduleVC.dateIntShowing = findDateInt(for: schedule)
		navigationController?.pushViewController(scheduleVC, animated: true)
	}
	
	fileprivate func findDateInt(for schedule: Schedule) -> Int {
		switch schedule.time {
		case .spot(let date):
			return date.toInt
		case .period(let startDate, let endDate):
			if (startDate.toInt...endDate.toInt).contains(Date().toInt) {
				return Date().toInt
			}else {
				return startDate.toInt
			}
		case .cycle(let referenceDate, let factor, let values):
			let today = Date()
			if referenceDate > today {
				return referenceDate.toInt
			}
			var found: Int?
			values.forEach {
				var current = referenceDate
				while current <= today {
					if current.isSameDay(with: today) {
						found = current.toInt
						break
					}
					current = current.getNext(by: factor == .day ? .day($0): .weekday($0))
				}
			}
			return found ?? referenceDate.toInt
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		initTableView()
		initNavigationBar()
	}
	
	fileprivate func initTableView() {
		tableView.register(ScheduleCell.self, forCellReuseIdentifier: String(describing: ScheduleCell.self))
		tableView.register(HolidayCell.self, forCellReuseIdentifier: String(describing: HolidayCell.self))
		tableView.dataSource = self
		tableView.delegate = self
		tableView.separatorStyle = .none
	}
	
	fileprivate func initNavigationBar() {
		title = "\(searchString) 검색 결과"
		navigationItem.leftBarButtonItem =  .init(title: "닫기", style: .plain, target: self, action: #selector(tapCloseButton))
		navigationItem.searchController = searchController
		searchController.loadViewIfNeeded()
		CalendarViewController.configSearchBarUI(searchController.searchBar)
		searchController.searchBar.delegate = self
	}
	
	fileprivate func query(for searchString: String) {
		searchedSchedules = modelController.querySchedulesTitle(by: searchString)
		if let language = LanguageDetector.detect(for: searchString) {
			searchedHolidays = modelController.queryHoliday(
				by: searchString, for: language)
				.sorted{ lhs, rhs in
					lhs.dateInt < rhs.dateInt
			}
		}else {
			searchedHolidays = []
		}
		tableView.reloadData()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		tableView.frame = view.bounds
		view.addSubview(tableView)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		query(for: searchString)
	}
	
	init(searchString: String,
			 modelController: ScheduleModelController,
			 settingController: SettingController) {
		self.modelController = modelController
		self.settingController = settingController
		self.searchedSchedules = []
		self.searchedHolidays = []
		self.tableView = UITableView()
		self.searchController = UISearchController()
		self.searchString = searchString
		super.init(nibName: nil, bundle: nil)
	}
	
	
	required init?(coder: NSCoder) {
	 fatalError("init(coder:) has not been implemented")
 }

}

extension CalendarSearchVC: UITableViewDelegate, UITableViewDataSource {
	
	func numberOfSections(in tableView: UITableView) -> Int {
		2
	}
	
	func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 0 {
			return "스케쥴"
		}else if section == 1 {
			return "휴일"
		}else {
			return nil
		}
	}
	
	func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		guard let header = view as? UITableViewHeaderFooterView else {
			return
		}
		header.contentView.backgroundColor = settingController.palette.tertiary.withAlphaComponent(0.5)
		header.textLabel?.textColor = settingController.palette.primary
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		30
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
			return max(filteredSchedules.count, 1)
		}else if section == 1 {
			return max(searchedHolidays.count, 1)
		}else {
			return 0
		}
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 0 {
			let selectedSchedule = filteredSchedules[indexPath.row]
			tapSchedule(selectedSchedule)
		} else if indexPath.section == 1 {
			let selectedHoliday = searchedHolidays[indexPath.row]
			tapHoliday(selectedHoliday)
		}
	}
	
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.section == 0, !searchedSchedules.isEmpty {
			return ScheduleCell.cellHeight
		}else if indexPath.section == 1, !searchedHolidays.isEmpty {
			return HolidayCell.cellHeight
		}
		return 40
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell: UITableViewCell
		if indexPath.section == 0, !filteredSchedules.isEmpty {
			let identifier = String(describing: ScheduleCell.self)
			let scheduleCell = tableView.dequeueReusableCell(withIdentifier: identifier) as? ScheduleCell ?? ScheduleCell(style: .default, reuseIdentifier: identifier)
			let schedule = filteredSchedules[indexPath.row]
			scheduleCell.config(schedule: schedule,
									palette: settingController.palette,
									dateLanguage: settingController.dateLanguage, markCompleted: schedule.isDone(for: findDateInt(for: schedule)))
			cell = scheduleCell
		}else if indexPath.section == 1, !searchedHolidays.isEmpty {
			let identifier = String(describing: HolidayCell.self)
			let holidayCell = tableView.dequeueReusableCell(withIdentifier: identifier) as? HolidayCell ?? HolidayCell(style: .default, reuseIdentifier: identifier)
			holidayCell.config(by: searchedHolidays[indexPath.row], palette: settingController.palette, language: settingController.dateLanguage)
			cell = holidayCell
		}else  {
			cell = UITableViewCell(style: .default, reuseIdentifier: nil)
			cell.textLabel?.text = "검색 결과가 없습니다"
			cell.textLabel?.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
			cell.textLabel?.textColor = .gray
		}
		cell.selectionStyle = .none
		return cell
	}
}

extension CalendarSearchVC: UISearchBarDelegate {
	
	
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		guard let searchString = searchBar.text,
					!searchString.isEmpty else {
			return
		}
		self.searchString = searchString
		searchController.isActive = false
		query(for: searchString)
	}
	
	func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
		if selectedScope == 0 {
			scheduleFilterPriority = nil
		}else {
			scheduleFilterPriority = selectedScope
		}
	}
}

fileprivate class ScheduleCell: UITableViewCell {
	
	static let cellHeight: CGFloat = 80
	
	// Swift UI
	private var hoistingController: UIHostingController<DailyScheduleContentsView>?
	private let dateLabel = UILabel()
	private var dateLanguage: SettingKey.DateLanguage!
	private let dateLabelHeight: CGFloat = 20
	private let leftMargin: CGFloat = 10
	
	func config(schedule: Schedule, palette: SettingKey.ColorPalette,
							dateLanguage: SettingKey.DateLanguage, markCompleted: Bool) {
		hoistingController = UIHostingController(rootView: DailyScheduleContentsView(for: schedule, with: palette, watch: nil))
		self.dateLanguage = dateLanguage
		if markCompleted {
			hoistingController?.rootView.isDone = true
		}
		dateLabel.text = schedule.time.getDescription(for: dateLanguage)
		setFrame()
	}
	
	private func setFrame() {
		guard hoistingController != nil else  {
			assertionFailure("Hoisting controller is not set")
			return
		}
		contentView.frame.size.height = ScheduleCell.cellHeight
		contentView.addSubview(dateLabel)
		dateLabel.frame = CGRect(
			origin:
				CGPoint(x: contentView.bounds.origin.x + leftMargin,
								y: contentView.bounds.origin.y),
			size: CGSize(width: contentView.bounds.width - leftMargin,
									 height: dateLabelHeight))
		hoistingController!.view.translatesAutoresizingMaskIntoConstraints = false
		hoistingController!.view.frame = CGRect (
			origin: CGPoint(x: contentView.bounds.origin.x + leftMargin*2,
											y: contentView.bounds.origin.y + dateLabelHeight),
			size: CGSize(width: contentView.bounds.width - leftMargin*2,
									 height: contentView.bounds.height - dateLabelHeight))
		contentView.addSubview(hoistingController!.view)
	}
	
	func chageSchedule(_ schedule: Schedule) {
		hoistingController?.rootView.schedule = schedule
		dateLabel.text = schedule.time.getDescription(for: dateLanguage)
	}
}


fileprivate class HolidayCell: UITableViewCell {
	
	static let cellHeight: CGFloat = 60
	
	private let dateLabel = UILabel()
	private let titleLabel = UILabel()
	private let dateLabelHeight: CGFloat = 20
	private let titleHeight: CGFloat = 40
	private let leftMargin: CGFloat = 10
	var colorPalette: SettingKey.ColorPalette!
	
	func config(by holiday: HolidayGather.Holiday, palette: SettingKey.ColorPalette, language: SettingKey.DateLanguage) {
		guard let date = holiday.dateInt.toDate else {
			assertionFailure("Date of holiday is not convertible \(holiday)")
			return
		}
		colorPalette = palette
		let title: String
		switch language {
		case .english:
			title = holiday.title
		case .korean:
			title = holiday.translateTitle(to: .korean)
		}
		let formatter = DateFormatter()
		formatter.locale = .init(identifier: language.locale)
		formatter.dateFormat = "yy. MM. d (EEEE)"
		dateLabel.text = formatter.string(from: date)
		titleLabel.text = title
//		titleLabel.textColor = UIColor(getFontColor(for: date, with: holiday))
		setFrame()
	}
	
	private func setFrame() {
		contentView.frame.size.height = HolidayCell.cellHeight
		let cellOrigin = contentView.bounds.origin
		let cellWidth = contentView.bounds.width
		dateLabel.frame = CGRect(x: cellOrigin.x + leftMargin,
														 y: cellOrigin.y,
														 width: cellWidth,
														 height: dateLabelHeight)
		titleLabel.frame = CGRect(x: cellOrigin.x + leftMargin*2,
															y: cellOrigin.y + dateLabelHeight,
															width: cellWidth,
															height: titleHeight)
		contentView.addSubview(dateLabel)
		contentView.addSubview(titleLabel)
	}
}
