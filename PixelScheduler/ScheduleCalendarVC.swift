

import UIKit

class ScheduleCalendarViewController: UIViewController, ColorBackground {
  
    // MARK: Controllers
    
    var modelController: ScheduleModelController!
    var settingController: SettingController!
    lazy private var searchController = UISearchController()
    private var currentCalendarVC: CalendarController!
    private var prevCalendarVC: CalendarController!
    private var nextCalendarVC: CalendarController!
    
    // MARK:- Properties
    
    @IBOutlet weak var characterView: CharacterHelper!
    @IBOutlet weak var titleStackView: UIStackView!
    @IBOutlet private weak var monthLabel: UILabel!
    @IBOutlet private weak var nextCalendarView: UICollectionView!
    @IBOutlet private weak var currentCalendarView: UICollectionView!
    @IBOutlet private weak var prevCalendarView: UICollectionView!
    @IBOutlet private weak var scrollCalendarView: UIScrollView!
    @IBOutlet private weak var datePickerModal: UIView!
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var datePickerButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var weekDayHStack: UIStackView!
    var selectedDate = Date()
    private let today = Date()
    let gradient = CAGradientLayer()
    let blurEffect = UIBlurEffect()
    @IBOutlet weak var backgroundView: UIView!
    let blurEffectView = UIVisualEffectView()
    
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
        currentCalendarVC.yearAndMonth = (dateToDeliver.year * 100) + dateToDeliver.month
        prevCalendarVC.yearAndMonth = (dateToDeliver.aMonthAgo.year * 100) + dateToDeliver.aMonthAgo.month
        nextCalendarVC.yearAndMonth = (dateToDeliver.aMonthAfter.year * 100) + dateToDeliver.aMonthAfter.month
        updateMonthLabel(with: dateToDeliver)
    }
    
    private func updateMonthLabel(with date: Date)  {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: settingController.dateLanguage.locale)
        formatter.dateFormat = settingController.dateLanguage == .english ? "MMM YYYY": "MMM YYYY년"
        monthLabel.text = formatter.string(from: date)
    }
    
    // MARK:- Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueID.NewScheduleSegue.rawValue,
           let navigationVC = segue.destination as? UINavigationController,
           let editScheduleVC = navigationVC.visibleViewController as? EditScheduleVC {
            editScheduleVC.modelController = modelController
            editScheduleVC.settingController = settingController
            editScheduleVC.recievedDate = selectedDate
            
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
        scrollCalendarView.delegate = self
        initCalendarControllers()
        characterView.settingController = settingController
        updateMonthLabel(with: today)
        initDatePicker()
        initSearchBar()
        initBackground()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollCalendarView.scrollToChild(currentCalendarView)
        characterView.load()
        applyUISetting()
        datePicker.locale = Locale(identifier: settingController.dateLanguage.locale)
        updateBackground()
        tabBarController?.applyColorScheme(settingController.visualMode)
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollCalendarView.scrollToChild(currentCalendarView)
        deliverDateToEachCalendar(selectedDate)
        loadingSpinner.isHidden = true
        if settingController.isFirstOpen {
            characterView.guide = .firstOpen
            characterView.showQuikHelp()
            settingController.firstOpened()
        }
        characterView.guide = .monthlyCalendar
    }
    
    private func initCalendarControllers() {
        currentCalendarVC =  CalendarController(
            of: currentCalendarView,
            on: today.toInt / 100,
            modelController: modelController,
            settingController: settingController,
            segue: performSegue(withIdentifier:sender:))
        prevCalendarVC = CalendarController(
            of: prevCalendarView,
            on: today.toInt / 100,
            modelController: modelController,
            settingController: settingController,
            segue: performSegue(withIdentifier:sender:))
        nextCalendarVC = CalendarController(
            of: nextCalendarView,
            on: today.toInt / 100,
            modelController: modelController,
            settingController: settingController,
            segue: performSegue(withIdentifier:sender:))
        currentCalendarVC.updateCalendar()
    }
    
    private func initDatePicker() {
        datePickerModal.layer.borderWidth = 2
        datePickerModal.layer.cornerRadius = 10
        datePicker.date = selectedDate
        datePicker.addTarget(self, action: #selector(selectDateInDatePicker(_:)), for: .valueChanged)
    }
    private func applyUISetting() {
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
    
    private func updateWeekLabels() {
        for (index, label) in weekDayHStack.arrangedSubviews.enumerated() {
            let label = label as! UILabel
            label.text = settingController.dateLanguage == .english ? Calendar.englishWeekDays[index]: Calendar.koreanWeekDays[index]
        }
    }
    
    private func initSearchBar() {
        searchController.loadViewIfNeeded()
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.enablesReturnKeyAutomatically = false
        searchController.searchBar.returnKeyType = .search
        if let searchTextField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            searchTextField.backgroundColor = UIColor(white: 0.9, alpha: 0.5)
            searchTextField.attributedPlaceholder = NSAttributedString(string: searchTextField.placeholder ?? "", attributes: [NSAttributedString.Key.foregroundColor : UIColor.black])
        }
        definesPresentationContext = true
        searchController.searchBar.scopeButtonTitles = ["All"] +  UIColor.Button.allCases.map { $0.rawValue }
        searchController.searchBar.delegate = self
        searchController.searchBar.showsCancelButton = true
        let navigationItem = UINavigationItem(title: "")
        navigationItem.titleView = searchController.searchBar
        searchController.searchBar.showsScopeBar = true
        navigationBar.pushItem(navigationItem, animated: false)
        navigationBar.isHidden = true
    }
    
    enum SegueID: String {
        case NewScheduleSegue
        case ShowDailyViewSegue
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }

}

// MARK:- Scroll view delegate
extension ScheduleCalendarViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.x > 30 && scrollView.contentOffset.x < 780 {
            return
        }
        let firstDate = scrollView.contentOffset.x < 30 ?  Calendar.firstDateOfMonth(prevCalendarVC.yearAndMonth) :
            Calendar.firstDateOfMonth(nextCalendarVC.yearAndMonth)

        currentCalendarVC.yearAndMonth = (firstDate.year * 100) + firstDate.month
        prevCalendarVC.yearAndMonth = (firstDate.aMonthAgo.year * 100) + firstDate.aMonthAgo.month
        nextCalendarVC.yearAndMonth = (firstDate.aMonthAfter.year * 100) + firstDate.aMonthAfter.month
        updateMonthLabel(with: firstDate)
        scrollView.scrollToChild(currentCalendarView)
    }
}

// MARK:- Search bar delegate
extension ScheduleCalendarViewController: UISearchBarDelegate {
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        navigationBar.isHidden = true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        navigationBar.isHidden = true
    }
}

// MARK:- Search result handling
extension ScheduleCalendarViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        let searchText = searchBar.text == nil || searchBar.text!.isEmpty ? nil : searchBar.text!
        let priority = searchBar.selectedScopeButtonIndex == 0 ? nil : searchBar.selectedScopeButtonIndex
        currentCalendarVC.searchRequest.text = searchText?.lowercased()
        currentCalendarVC.searchRequest.priority = priority
    }
}
