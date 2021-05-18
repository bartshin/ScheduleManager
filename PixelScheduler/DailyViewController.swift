//
//  DailyViewController.swift
//  Schedule_B
//
//  Created by Shin on 2/24/21.
//

import UIKit
import Combine

class DailyViewController: UIViewController {
    
    //MARK: Controllers
    var modelController: ScheduleModelController!
    var settingController: SettingController!
    private(set) var topVC: WeeklyScheduleVC!
    private(set) var bottomVC: DailyScrollVC!
    
    //MARK:- Properties
    
    @IBOutlet weak var characterView: CharacterHelper!
    @Published var dateIntShowing: Int? {
        didSet {
            navigationItem.title = dateShowing.getMonthDayString(with: settingController.dateLanguage.locale)
            self.stickerShowing = modelController.stickerTable[dateIntShowing!]
            if holiydayLabel != nil, holiydayBoard != nil {
                updateHoliyday()
            }
        }
    }
    var observeTopViewCancellable: AnyCancellable?
    private var stickerShowing: Sticker? {
        didSet {
            stickerButton?.setBackgroundImage(stickerShowing?.image ?? UIImage(named: "sticker_icon")!, for: .normal)
        }
    }
    
    var dateShowing: Date {
        dateIntShowing!.toDate!
    }
    @IBOutlet weak var holiydayLabel: UILabel!
    @IBOutlet weak var holiydayBoard: UIImageView!
    @IBOutlet weak var stickerButton: UIButton!
    
    // MARK:- User intents
    
    @objc private func tapBackButton() {
        dismiss(animated: true)
    }
    
    @IBAction func tapStickerButton(_ sender: UIButton) {
        let alert = UIAlertController(title: "스티커 선택", message: nil, preferredStyle: .actionSheet)
        let selectorVC = storyboard?.instantiateViewController(identifier: "StickerSelectVC") as! StickerSelectVC
        selectorVC.drawCustomView(in: alert)
        selectorVC.palette = settingController.palette
        if let selectedSticker = stickerShowing {
            selectorVC.selectedSticker = selectedSticker
        }
        alert.addAction(UIAlertAction(title: "선택", style: .default,  handler: { [self] _ in
            alert.dismiss(animated: true)
            stickerShowing = modelController.setSticker(selectorVC.selectedSticker, to: dateIntShowing!)
        }))
        alert.addAction(UIAlertAction(title: "지우기", style: .destructive, handler: { [self] _ in
            alert.dismiss(animated: true)
            stickerShowing = modelController.setSticker(nil, to: dateIntShowing!)
        }))
        present(alert, animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        characterView.settingController = settingController
        navigationItem.setLeftBarButton(
            UIBarButtonItem(title: "Back",
                            style: .plain,
                            target: self,
                            action: #selector(tapBackButton)),
            animated: false)
        updateHoliyday()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        characterView.load()
        characterView.guide = .weeklyCalendar
        modifyNavigationBar()
        applyUISetting()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let tabBarController = presentingViewController as? UITabBarController,
           let calendarVC = tabBarController.viewControllers!.first(where: { $0 is ScheduleCalendarViewController}) as? ScheduleCalendarViewController {
            calendarVC.selectedDate = dateShowing
        }
    }
    
    private func modifyNavigationBar() {
        navigationController?.navigationBar.barTintColor = settingController.palette.tertiary
        let titleDict = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = titleDict
        navigationController?.navigationBar.tintColor = .white
    }
    
    private func applyUISetting() {
        applyColorScheme(settingController.visualMode)
        holiydayLabel.backgroundColor = settingController.palette.tertiary.withAlphaComponent(0.7)
        holiydayLabel.textColor = settingController.palette.primary
    }
    
    private func updateHoliyday() {
        if let holiday = modelController.holidayTable[dateIntShowing!] {
            holiydayLabel.isHidden = false
            holiydayLabel.text = " \(holiday.title) "
            holiydayBoard.isHidden = false
        }else {
            holiydayBoard.isHidden = true
            holiydayLabel.isHidden = true
        }
    }
    
    // MARK:- Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueID.TopViewControllerSegue.rawValue{
            topVC = (segue.destination as! WeeklyScheduleVC)
            topVC.modelController = modelController
            topVC.settingController = settingController
            topVC.dateIntChosen = dateIntShowing
            observeTopViewCancellable = topVC.$dateIntChosen.sink { [self] in
                self.dateIntShowing = $0
            }
        }else if segue.identifier == SegueID.BottomViewControllerSegue.rawValue {
            bottomVC = (segue.destination as! DailyScrollVC)
            bottomVC.modelController = modelController
            bottomVC.settingController = settingController
            bottomVC.dateIntShowing = dateIntShowing
            bottomVC.observeTopViewCancellable = $dateIntShowing.sink {
                self.bottomVC.dateIntShowing = $0
            }
        }else if segue.identifier == SegueID.NewScheduleSegue.rawValue,
                 let editScheduleVC = segue.destination as? EditScheduleVC {
            editScheduleVC.modelController = modelController
            editScheduleVC.settingController = settingController
            editScheduleVC.recievedDate = dateShowing
        }else if segue.identifier == SegueID.WidgetSegue.rawValue,
                 let id = sender as? UUID,
                 let detailVC = segue.destination as? scheduleDetailVC {
            detailVC.modelController = modelController
            detailVC.settingController = settingController
            detailVC.schedulePresenting = modelController.getSchedule(by: id)
            detailVC.dateIntShowing = dateIntShowing!
        }
    }
    
    enum SegueID: String {
        case TopViewControllerSegue
        case BottomViewControllerSegue
        case NewScheduleSegue
        case WidgetSegue
    }
}
