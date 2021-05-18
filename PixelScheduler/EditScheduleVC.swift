//
//  EditScheduleVC.swift
//  Schedule_B
//
//  Created by Shin on 2/28/21.
//

import UIKit
import Combine
import CoreLocation
import ContactsUI
import AVFoundation

class EditScheduleVC: UITableViewController, PlaySoundEffect {
    
    // MARK: Controllers
    var settingController: SettingController!
    var modelController: ScheduleModelController!
    private var dateSelectVC: DateSelectVC!
    private var notificationPermissionCancallable: AnyCancellable?
   
    // MARK:- Properties
    var toEdit: Schedule?
    var recievedDate: Date?
    private var currentPermissionStatus: UNAuthorizationStatus? {
        didSet {
            if (currentPermissionStatus! == .denied) {
                scheduleAlarm = .off
                DispatchQueue.runOnlyMainThread { [self] in
                    alarmButton.setImage(nil, for: .disabled)
                    alarmButton.setTitle("No permission", for: .disabled)
                    alarmButton.titleLabel?.adjustsFontSizeToFitWidth = true
                    alarmTimePicker.isEnabled = false
                    alarmButton.isEnabled = false
                }
            }else {
                DispatchQueue.runOnlyMainThread { [self] in
                    alarmTimePicker.isEnabled = true
                    alarmButton.isEnabled = true
                    alarmButton.titleLabel?.adjustsFontSizeToFitWidth = true
                }
            }
        }
    }
    private var currentPriority: Int {
        get {
            priority.selectedSegmentIndex + 1
        }
        set {
            priority.selectedSegmentIndex = newValue - 1
        }
    }
    private var selectedLocation: Schedule.Location?
    var locationState: LocationState = .off {
        didSet{
            locationButton.tintColor = locationState.getColor()
            locationButton.setTitleColor(locationState.getColor(), for: .normal)
            locationButton.layer.borderColor = locationState.getColor().cgColor
            if case let .on(annotation) = locationState {
                locationTitle.text = annotation.title
                locationAddress.text = annotation.subtitle
            }
        }
    }
    private var selectedContact: Schedule.Contact? {
        didSet {
            if selectedContact != nil {
                contactButton.tintColor = .systemBlue
                contactButton.setTitleColor(.systemBlue, for: .normal)
                contactButton.layer.borderColor = UIColor.systemBlue.cgColor
                contactName.text = selectedContact!.name
                contactNumber.text = selectedContact!.phoneNumber.isEmpty ? "연락처 정보가 없습니다" : selectedContact!.phoneNumber
                contactName.isHidden = false
                contactNumber.isHidden = false
            }else {
                contactButton.tintColor = .gray
                contactButton.setTitleColor(.gray, for: .normal)
                contactButton.layer.borderColor = UIColor.gray.cgColor
                contactName.isHidden = true
                contactNumber.isHidden = true
            }
        }
    }
    private var locationObserveCancellable: AnyCancellable?
    var player: AVAudioPlayer!
    
    // MARK: UI properties
    
    private var scheduleAlarm: AlarmState = .off
   
    @IBOutlet private var rootTableview: UITableView!
    @IBOutlet private weak var titleInput: UITextField!
    @IBOutlet private weak var descriptionInput: UITextView!
    
    @IBOutlet private weak var priority: UISegmentedControl!
    @IBOutlet private weak var dateTypeSegment: UISegmentedControl!
    
    @IBOutlet private weak var alarmTimePicker: UIDatePicker!

    @IBOutlet weak var contactName: UILabel!
    @IBOutlet weak var contactNumber: UILabel!
    @IBOutlet private weak var locationTitle: UILabel!
    @IBOutlet private weak var locationAddress: UILabel!
 
    @IBOutlet private weak var alarmButton: UIButton!
    @IBOutlet private weak var locationButton: UIButton!
    @IBOutlet weak var contactButton: UIButton!
    @IBOutlet weak var characterView: CharacterHelper!
    
    // MARK:- User intents
    
    @IBAction private func changeDateSegment(_ sender: UISegmentedControl) {
       changeDateType(segment: sender)
    }
    @IBAction private func turnAlarmButton(_ sender: UIButton) {
        changeAlarm(button: sender, from: scheduleAlarm)
    }
 
    @IBAction private func changePriority(_ sender: UISegmentedControl) {
        let titleDict = [NSAttributedString.Key.foregroundColor: UIColor.byPriority(currentPriority)]
        navigationController?.navigationBar.titleTextAttributes = titleDict
    }
    @objc private func tapCancelButton() {
        if navigationController!.viewControllers.count > 1 {
            navigationController!.popViewController(animated: true)
        }else {
            dismiss(animated: true)
        }
    }
    @objc private func tapAddButton() {
        let message: String
        let generator = UIImpactFeedbackGenerator()
        generator.prepare()
        if let title = titleInput.text,
           !title.isEmpty{
            if let dateType = dateSelectVC.getDatePicked(){
                let alarm = getAlarm(by: dateType)
                let id: UUID? = toEdit?.id
                let newSchedule = Schedule(
                    title: title,
                    description: descriptionInput.text == placeHolderTextView.defaultDescription ? "" : descriptionInput.text,
                    priority: currentPriority,
                    time: dateType,
                    alarm: alarm,
                    with: id,
                    location: selectedLocation,
                    contact: selectedContact)
                playSound(AVAudioPlayer.write)
                generator.generateFeedback(for: settingController.hapticMode)
                if toEdit != nil{
                    if !modelController.replaceSchedule(toEdit!, to: newSchedule, alarmCharacter: settingController.character){
                        print("Fail to replace schedule with alarm \n \(newSchedule)")
                    }
                }else if !modelController.addNewSchedule(newSchedule, alarmCharacter: settingController.character) {
                    print("Fail to add schedule with alarm \n \(newSchedule)")
                }
                if navigationController!.viewControllers.count > 1{
                    navigationController!.popViewController(animated: true)
                }else {
                    dismiss(animated: true)
                }
                return
            }else {
                message = "일정의 기간을 확인해주세요"
            }
        }else {
            message = "제목을 입력해주세요"
        }
        let alertController = UIAlertController(
            title: "새로운 일정 등록 실패",
            message: message,
            preferredStyle: .alert)
        let dissmissAction = UIAlertAction(
            title: "확인", style: .cancel)
        alertController.addAction(dissmissAction)
        alertController.applyColorScheme(settingController.visualMode)
        present(alertController, animated: true)
    }
    @objc private func tapRootView(_ sender: Any) {
        if titleInput.isEditing {
            titleInput.resignFirstResponder()
        }else if let newLineText = descriptionInput as? placeHolderTextView ,
                 newLineText.isEditing{
            newLineText.resignFirstResponder()
        }
        
    }
    @IBAction func tapContactButton(_ sender: UIButton) {
        if selectedContact == nil {
            let contactPicker = CNContactPickerViewController()
            contactPicker.delegate = self
            present(contactPicker, animated: true)
        }else {
            selectedContact = nil
        }
    }
    
    private func getAlarm(by date: Schedule.DateType) -> Schedule.Alarm? {
        switch scheduleAlarm {
        case .on:
            if case .cycle(let startDate, _, _) = date {
                var components = Calendar.current.dateComponents(in: .current, from: startDate)
                components.hour = alarmTimePicker.date.hour
                components.minute = alarmTimePicker.date.minute
                return .periodic(components.date!)
            }else {
                var day: Date?
                if case let .spot(scheduleDate) = date {
                    day = scheduleDate
                }else if case let .period(startDate, _) = date {
                    day = startDate
                }
                var components = Calendar.current.dateComponents(in: .current, from: day!)
                components.hour = alarmTimePicker.date.hour
                components.minute = alarmTimePicker.date.minute
                return .once(components.date!)
            }
        case .off:
            return nil
        }
    }
    
    // MARK:- Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueID.DatePickerSegue.rawValue ,
           let dateSelectVC = segue.destination as? DateSelectVC {
            self.dateSelectVC = dateSelectVC
            dateSelectVC.recievedDate = recievedDate
            dateSelectVC.dateLanguage = settingController.dateLanguage
        }else if segue.identifier == SegueID.ShowLocationSelectorSegue.rawValue ,
                 let locationSeletorVC = segue.destination as? LocationSelectorVC{
            locationSeletorVC.modelController = modelController
            locationSeletorVC.settingController = settingController
            locationSeletorVC.locationTitle = titleInput.text
            locationSeletorVC.priority = currentPriority
            locationObserveCancellable = locationSeletorVC.$presentingAnnotation.sink {
                [weak weakSelf = self] in
                if $0 != nil {
                    let location = Schedule.Location(
                        title: $0!.title ?? "",
                        address: $0!.subtitle ?? "",
                        coordinates: $0!.coordinate)
                    weakSelf?.selectedLocation = location
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        drawButtonBorder()
        checkNotificationPermission()
        titleInput.delegate = self
        characterView.settingController = settingController
        rootTableview.addGestureRecognizer(
            UITapGestureRecognizer(target: self,
                                   action: #selector(tapRootView(_:))))
        if toEdit != nil {
            drawEditingSchedule(toEdit!)
        }
        alarmTimePicker.locale = Locale(identifier: settingController.dateLanguage.locale)
        dateSelectVC.spotDatePicker.addTarget(self, action: #selector(changeAlarmDate(_:)), for: .valueChanged)
        dateSelectVC.startDatePicker.addTarget(self, action: #selector(changeAlarmDate(_:)), for: .valueChanged)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        characterView.load()
        characterView.guide = .editSchedule
        applyColorScheme(settingController.visualMode)
        descriptionInput.textColor = settingController.palette.secondary
        modifyNavigationBar()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        restoreNavigationBar()
    }
    
    private func drawButtonBorder() {
        let buttons: [UIButton] = [alarmButton, locationButton, contactButton]
        buttons.forEach {
            $0.layer.borderColor = .init(gray: 0.5, alpha: 0.8)
            $0.layer.cornerRadius = 10
            $0.layer.borderWidth = 2
        }
    }
    
    @objc private func changeAlarmDate(_ sender: UIDatePicker) {
        alarmTimePicker.date = sender.date
    }
    
    private func modifyNavigationBar() {
        
        navigationItem.title = toEdit == nil ? "New Schedule" : "Edit Schedule"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self,
            action: #selector(tapCancelButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: toEdit == nil ? .add : .done, target: self,
            action: #selector(tapAddButton))
        let titleDict = [NSAttributedString.Key.foregroundColor: UIColor.byPriority(toEdit?.priority ?? 3)]
        navigationController?.navigationBar.titleTextAttributes = titleDict
    }
    private func restoreNavigationBar() {
        let titleDict = [NSAttributedString.Key.foregroundColor: UIColor.black]
        navigationController?.navigationBar.titleTextAttributes = titleDict
    }
    private func checkNotificationPermission() {
        modelController.notificationContoller.requestPermission()
        notificationPermissionCancallable = modelController.notificationContoller.$authorizationStatus.sink{ [self] status in
            currentPermissionStatus = status
        }
    }
    
    private func drawEditingSchedule(_ toEdit: Schedule) {
        navigationItem.title = "Edit Schedule"
        titleInput.text = toEdit.title
        if !toEdit.description.isEmpty {
            descriptionInput.text = toEdit.description
        }
        currentPriority = toEdit.priority
        switch toEdit.time {
        case .spot(let date):
            dateSelectVC.recievedDate = date
            dateTypeSegment.selectedSegmentIndex = 0
        case .period(start: let startDate, end: let endDate):
            dateSelectVC.recievedDate = startDate
            dateSelectVC.recievedEndDate = endDate
            dateTypeSegment.selectedSegmentIndex = 1
        case .cycle(since: let date, for: let factor, every: let values):
            dateSelectVC.recievedDate = date
            dateSelectVC.recievedCycle = (factor, values)
            dateTypeSegment.selectedSegmentIndex = factor == .weekday ? 2 : 3
        }
        changeDateType(segment: dateTypeSegment)
        if toEdit.alarm != nil, toEdit.isAlarmOn {
            changeAlarm(button: alarmButton, from: scheduleAlarm)
            switch toEdit.alarm! {
            case .once(let date):
                alarmTimePicker.date = date
            case .periodic(let date):
                alarmTimePicker.date = date
            }
        }
        if let contact = toEdit.contact {
            selectedContact = contact
        }
        if let location = toEdit.location {
            locationState = .on(annotation:
                                    ScheduleAnnotaion(
                                        title: location.title,
                                        address: location.address,
                                        priority: toEdit.priority,
                                        coordinate: location.coordinates))
            selectedLocation = location
        }
    }
    
    private func changeAlarm(button: UIButton, from state: AlarmState) {
        scheduleAlarm = scheduleAlarm == .on ? .off : .on
        button.tintColor = scheduleAlarm.getColor()
        button.setTitleColor(scheduleAlarm.getColor(), for: .normal)
        alarmButton.layer.borderColor = scheduleAlarm.getColor().cgColor
        alarmTimePicker.isEnabled = scheduleAlarm == .on
    }
    
    private func changeDateType(segment sender: UISegmentedControl) {
        dateSelectVC.viewIndexPresenting = sender.selectedSegmentIndex
    }
    
    enum AlarmState{
        case on
        case off
        func getColor() -> UIColor {
            switch self {
            case .on:
                return .systemPink
            case .off:
                return .lightGray
            }
        }
    }
    enum LocationState{
        case on (annotation: ScheduleAnnotaion)
        case off
        func getColor() -> UIColor {
            switch self {
            case .on:
                return .green
            case .off:
                return .lightGray
            }
        }
    }
    enum SegueID: String {
        case DatePickerSegue
        case ShowLocationSelectorSegue
    }
}

// MARK:- Delegate

extension EditScheduleVC: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}

extension EditScheduleVC: CNContactPickerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let phoneNumber: String
        if let firstNumber = contact.phoneNumbers.first?.value {
            phoneNumber = firstNumber.stringValue
        }else {
            phoneNumber = String()
        }
        selectedContact = .init(
            name: contact.familyName + contact.givenName,
            phoneNumber: phoneNumber,
            contactID: contact.identifier)
    }
}
