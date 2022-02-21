//
//  ConnectAppleCalendarVC.swift
//  FancyScheduler
//
//  Created by Shin on 4/7/21.
//

import UIKit
import EventKit
import Combine
import AVFoundation

class ConnectAppleCalendarVC: UIViewController
//, PlaySoundEffect
{
    
    // MARK: Controllers
    var settingController: SettingController!
    var scheduleModelController: ScheduleModelController!
    var calendarGather: AppleCalendarGather!
    private let eventListController = ExternalCalendarEventListController()
    private let contactGather = ContactGather()
    private var fetchEventCancellable: AnyCancellable?
    
    // MARK:- Properties
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var totalEventNumberLabel: UILabel!
    @IBOutlet weak var calendarPicker: UIPickerView!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    var player: AVAudioPlayer!
    
    // MARK:- User intents
    
    @IBAction func turnSwitch(_ sender: UISwitch) {
        eventListController.changeGroupInclusion(to: sender.isOn)
    }
    @IBAction func tapSaveButton(_ sender: UIButton) {
        let generator = UIImpactFeedbackGenerator()
        generator.prepare()
        loadingSpinner.isHidden = false
        guard scheduleModelController.importSchedules(
                eventListController.schedulesToImport, alarmCharacter: settingController.character) else {
            loadingSpinner.isHidden = true
            let alertController = UIAlertController(
                title: "등록되지 않은 일정이 있습니다",
                message: "일부 일정은 알람이 등록되지 않았습니다 알림 설정을 켜주세요", preferredStyle: .alert)
            let dismissAction = UIAlertAction(
                title: "확인", style: .cancel) {_ in
                self.navigationController?.popViewController(animated: true)
            }
            alertController.applyColorScheme(settingController.visualMode)
            alertController.addAction(dismissAction)
            present(alertController, animated: true)
            return
        }
        loadingSpinner.isHidden = true
        generator.generateFeedback(for: settingController.hapticMode)
//        playSound(AVAudioPlayer.coin)
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        eventListController.tableView = tableView
        calendarGather.getCalendars()
        calendarPicker.delegate = self
        calendarPicker.dataSource = self
        
        calendarGather.getEvents(baseOn: Date())
        tableView.delegate = eventListController
        tableView.dataSource = eventListController
        fetchEventCancellable = calendarGather.$events.sink { [self] ekEvents in
            contactGather.requestPermission {
                eventListController.events = ekEvents.compactMap{ events in
                    self.convertEventToSchedule(from: events, withContact: true)
                }
            } deniedHandler: {
                eventListController.events = ekEvents.compactMap{ events in
                    self.convertEventToSchedule(from: events, withContact: false)
                }
            }
            totalEventNumberLabel.text = ekEvents.isEmpty ? "" : String(ekEvents.count) + "개의 이벤트"
        }
        
        
    }
    
    private func convertEventToSchedule(from event: EKEvent, withContact: Bool) -> Schedule {
        var description = "Information from Apple calendar \n"
        if let location = event.location {
            description += "location: \(location) \n"
        }
        if let url = event.url, !url.absoluteString.isEmpty {
            description += "url: \(url.absoluteString) \n"
        }
        if let creation = event.creationDate {
            description += "created at: \(creation.dayShortString) \n"
        }
        if let lastModified = event.lastModifiedDate {
            description += "last modified at: \(lastModified.dayShortString)"
        }
        if event.status == .canceled {
            description += "canceled event"
        }
        var alarm: Schedule.Alarm? = nil
        if event.hasAlarms,
					 event.alarms?.first != nil{
            let timeOffset = event.alarms![0].relativeOffset
            let alarmDate = event.startDate + timeOffset
            alarm = .once(alarmDate)
        }
        let contact: Schedule.Contact?
        if let contactID = event.birthdayContactIdentifier, withContact {
            if let firstContact = try? contactGather.getContacts(by: [contactID], forImage: false).first {
                let phoneNumber: String
                if let firstNumber = firstContact.phoneNumbers.first?.value {
                    phoneNumber = firstNumber.stringValue
                }else {
                    phoneNumber = String()
                }
                contact = .init(
                    name: firstContact.familyName+firstContact.givenName,
                    phoneNumber: phoneNumber, contactID: firstContact.identifier)
            }else {
                contact = nil
            }
        }else {
            contact = nil
        }
        
        return Schedule(
            title: event.title,
            description: description,
            priority: 5,
            time: .period(start: event.startDate, end: event.endDate),
            alarm: alarm,
            storeAt: .appleCalendar(uid: event.calendarItemIdentifier),
            location: nil,
            contact: contact)
    }
}

extension ConnectAppleCalendarVC: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        calendarGather.allCalendars.count + 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 {
            return "All"
        }else {
            return calendarGather.allCalendars[row - 1].title
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let calendar: EKCalendar?
        if row == 0 {
            calendar = nil
        }else {
            calendar = calendarGather.allCalendars[row - 1]
        }
        
        calendarGather.getEvents(baseOn: Date(), for: calendar)
    }
}
