

import UIKit
import Combine
import AVFoundation

class CalendarController: NSObject, PlaySoundEffect {
    
    
    // MARK: Controller
    var settingController: SettingController!
    var modelController: ScheduleModelController!
    
    // MARK:- Properties
    var calendarView: UICollectionView!
    private var observeScheduleCancellable: AnyCancellable?
    private var showDailyViewSegue: (String, Any) -> Void
    private let today = Date()
    var player: AVAudioPlayer!
    let hapticGenerator = UIImpactFeedbackGenerator()
    var yearAndMonth: Int{
        didSet{
            updateCalendar()
        }
    }
    
    var searchRequest = SearchRequest(priority: nil, text: nil) {
        didSet {
            calendarView.reloadData()
        }
    }

    var squaresInCalendarView = [Int?]()
    
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
    
    init(of calendarView: UICollectionView, on yearAndMonth: Int, modelController: ScheduleModelController, settingController: SettingController , segue: @escaping (String, Any) -> Void = { _, _ in}) {
        self.calendarView = calendarView
        self.yearAndMonth = yearAndMonth
        self.modelController = modelController
        self.showDailyViewSegue = segue
        self.settingController = settingController
        super.init()
        calendarView.isScrollEnabled = false
        calendarView.dataSource = self
        calendarView.delegate = self
        observeScheduleCancellable = modelController.objectWillChange.sink{ [self] _ in
            updateCalendar()
        }
    }
}

// MARK:- Collection view delegate
extension CalendarController: CalendarCollectionController {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        squaresInCalendarView.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = calendarView.dequeueReusableCell(
            withReuseIdentifier: CalendarCell.reuseID,
            for: indexPath) as! CalendarCell
        cell = drawCellForCalendar(cell, at: indexPath, calendarView: calendarView, with: settingController.palette)
        if !isEmptyCell(cell) {
            cell.calendarCellView.searchRequest = searchRequest
        }
        if let dateInt = squaresInCalendarView[indexPath.item] {
        cell.calendarCellView.sticker = modelController.stickerTable[dateInt]
        }
        cell.calendarCellHC.view.backgroundColor = .clear
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CalendarCell.size(in: (calendarView.frame.size))
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        hapticGenerator.prepare()
        if let dateToShow = squaresInCalendarView[indexPath.row]{
            showDailyViewSegue(
                ScheduleCalendarViewController.SegueID.ShowDailyViewSegue.rawValue, dateToShow)
            hapticGenerator.generateFeedback(for: settingController.hapticMode)
            playSound(AVAudioPlayer.paper)
        }
    }
    
    struct SearchRequest {
        var priority: Int?
        var text: String?
    }
}
