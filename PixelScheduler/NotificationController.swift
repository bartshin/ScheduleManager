
import UserNotifications
import AVFoundation

class NotificationController {
    
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined 
    
    func setAlarm(of newSchedule: Schedule, numberOfRepeatForEach: Int = 5, character: SettingController.Character)  {
        guard let alarm = newSchedule.alarm else {
            assertionFailure("Try to set alarm not existing \n \(newSchedule)")
            return
        }
        var datesToAlarm = [Date]()
        
        switch alarm {
        case .once(let date):
            datesToAlarm.append(date)
        case .periodic(let startDate):
            if case .cycle(_, let factor, let values) = newSchedule.time {
                switch factor {
                case .weekday:
                    for weekday in values {
                        var dateToAlarm = startDate.getNext(by: .weekday(weekday))
                        datesToAlarm.append(dateToAlarm)
                        for _ in 0..<numberOfRepeatForEach {
                            dateToAlarm = dateToAlarm.getNext(by: .weekday(weekday))
                            datesToAlarm.append(dateToAlarm)
                        }
                    }
                case .day:
                    for day in values {
                        var dateToAlarm = startDate.getNext(by: .day(day))
                        datesToAlarm.append(dateToAlarm)
                        for _ in 0..<numberOfRepeatForEach {
                            dateToAlarm = dateToAlarm.getNext(by: .day(day))
                            datesToAlarm.append(dateToAlarm)
                        }
                    }
                }
            } else {
                assertionFailure("Try to set periodic alarm of non-cycle schedule \n \(newSchedule)")
                return
            }
        }
        addAlarm(foreach: datesToAlarm, of: newSchedule, character: character)
    }
    
    func removeAlarm(of schedule: Schedule) {
        guard schedule.alarm != nil else {
            assertionFailure("Try to remove alarm for schedule has not alarm \n \(schedule)")
            return
        }
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { notifications in
            var identifiersToRemove = [String]()
            
            for notification in notifications {
                if notification.identifier.hasPrefix(schedule.idForNotification) {
                    identifiersToRemove.append(notification.identifier)
                }
            }
            center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }
    
    func requestPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if error != nil {
                print("Fail to request notification authorization \n \(error!.localizedDescription)")
                return
            }
            
            if granted {
                self.authorizationStatus = .authorized
            }else {
                self.authorizationStatus = .denied
            }
        }
    }
    private func addAlarm(foreach dates: [Date], of schedule: Schedule, character: SettingController.Character) {
        // Check permission
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = schedule.title
        content.body = schedule.description
        content.sound = .init(named: UNNotificationSoundName(rawValue: "coin.wav"))
        content.userInfo["urlString"] = CustomWidgetURL.create(for: .schedule, at: Date(), objectID: schedule.id).absoluteString
        
        var subtitle = String()
        if let contact = schedule.contact {
            subtitle += "-\(contact.name)   "
        }
        if let location = schedule.location {
            subtitle += "-\(location.title)"
        }
        content.subtitle = subtitle
        if let imageURL = URL.localURLForXCAsset(name: "\(character.rawValue)_static"){
            do{
                let alertImage = try UNNotificationAttachment(identifier: "",
                                                              url: imageURL,
                                                              options: nil)
                content.attachments = [ alertImage ]
            }catch {
                assertionFailure("Fail to attach alert image \n \(error.localizedDescription)")
            }
        }else {
            assertionFailure("Fail to create url for \(character)")
        }
        var distinguisher = 0
        
        for timeToNotify in dates {
            let dateComponents = DateComponents(
                calendar: .current,
                timeZone: .current,
                year: timeToNotify.year,
                month: timeToNotify.month,
                day: timeToNotify.day,
                hour: timeToNotify.hour,
                minute: timeToNotify.minute)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: schedule.idForNotification + String(distinguisher),
                content: content,
                trigger: trigger)
            distinguisher += 1
            center.add(request){ error in
                if error != nil {
                    assertionFailure("Error with request notification: \(error!.localizedDescription)")
                }
            }
        }
    }
    
    init() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            self.authorizationStatus = settings.authorizationStatus
        }
    }
}

