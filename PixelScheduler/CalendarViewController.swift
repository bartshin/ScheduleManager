

import UIKit

class CalendarViewController: UIViewController {
	
	// MARK: Controllers
	
	var modelController: ScheduleModelController!
	var settingController: SettingController!
	lazy private var searchController = UISearchController()
	
	private var firstCalendar: MonthlyVC!
	private var secondCalendar: MonthlyVC!
	private var thirdCalendar: MonthlyVC!
	private var pageViewController: UIPageViewController!
	private var currentCalendar: MonthlyVC {
		pageViewController.viewControllers!.first as! MonthlyVC
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
	
	// MARK:- Properties
	
	var selectedDate = Date()
	
//	@IBOutlet weak var characterView: CharacterHelper!
	@IBOutlet weak var titleStackView: UIStackView!
	@IBOutlet private weak var monthLabel: UILabel!
	@IBOutlet private weak var datePickerModal: UIView!
	@IBOutlet weak var navigationBar: UINavigationBar!
	@IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
	@IBOutlet weak var datePickerButton: UIButton!
	@IBOutlet weak var searchButton: UIButton!
	@IBOutlet weak var datePicker: UIDatePicker!
	@IBOutlet weak var weekDayHStack: UIStackView!
	
	
	// MARK:- User intents
	
	@IBAction private func tapSearchButton(_ sender: Any) {
		navigationBar.isHidden = false
	}
	
	@IBAction private func showDatePicker(_ sender: UIButton) {
		if datePickerModal.isHidden {
			self.datePickerModal.isHidden = false
			let blurView = UIVisualEffectView(effect:
																					UIBlurEffect(style: .light))
			blurView.frame = view.bounds
			blurView.alpha = 0.5
			blurView.addGestureRecognizer(
				UITapGestureRecognizer(target: self,
															 action: #selector(hideDatePicker)))
			view.insertSubview(blurView, belowSubview: datePickerModal)
		}
	}
	
	@objc private func hideDatePicker() {
		let blurView = view.subviews.first() { $0 is UIVisualEffectView }
		blurView?.removeFromSuperview()
		datePickerModal.isHidden = true
	}
	@objc private func selectDateInDatePicker(_ sender: UIDatePicker) {
		deliverDateToEachCalendar(sender.date)
		hideDatePicker()
	}
	
	@objc private func deliverDateToEachCalendar(_ dateToDeliver: Date) {
		currentCalendar.yearAndMonth = dateToDeliver.year * 100 + dateToDeliver.month
		prevCalendar.yearAndMonth = (dateToDeliver.aMonthAgo.year * 100) + dateToDeliver.aMonthAgo.month
		nextCalendar.yearAndMonth = (dateToDeliver.aMonthAfter.year * 100) + dateToDeliver.aMonthAfter.month
		updateMonthLabel(with: dateToDeliver)
	}
	
	fileprivate func updateMonthLabel(with date: Date)  {
		let formatter = DateFormatter()
		formatter.locale = Locale(identifier: settingController.language.locale)
		formatter.dateFormat = settingController.language == .english ? "MMM YYYY": "MMM YYYY년"
		monthLabel.text = formatter.string(from: date)
	}
	
	// MARK:- Segue
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == SegueID.NewScheduleSegue.rawValue,
			 let navigationVC = segue.destination as? UINavigationController,
			 let editScheduleVC = navigationVC.visibleViewController as? EditScheduleVC {
			editScheduleVC.modelController = modelController
			editScheduleVC.settingController = settingController
			let now = Date()
			var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
			dateComponents.hour = now.hour
			dateComponents.minute = now.minute
			editScheduleVC.recievedDate = Calendar.current.date(from: dateComponents) ?? selectedDate
			
		}else if segue.identifier == SegueID.ShowDailyViewSegue.rawValue,
						 let navigationVC = segue.destination as? UINavigationController ,
						 let dailyVC = navigationVC.visibleViewController as? DailyViewController,
						 let dateToShow = sender as? Int{
			dailyVC.modelController = modelController
			dailyVC.settingController = settingController
			dailyVC.dateIntShowing = dateToShow
			navigationVC.modalPresentationStyle = .fullScreen
			navigationVC.modalTransitionStyle = .coverVertical
		}
		
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		initCalendars()
		initPageViewcontroller(for: settingController.calendarPaging == .pageCurl ? .pageCurl: .scroll)
//		characterView.settingController = settingController
		updateMonthLabel(with: selectedDate)
		initDatePicker()
		initSearchBar()
	}
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		deliverDateToEachCalendar(selectedDate)
//		characterView.load()
		applyUISetting()
		datePicker.locale = Locale(identifier: settingController.language.locale)
		tabBarController?.applyColorScheme(settingController.visualMode)
	}
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		loadingSpinner.isHidden = true
		if settingController.isFirstOpen {
			
//			characterView.showQuikHelp()
			settingController.firstOpened()
		}
	}
	
	fileprivate func initCalendars() {
		let storyboard = UIStoryboard(name: "Schedule", bundle: nil)
		firstCalendar = storyboard.instantiateViewController(identifier: String(describing: MonthlyVC.self))
		secondCalendar =
			storyboard.instantiateViewController(identifier: String(describing: MonthlyVC.self))
		thirdCalendar =
			storyboard.instantiateViewController(identifier: String(describing: MonthlyVC.self))
		
		[firstCalendar!, secondCalendar!, thirdCalendar!].forEach {
			$0.modelController = modelController
			$0.settingController = settingController
			$0.showDailyViewSegue = { dateInt in
				self.performSegue(withIdentifier: CalendarViewController.SegueID.ShowDailyViewSegue.rawValue, sender: dateInt)
			}
			$0.loadViewIfNeeded()
		}
	}
	
	fileprivate func initPageViewcontroller(for style: UIPageViewController.TransitionStyle) {
		pageViewController = UIPageViewController(transitionStyle: style, navigationOrientation: style == .pageCurl ? .vertical: .horizontal)
		addChild(pageViewController)
		pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
//		view.insertSubview(pageViewController.view, belowSubview: characterView)
		pageViewController.view.topAnchor.constraint(equalTo: weekDayHStack.bottomAnchor).isActive = true
		pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
		pageViewController.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
		pageViewController.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
		
		pageViewController.dataSource = self
		pageViewController.delegate = self
		pageViewController.setViewControllers(
			[secondCalendar],
			direction: .forward, animated: true)
		if let tapGesture = pageViewController.gestureRecognizers.first(where: {
			$0 is UITapGestureRecognizer
		}) {
			pageViewController.view.removeGestureRecognizer(tapGesture)
		}
		
	}
	
	fileprivate func initDatePicker() {
		datePickerModal.layer.borderWidth = 2
		datePickerModal.layer.cornerRadius = 10
		datePicker.date = selectedDate
		datePicker.addTarget(self, action: #selector(selectDateInDatePicker(_:)), for: .valueChanged)
	}
	
	fileprivate func applyUISetting() {
		applyColorScheme(settingController.visualMode)
		switch traitCollection.userInterfaceStyle {
		case .light:
			datePickerModal.backgroundColor = .white
		case .dark:
			datePickerModal.backgroundColor = .darkGray
		default:
			break
		}
		
		datePickerModal.layer.borderColor = settingController.palette.tertiary.cgColor
		monthLabel.textColor = settingController.palette.secondary
		updateMonthLabel(with: selectedDate)
		updateWeekLabels()
		datePickerButton.tintColor = settingController.palette.tertiary
		searchButton.tintColor = settingController.palette.tertiary
		weekDayHStack.backgroundColor = settingController.palette.quaternary
	}
	
	fileprivate func updateWeekLabels() {
		for (index, label) in weekDayHStack.arrangedSubviews.enumerated() {
			let label = label as! UILabel
			label.text = settingController.language == .english ? Calendar.englishWeekDays[index]: Calendar.koreanWeekDays[index]
		}
	}
	
	fileprivate func initSearchBar() {
		searchController.loadViewIfNeeded()
		searchController.searchResultsUpdater = self
		searchController.obscuresBackgroundDuringPresentation = false
		CalendarViewController.configSearchBarUI(searchController.searchBar)
		searchController.searchBar.delegate = self
		definesPresentationContext = true
		let navigationItem = UINavigationItem(title: "")
		navigationItem.titleView = searchController.searchBar
		navigationBar.pushItem(navigationItem, animated: false)
		navigationBar.isHidden = true
	}
	
	static func configSearchBarUI(_ searchBar: UISearchBar) {
		searchBar.enablesReturnKeyAutomatically = false
		searchBar.returnKeyType = .search
		if let searchTextField = searchBar.value(forKey: "searchField") as? UITextField {
			searchTextField.backgroundColor = UIColor(white: 0.9, alpha: 0.5)
			searchTextField.attributedPlaceholder = NSAttributedString(string: searchTextField.placeholder ?? "", attributes: [NSAttributedString.Key.foregroundColor : UIColor.black])
		}
//		searchBar.scopeButtonTitles = ["All"] +  UIColor.Button.allCases.map { $0.rawValue }
		searchBar.showsScopeBar = true
	}
	
	enum SegueID: String {
		case NewScheduleSegue
		case ShowDailyViewSegue
	}
	
	override var prefersHomeIndicatorAutoHidden: Bool {
		true
	}
}

extension CalendarViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
	
	func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
		if completed {
			let dateToShow = Calendar.firstDateOfMonth(currentCalendar.yearAndMonth)
			deliverDateToEachCalendar(dateToShow)
			updateMonthLabel(with: dateToShow)
		}
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
}

extension CalendarViewController: UISearchBarDelegate {
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		clearSearchBar(searchBar)
	}
	
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		guard let searchString = searchBar.text,
					!searchString.isEmpty else {
			return
		}
		clearSearchBar(searchBar)
		let searchVC = CalendarSearchVC(
			searchString: searchString,
			modelController: modelController,
			settingController: settingController)
		searchVC.view.center = view.center
		searchVC.view.frame.size = CGSize(
			width: view.bounds.size.width * 0.9,
			height: view.bounds.size.height * 0.8)
		let navigationController = UINavigationController(rootViewController: searchVC)
		navigationController.definesPresentationContext = false
		present(navigationController, animated: true)
	}
	
	fileprivate func clearSearchBar(_ searchBar: UISearchBar) {
		searchBar.text = nil
//		secondCalendar.searchRequest = .empty
		navigationBar.isHidden = true
		searchController.isActive = false
	}
}

extension CalendarViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		let searchBar = searchController.searchBar
		let searchText = searchBar.text == nil || searchBar.text!.isEmpty ? nil : searchBar.text!
		let priority = searchBar.selectedScopeButtonIndex == 0 ? nil : searchBar.selectedScopeButtonIndex
//		secondCalendar.searchRequest.text = searchText?.lowercased()
//		secondCalendar.searchRequest.priority = priority
	}
}

