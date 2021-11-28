//
//  EventDetailVC.swift
//  Schedule_B
//
//  Created by Shin on 3/1/21.
//

import UIKit
import Combine
import MapKit
import ContactsUI
import AVFoundation

class scheduleDetailVC: UIViewController
//, ColorBackground, PlaySoundEffect
{
	
	// MARK: Controller
	var settingController: SettingController!
	var modelController: ScheduleModelController! {
		didSet {
			observeScheduleCancellable = modelController.objectWillChange.sink{
				[self] _ in
				if schedulePresenting != nil {
					schedulePresenting = modelController.getSchedule(by: schedulePresenting!.id)
					drawContent()
				}
			}
		}
	}
	
	var observeScheduleCancellable: AnyCancellable?
	var dateIntShowing: Int!
	
	// MARK:- Properties
	
	var schedulePresenting: Schedule? {
		didSet {
			if oldValue != nil {
				DispatchQueue.runOnlyMainThread {
					self.drawContent()
				}
			}
		}
	}
	
	@IBOutlet private weak var characterBackgroundView: UIImageView!
//	@IBOutlet weak var characterView: CharacterHelper!
	private var animator: UIViewPropertyAnimator!
	private var isCharacterAtLeft: Bool {
//		characterView.center.x < characterBackgroundView.center.x
		true
	}
	@IBOutlet private weak var priorityIcon: UIImageView!
	@IBOutlet weak var openMapButton: UIButton!
	@IBOutlet weak var completeButton: UIButton!
	@IBOutlet weak var alarmButton: UIButton!
	@IBOutlet weak var contactButton: UIButton!
	
	@IBOutlet weak var contactName: UILabel!
	@IBOutlet weak var contactPhoneNumber: UILabel!
	@IBOutlet private weak var alarmDescriptionLabel: UILabel!
	@IBOutlet private weak var titleLabel: UILabel!
	@IBOutlet private weak var dateDescriptionLabel: UILabel!
	@IBOutlet private weak var alarmTypeLabel: UILabel!
	@IBOutlet weak var locationTitleLabel: UILabel!
	@IBOutlet weak var locationAddressLabel: UILabel!
	@IBOutlet weak var completeLabel: UILabel!
	
	@IBOutlet private weak var eventDescription: UITextView!
	
	@IBOutlet weak var bulletinBoard: UIImageView!
	@IBOutlet weak var backgroundView: UIView!
	let gradient = CAGradientLayer()
	let blurEffect = UIBlurEffect()
	let blurEffectView = UIVisualEffectView()
	let hapticGenerator = UIImpactFeedbackGenerator()
	var player: AVAudioPlayer!
	
	// MARK:- User Intents
	
	@objc private func tapEditButton() {
		let message: String
		switch schedulePresenting!.time {
		case .spot(_):
			performSegue(withIdentifier: SegueID.EditScheduleSegue.rawValue, sender: schedulePresenting)
			return
		case .period(start: _, end: _):
			message = "연속되는 일정이 모두 변경됩니다"
		case .cycle(_, for: let factor, _):
			message = factor == .day ? "매월 반복 되는 일정이 한번에 수정됩니다" : "매주 반복 되는 일정이 한번에 수정됩니다"
		}
		let alert = UIAlertController(title: "여러 일정 수정", message: message, preferredStyle: .alert)
		let confirmAction = UIAlertAction(title: "수정", style: .destructive) { [self] _ in
			performSegue(withIdentifier: SegueID.EditScheduleSegue.rawValue, sender: schedulePresenting)
		}
		let cancelAction = UIAlertAction(title: "취소", style: .cancel)
		alert.addAction(confirmAction)
		alert.addAction(cancelAction)
		alert.applyColorScheme(settingController.visualMode)
		present(alert, animated: true)
	}
	
	@IBAction func tapAlarmButton(_ sender: UIButton) {
		hapticGenerator.prepare()
		var newSchedule = schedulePresenting!
		newSchedule.isAlarmOn = !newSchedule.isAlarmOn
		if !modelController.replaceSchedule(schedulePresenting!, to: newSchedule, alarmCharacter: settingController.character) {
			showAlertForDismiss(title: "변경 실패",
													message: "알람 변경을 실패하였습니다 설정에서 권한을 확인해주세요",
													with: settingController.visualMode)
		}
		hapticGenerator.generateFeedback(for: settingController.hapticMode)
	}
	@IBAction func tapContactButton(_ sender: UIButton) {
		guard let contact = schedulePresenting!.contact else { return }
		let contactGather = ContactGather()
		let alertTitle = "연락처 가져오기 실패"
		contactGather.requestPermission { [self] in
			do {
				let results = try contactGather.getContacts(by: [contact.contactID], forImage: false)
				if let firstContact = results.first {
					let contactVC = CNContactViewController(for: firstContact)
					DispatchQueue.runOnlyMainThread {
						contactVC.hidesBottomBarWhenPushed = true
						contactVC.allowsEditing = false
						navigationController?.pushViewController(contactVC, animated: true)
					}
				}else {
					showAlertForDismiss(
						title: alertTitle, message: "연락처를 찾을 수 없습니다", with: settingController.visualMode)
				}
			}catch {
				assertionFailure("Fail to fetch contact \n" + error.localizedDescription)
				showAlertForDismiss(title: alertTitle, message: "데이터 오류로 연락처를 가져오지 못했습니다", with: settingController.visualMode)
			}
		} deniedHandler: { [self] in
			showAlertForDismiss(title: alertTitle,
													message: "설정에서 연락처 권한을 허용해 주세요", with: settingController.visualMode)
		}
	}
	
	@IBAction func tapMapButton(_ sender: UIButton) {
		if let location = schedulePresenting?.location {
			let mapAnnotation = ScheduleAnnotaion(
				title: location.title,
				address: location.address,
				priority: schedulePresenting!.priority,
				coordinate: location.coordinates)
			let launchOptions = [
				MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
			mapAnnotation.mapItem?.openInMaps(launchOptions: launchOptions)
		}
	}
	
	@IBAction func tapDeleteButton(_ sender: UIButton) {
		hapticGenerator.prepare()
		let title: String
		let message: String
		switch schedulePresenting!.time {
		case .spot(_):
			title = "일정 삭제"
			message = "일정을 삭제합니다"
		case .period(_, _):
			title = "연속된 일정 삭제"
			message = "다른 날과 연속되는 일정을 삭제합니다"
		case .cycle(_, for: let factor, _):
			title = "반복되는 일정 삭제"
			message = factor == .day ? "매월 반복되는 일정을 모두 삭제합니다": "매주 반복되는 일정을 모두 삭제합니다"
		}
		
		let alert = UIAlertController(title: title,
																	message: message,
																	preferredStyle: .alert)
		let cancelAction = UIAlertAction(title: "취소", style: .cancel)
		let deleteAction = UIAlertAction(title: "삭제", style: .destructive) {[self] _ in
			modelController.deleteSchedule(schedulePresenting!)
			navigationController?.popViewController(animated: true)
//			playSound(AVAudioPlayer.delete)
		}
		alert.addAction(cancelAction)
		alert.addAction(deleteAction)
		present(alert, animated: true)
		hapticGenerator.generateFeedback(for: settingController.hapticMode)
	}
	
	@IBAction func tapCompleteButton(_ sender: UIButton) {
		guard var newSchedule = schedulePresenting else { return }
		hapticGenerator.prepare()
		newSchedule.toggleIsDone(for: dateIntShowing)
		newSchedule.isAlarmOn = false
		func changeModel() {
			if modelController.replaceSchedule(schedulePresenting!, to: newSchedule, alarmCharacter: settingController.character) {
				schedulePresenting = newSchedule
			}else {
				showAlertForDismiss(title: "변경 실패", message: "스케쥴 완료 상태를 변경하는데 오류가 발생했습니다 나중에 다시 시도해 주세요", with: settingController.visualMode)
				return
			}
		}
		
		if newSchedule.isDone(for: dateIntShowing) {
//			playSound(AVAudioPlayer.coin)
			completeButton.setTitle("완료 취소", for: .normal)
			completeButton.setTitleColor(.gray, for: .normal)
			let transform =  CATransform3DTranslate(CATransform3DIdentity, 0, -50, 0)
			bulletinBoard.layer.transform = transform
			completeLabel.layer.transform = transform
			bulletinBoard.isHidden = false
			
			UIViewPropertyAnimator.runningPropertyAnimator(
				withDuration: 0.6,
				delay: 0,
				options: .curveEaseIn) { [self] in
				bulletinBoard.layer.transform = CATransform3DIdentity
				completeLabel.layer.transform = CATransform3DIdentity
//				characterView.alpha = 0
			} completion: { progress in
				if progress == .end {
					changeModel()
//					self.characterView.isHidden = true
				}
			}
			hapticGenerator.generateFeedback(for: settingController.hapticMode)
		}else {
//			playSound(AVAudioPlayer.closeDrawer)
			completeButton.setTitle("완료", for: .normal)
			completeButton.setTitleColor(.systemGreen, for: .normal)
			let transform =  CATransform3DTranslate(CATransform3DIdentity, 0, -50, 0)
//			characterView.alpha = 0
			completeLabel.isHidden = false
//			characterView.isHidden = false
			UIViewPropertyAnimator.runningPropertyAnimator(
				withDuration: 0.6,
				delay: 0,
				options: .curveEaseIn) { [self] in
				bulletinBoard.layer.transform = transform
				completeLabel.layer.transform = transform
//				characterView.alpha = 1
			} completion: { progress in
				if progress == .end {
					changeModel()
				}
			}
		}
	}
	
	
	// MARK:- Segue
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == SegueID.EditScheduleSegue.rawValue,
			 let editScheduleVC = segue.destination as? EditScheduleVC ,
			 let scheduleToEdit = sender as? Schedule{
			editScheduleVC.modelController = modelController
			editScheduleVC.settingController = settingController
			editScheduleVC.toEdit = scheduleToEdit
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		characterBackgroundView.image = UIImage(named: "background_\(Int.random(in: 1...6))")
//		initBackground()
//		characterView.settingController = settingController
//		characterView.showQuikHelpCompletion = {
//			self.animator.stopAnimation(false)
//		}
//		characterView.dismissQuikHelpCompletion = { [self] in
//			animator.finishAnimation(at: .current)
//			moveCharacter(fromLeft: isCharacterAtLeft)
//		}
		
		navigationItem.rightBarButtonItem = UIBarButtonItem(
			title: "Edit", style: .plain, target: self, action: #selector(tapEditButton))
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
//		characterView.loadGif(name: settingController.character.moveGif)
//		characterView.guide = .scheduleDetail
		moveCharacter(fromLeft: isCharacterAtLeft)
		applyUI()
		drawContent()
//		updateBackground()
	}
	
	private func applyUI() {
		applyColorScheme(settingController.visualMode)
		completeLabel.backgroundColor = settingController.palette.tertiary.withAlphaComponent(0.7)
		completeLabel.textColor = settingController.palette.primary
	}
	
	private func drawContent() {
		guard let event = schedulePresenting else {
			return
		}
		priorityIcon.tintColor = UIColor.byPriority(event.priority)
		titleLabel.textColor = UIColor.byPriority(event.priority)
		titleLabel.text = event.title
		if event.isDone(for: dateIntShowing) {
			completeButton.setTitle("완료 취소", for: .normal)
			completeButton.setTitleColor(.gray, for: .normal)
//			characterView.isHidden = true
		}else {
			completeButton.setTitle("완료", for: .normal)
			completeButton.setTitleColor(.systemGreen, for: .normal)
//			characterView.isHidden = false
		}
		switch event.time {
		case .spot(let date):
			dateDescriptionLabel.text = date.monthDayTimeKoreanString
		case .period(start: let startDate, end: let endDate):
			dateDescriptionLabel.text = "\(startDate.monthDayTimeKoreanString) ~ \(endDate.monthDayTimeKoreanString)"
		case .cycle(_, for: let factor, every: let values):
			switch factor {
			case .day:
				dateDescriptionLabel.text = "매 월 " + values.map {String($0)}.joined(separator: ", ") + " 일"
			case .weekday:
				dateDescriptionLabel.text = "매 주 " + values.map{
					($0 - 1).toKoreanWeekDay! + "요일"
				}.joined(separator: ", ")
			}
		}
		if let contact = event.contact {
			contactButton.isEnabled = true
			contactName.text = contact.name
			contactPhoneNumber.text = contact.phoneNumber
		}else {
			contactButton.isEnabled = false
			contactName.text = "연락처 없음"
			contactPhoneNumber.isHidden = true
		}
		
		if let alarm = event.alarm {
			switch alarm {
			case .once(let date):
				alarmTypeLabel.text = event.isAlarmOn ? "한번 (켜짐)": "한번(꺼짐)"
				alarmDescriptionLabel.text = date.monthDayTimeKoreanString
			case .periodic(let date):
				alarmTypeLabel.text = event.isAlarmOn ? "반복 (켜짐)":
					"반복(꺼짐)"
				alarmDescriptionLabel.text = date.monthDayTimeKoreanString
			}
			alarmButton.tintColor = schedulePresenting!.isAlarmOn ? .systemPink : .gray
		}else {
			alarmTypeLabel.text = "알람 없음"
			alarmDescriptionLabel.text = ""
			alarmButton.isEnabled = false
		}
		if let location = event.location {
			locationTitleLabel.text = location.title
			locationAddressLabel.text = location.address
		}else {
			locationTitleLabel.text = "위치 정보 없음"
			locationAddressLabel.isHidden = true
			openMapButton.isEnabled = false
		}
		
		if event.isDone(for: dateIntShowing){
			completeLabel.isHidden = false
			bulletinBoard.isHidden = false
		}else {
			completeLabel.isHidden = true
			bulletinBoard.isHidden = true
		}
		
		eventDescription.text = event.description.isEmpty ? "상세 내용 없음" : event.description
		
	}
	private func moveCharacter(fromLeft: Bool) {
//		characterView.transform =  CGAffineTransform(
//			scaleX: fromLeft ? 1 : -1, y: 1)
		var destination: CGFloat
		if fromLeft {
			destination = characterBackgroundView.bounds.maxX - 40
		}else {
			destination = characterBackgroundView.bounds.minX + 40
		}
		let animator = UIViewPropertyAnimator(
			duration: 4,
			curve: .easeInOut) {
//			self.characterView.center.x = destination
		}
		
		animator.addCompletion { [self] progress in
			if progress == .end, self == navigationController?.viewControllers.last  {
				moveCharacter(fromLeft: isCharacterAtLeft)
			}
		}
		animator.startAnimation(afterDelay: 1)
		self.animator = animator
	}
	
	enum SegueID: String{
		case EditScheduleSegue
	}
}
