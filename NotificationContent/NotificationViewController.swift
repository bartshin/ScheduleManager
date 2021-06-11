//
//  NotificationViewController.swift
//  NotificationContent
//
//  Created by bart Shin on 11/06/2021.
//

import UIKit
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {
	
	private var schedule: Schedule!
	
	@IBOutlet weak var titleIcon: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var contactLabel: UILabel!
	@IBOutlet weak var locationTitle: UILabel!
	@IBOutlet weak var locationAddress: UILabel!
	@IBOutlet weak var scheduleDescription: UITextView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		guard schedule != nil else {
			return
		}
		
	}
	
	func didReceive(_ notification: UNNotification) {
		guard let scheduleDictionary = notification.request.content.userInfo["schedule"] as? [String: Any],
					let data = try? JSONSerialization.data(withJSONObject: scheduleDictionary, options: []),
					let schedule = try? JSONDecoder().decode(Schedule.self, from: data) else {
			return
		}
		self.schedule = schedule
		titleLabel.text = schedule.title
		titleIcon.tintColor = UIColor.byPriority(schedule.priority)
		dateLabel.text = schedule.time.getDescription()
		if let contact = schedule.contact {
			contactLabel.text = contact.name
		}else {
			contactLabel.text = "연락처 없음"
		}
		if let location = schedule.location {
			locationTitle.text = location.title
			locationAddress.text = location.address
		}else {
			locationTitle.text = "장소 없음"
			locationAddress.text = ""
		}
		scheduleDescription.text = schedule.description
	}
}
