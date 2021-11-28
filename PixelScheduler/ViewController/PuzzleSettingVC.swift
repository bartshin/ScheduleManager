//
//  PuzzleSettingVC.swift
//  ScheduleManager
//
//  Created by Shin on 3/31/21.
//

import UIKit

class PuzzleSettingVC: UIViewController {
	
	var settingController: SettingController!
	static let storyboardID = "PuzzleSettingVC"
	@IBOutlet private weak var puzzlePreview: UIImageView!
	@IBOutlet private weak var puzzleImagePicker: UIPickerView!
	@IBOutlet private weak var numRowSelector: UISegmentedControl!
	@IBOutlet private weak var numColumnSelector: UISegmentedControl!
	var selectedBackground: TaskCollection.PuzzleBackground!
	var minimumPuzzlePieces: Int!
	var confirmSetting: (TaskCollection.PuzzleBackground, Int, Int) -> Void = { _,_,_ in }
	
	@IBAction private func tapConfirmButton(_ sender: UIButton) {
		if !selectedBackground.isFree && !settingController.isPurchased {
			showAlertForDismiss(title: "프리미엄 배경화면", message: "선택된 퍼즐배경은 프리미엄 기능입니다, 설정 탭에서 구매해주세요", with: settingController.visualMode)
		}else if (numRowSelector.selectedSegmentIndex + 3) * (numColumnSelector.selectedSegmentIndex + 3) < minimumPuzzlePieces {
			showAlertForDismiss(title: "퍼즐 개수 부족", message: "기존 퍼즐은 최소 \(minimumPuzzlePieces!)개의 조각이 필요합니다", with: settingController.visualMode)
		}else {
			confirmSetting(selectedBackground, numRowSelector.selectedSegmentIndex + 3, numColumnSelector.selectedSegmentIndex + 3)
			dismiss(animated: true)
		}
	}
	@IBAction private func tapCancelButton(_ sender: UIButton) {
		dismiss(animated: true)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		puzzlePreview.image = selectedBackground.image
		puzzleImagePicker.delegate = self
		puzzleImagePicker.dataSource = self
		let index = TaskCollection.PuzzleBackground.allCases.firstIndex(of: selectedBackground)!
		puzzleImagePicker.selectRow(index, inComponent: 0, animated: true)
	}
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		applyColorScheme(settingController.visualMode)
	}
	
	override func updateViewConstraints() {
		self.view.frame.size.height = UIScreen.main.bounds.height / 2
		self.view.frame.origin.y = 150
		self.view.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 10.0)
		super.updateViewConstraints()
	}
}

extension PuzzleSettingVC: UIPickerViewDelegate, UIPickerViewDataSource {
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		1
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		TaskCollection.PuzzleBackground.allCases.count
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		let image = TaskCollection.PuzzleBackground.allCases[row]
		if image.isFree || settingController.isPurchased {
			return image.pickerName
		}else {
			return image.pickerName + " (프리미엄)"
		}
	}
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		selectedBackground = TaskCollection.PuzzleBackground.allCases[row]
		puzzlePreview.image = TaskCollection.PuzzleBackground.allCases[row].image
	}
}

