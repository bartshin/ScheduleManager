//
//  SettingViewController.swift
//  Schedule_B
//
//  Created by Shin on 2/17/21.
//

import UIKit
import AuthenticationServices
import AVFoundation

class SettingViewController: UITableViewController, PlaySoundEffect {
	
	// MARK:- Controller
	var scheduleModelController: ScheduleModelController!
	var taskModelController: TaskModelController!
	var settingController: SettingController!
	
	// MARK:- Properties
	
	@IBOutlet private weak var deleteScheduleDataCell: UITableViewCell!
	@IBOutlet private weak var connectGoogleCalendarCell: UITableViewCell!
	@IBOutlet weak var deleteTaskDataCell: UITableViewCell!
	@IBOutlet weak var connectAppleCalendarCell: UITableViewCell!
	@IBOutlet weak var purchaseCell: UITableViewCell!
	@IBOutlet weak var copyrightCell: UITableViewCell!
	@IBOutlet weak var changeCharacterCell: UITableViewCell!
	
	@IBOutlet weak var visualModeSelector: UISegmentedControl!
	@IBOutlet weak var hapticSelector: UISegmentedControl!
	@IBOutlet weak var soundEffectSelector: UISegmentedControl!
	@IBOutlet weak var labelLanguageSelector: UISegmentedControl!
	@IBOutlet weak var icloudBackupSelector: UISegmentedControl!
	@IBOutlet weak var calendarPagingSelector: UISegmentedControl!
	
	@IBOutlet weak var colorPicker: UIPickerView!
	@IBOutlet weak var palettePreview: UILabel!
	@IBOutlet weak var purchasedLabel: UILabel!
	@IBOutlet weak var purchaseButton: UILabel!
	@IBOutlet weak var dateLanguageLabel: UILabel!
	
	@IBOutlet weak var chracterPreview: UIImageView!
	let hapticGenerator = UIImpactFeedbackGenerator()
	var player: AVAudioPlayer!
	
	
	// MARK:- User intents
	
	@objc private func selectVisualMode(sender: UISegmentedControl) {
		let selectedMode: SettingKey.VisualMode
		switch sender.selectedSegmentIndex {
		case 1:
			selectedMode = .dark
		case 2:
			selectedMode = .light
		default:
			selectedMode = .system
		}
		settingController.changeVisualMode(to: selectedMode)
		applyUISetting()
		updatePalettePreview(with: settingController.palette)
	}
	
	@IBAction func selectSoundEffect(_ sender: UISegmentedControl) {
		settingController.changeSoundEffect(to: sender.selectedSegmentIndex == 0 ? .on : .off)
		if sender.selectedSegmentIndex == 0 {
			playSound(AVAudioPlayer.coin)
		}
	}
	
	@IBAction func selectCalendarPaging(_ sender: UISegmentedControl) {
		settingController.changeCalendarPaging(to: sender.selectedSegmentIndex == 0 ? .pageCurl: .scroll)
		let alert = UIAlertController(title: "페이징 변경", message: "변경된 내용은 재시작 후에 적용됩니다", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "확인", style: .default))
		present(alert, animated: true)
	}
	@objc private func selectHapticMode(sender: UISegmentedControl) {
		hapticGenerator.prepare()
		let selectedMode: SettingKey.HapticMode
		switch sender.selectedSegmentIndex {
		case 0:
			selectedMode = .weak
		case 1:
			selectedMode = .strong
		default :
			selectedMode = .off
		}
		settingController.changeHapticMode(to: selectedMode)
		hapticGenerator.generateFeedback(for: settingController.hapticMode)
	}
	
	@IBAction func selectDateLanguage(_ sender: UISegmentedControl) {
		let selectedLanguage: SettingKey.DateLanguage
		switch sender.selectedSegmentIndex {
		case 0:
			selectedLanguage = .korean
		case 1:
			selectedLanguage = .english
		default:
			selectedLanguage = .korean
		}
		dateLanguageLabel.text = selectedLanguage == .english ? "캘린더 언어": "Date language"
		settingController.changeDateLanguage(to: selectedLanguage)
	}
	
	@IBAction func selectIcloudBackup(_ sender: UISegmentedControl) {
		let newState: SettingKey.ICloudBackup = sender.selectedSegmentIndex == 0 ? .on : .off
		settingController.changeIcloudBackup(to: newState)
		if newState == .on {
			func errorHandler(_ error: Error) {
				let alert = UIAlertController(title: "데이터 복원 실패", message: error.localizedDescription, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "확인",
																			style: .default))
				present(alert, animated: true)
			}
			let alert = UIAlertController(
				title: "데이터 복원",
				message: "복원을 선택하면 데이터를 가져와 현재 데이터를 대체합니다, 덮어쓰기를 선택하면 새로운 데이터가 아이클라우드에 저장됩니다 ", preferredStyle: .alert)
			let retrieveAction = UIAlertAction(title: "복원", style: .default) { [self] _ in
				do {
					try scheduleModelController.restoreBackup()
					try taskModelController.restoreBackup()
				}catch {
					print("Fail load backup from icloud \n \(error.localizedDescription)")
					errorHandler(error)
				}
			}
			let overwriteAction = UIAlertAction(title: "덮어쓰기", style: .destructive) { [self] _ in
				do {
					try scheduleModelController.backup()
					try taskModelController.backup()
				}catch  {
					print("Fail store backup to icloud \n \(error.localizedDescription)")
					errorHandler(error)
				}
			}
			alert.addAction(retrieveAction)
			alert.addAction(overwriteAction)
			present(alert, animated: true)
		}
	}
	
	@objc private func tapConnectAppleCalendar() {
		let appleCalendarGather = AppleCalendarGather()
		
		appleCalendarGather.requestPermission {
			DispatchQueue.runOnlyMainThread {
				self.performSegue(withIdentifier: SegueID.ConnectAppleCalendarSegue.rawValue, sender: appleCalendarGather)
			}
		} deniedHandler: { [self] in
			DispatchQueue.runOnlyMainThread {
				let alert = UIAlertController(
					title: "데이터 가져오기 실패",
					message: "설정에서 사용자의 캘린더 접근을 허용해주세요", preferredStyle: .alert)
				let dismissAction = UIAlertAction(
					title: "확인",
					style: .default)
				alert.addAction(dismissAction)
				present(alert, animated: true)
			}
		}
	}
	
	@objc private func tapConnectGoogleCalendar() {
		performSegue(withIdentifier: SegueID.ConnectGoogleCalendarSegue.rawValue, sender: nil)
	}
	
	@objc private func tapChangeCharacter() {
		performSegue(withIdentifier: SegueID.ChangeCharacterSegue.rawValue, sender: nil)
	}
	
	@objc private func tapDeleteScheduleDataCell() {
		let alertController = UIAlertController(
			title: "스케쥴 삭제",
			message: "모든 스케쥴이 삭제됩니다",
			preferredStyle: .alert)
		alertController.addAction(
			UIAlertAction(title: "취소", style: .cancel))
		alertController.addAction(UIAlertAction(
			title: "지우기",
			style: .destructive) {_ in
			if !self.scheduleModelController.removeAllSchedule() {
				// Fail to remove
				let alertController = UIAlertController(title: "삭제 실패",
																								message: "유저 데이터를 지우는데 실패하였습니다",
																								preferredStyle: .alert)
				alertController.addAction(
					UIAlertAction(title: "확인",
												style: .cancel))
				self.present(alertController, animated: true)
			}
		})
		alertController.applyColorScheme(settingController.visualMode)
		present(alertController, animated: true)
	}
	
	@objc private func tapDeleteTaskDataCell() {
		let alertController = UIAlertController(
			title: "작업 목록 삭제",
			message: "모든 컬렉션과 작업이 삭제됩니다",
			preferredStyle: .alert)
		alertController.addAction(
			UIAlertAction(title: "취소", style: .cancel))
		alertController.addAction(UIAlertAction(
			title: "지우기",
			style: .destructive) {_ in
			if !self.taskModelController.removeAllTaskData(){
				// Fail to remove
				let alertController = UIAlertController(title: "삭제 실패",
																								message: "유저 데이터를 지우는데 실패하였습니다",
																								preferredStyle: .alert)
				alertController.addAction(
					UIAlertAction(title: "확인",
												style: .cancel))
				self.present(alertController, animated: true)
			}
		})
		alertController.applyColorScheme(settingController.visualMode)
		present(alertController, animated: true)
	}
	
	@objc func tapCopyrightCell() {
		performSegue(withIdentifier: SegueID.ShowCopyrightSegue.rawValue, sender: nil)
	}
	
	@objc func tapPurchaseCell() {
		performSegue(withIdentifier: SegueID.PurchaseSegue.rawValue, sender: nil)
	}
	
	// MARK:- Segue
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == SegueID.ConnectGoogleCalendarSegue.rawValue,
			 let connectGoogleCalendarVC = segue.destination as? ConnectGoogleCalendarVC{
			connectGoogleCalendarVC.scheduleModelController = scheduleModelController
			connectGoogleCalendarVC.settingController = settingController
			connectGoogleCalendarVC.modalPresentationStyle = .fullScreen
		}else if segue.identifier == SegueID.ChangeCharacterSegue.rawValue,
						 let changeCharacterVC = segue.destination as? SelectCharacterVC {
			changeCharacterVC.settingController = settingController
		}else if segue.identifier == SegueID.ConnectAppleCalendarSegue.rawValue,
						 let connectAppleCalendarVC = segue.destination as? ConnectAppleCalendarVC,
						 let gather = sender as? AppleCalendarGather{
			connectAppleCalendarVC.scheduleModelController = scheduleModelController
			connectAppleCalendarVC.calendarGather = gather
			connectAppleCalendarVC.settingController = settingController
		}else if segue.identifier == SegueID.PurchaseSegue.rawValue ,
						 let purchaseVC = segue.destination as? InAppPurchaseVC{
			purchaseVC.settingController = settingController
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		deleteScheduleDataCell.addGestureRecognizer(
			UITapGestureRecognizer(target: self, action: #selector(tapDeleteScheduleDataCell)))
		deleteTaskDataCell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapDeleteTaskDataCell)))
		connectAppleCalendarCell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapConnectAppleCalendar)))
		connectGoogleCalendarCell.addGestureRecognizer(
			UITapGestureRecognizer(
				target: self, action: #selector(tapConnectGoogleCalendar)))
		changeCharacterCell.addGestureRecognizer(
			UITapGestureRecognizer(
				target: self, action: #selector(tapChangeCharacter)))
		purchaseCell.addGestureRecognizer(
			UITapGestureRecognizer(
				target: self, action: #selector(tapPurchaseCell)))
		copyrightCell.addGestureRecognizer(
			UITapGestureRecognizer(
				target: self, action: #selector(tapCopyrightCell)))
		dateLanguageLabel.text = settingController.dateLanguage == .english ? "캘린더 언어": "Date language"
		initSelectors()
	}
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		let colorIndex =  SettingKey.ColorPalette.allCases.firstIndex(of: settingController.palette)!
		colorPicker.selectRow(colorIndex, inComponent: 0, animated: false)
		updatePalettePreview(with: settingController.palette)
		applyUISetting()
		chracterPreview.loadGif(name: settingController.character.idleGif)
		if settingController.isPurchased {
			purchasedLabel.isHidden = false
			purchaseButton.isHidden = true
		}else {
			purchasedLabel.isHidden = true
			purchaseButton.isHidden = false
		}
	}
	
	private func applyUISetting() {
		applyColorScheme(settingController.visualMode)
		tabBarController?.applyColorScheme(settingController.visualMode)
	}
	private func updatePalettePreview(with palette: SettingKey.ColorPalette) {
		palettePreview.text?.removeAll()
		var paletteImage = UIImage(systemName: "paintpalette")!
		if traitCollection.userInterfaceStyle == .dark {
			paletteImage = paletteImage.withTintColor(.white)
		}
		let attributeString = NSMutableAttributedString()
		attributeString.append(paletteImage.toAttributeText)
		palette.allColors.forEach { color in
			attributeString.append(
				UIImage(systemName: "paintbrush.fill")!
					.withTintColor(color)
					.toAttributeText)
		}
		attributeString.addAttribute(.font, value: UIFont.systemFont(ofSize: 50), range: NSRange(location: 0, length: attributeString.string.count))
		palettePreview.attributedText = attributeString
	}
	private func initSelectors() {
		switch settingController.visualMode {
		case .system:
			visualModeSelector.selectedSegmentIndex = 0
		case .dark:
			visualModeSelector.selectedSegmentIndex = 1
		case .light:
			visualModeSelector.selectedSegmentIndex = 2
		}
		switch settingController.hapticMode {
		case .weak:
			hapticSelector.selectedSegmentIndex = 0
		case .strong:
			hapticSelector.selectedSegmentIndex = 1
		case .off:
			hapticSelector.selectedSegmentIndex = 2
		}
		soundEffectSelector.selectedSegmentIndex = settingController.soundEffect == .on ? 0: 1
		icloudBackupSelector.selectedSegmentIndex = settingController.icloudBackup == .on ? 0: 1
		labelLanguageSelector.selectedSegmentIndex =  settingController.dateLanguage == .korean ? 0: 1
		calendarPagingSelector.selectedSegmentIndex =
			settingController.calendarPaging == .pageCurl ? 0: 1
		visualModeSelector.addTarget(self, action: #selector(selectVisualMode(sender:)), for: .valueChanged)
		hapticSelector.addTarget(self, action: #selector(selectHapticMode(sender:)), for: .valueChanged)
		colorPicker.dataSource = self
		colorPicker.delegate = self
	}
	
	enum SegueID: String{
		case ConnectGoogleCalendarSegue
		case ChangeCharacterSegue
		case ShowCopyrightSegue
		case PurchaseSegue
		case ConnectAppleCalendarSegue
	}
}

extension SettingViewController: UIPickerViewDelegate, UIPickerViewDataSource {
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		1
	}
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		SettingKey.ColorPalette.allCases.count
	}
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		let pickedPalette = SettingKey.ColorPalette.allCases[row]
		if pickedPalette.isFree || settingController.isPurchased {
			return pickedPalette.rawValue
		}else {
			return pickedPalette.rawValue + " (프리미엄)"
		}
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		let pickedPalette = SettingKey.ColorPalette.allCases[row]
		updatePalettePreview(with: pickedPalette)
		if pickedPalette.isFree || settingController.isPurchased {
			settingController.changePalette(to: pickedPalette)
		}
	}
}
