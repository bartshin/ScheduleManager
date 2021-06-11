//
//  CustomAlertViewController.swift
//  ScheduleManager
//
//  Created by Shin on 3/25/21.
//

import UIKit

class CustomAlertViewController: UIViewController {
	
	let userMessagelabel: UILabel
	let segmentedSwitch: UISegmentedControl?
	let textInput: UITextField?
	var alertHeight: CGFloat = 150
	
	override func loadView() {
		
		view = UIView()
		let stackView = UIStackView()
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.axis = .vertical
		view.addSubview(stackView)
		NSLayoutConstraint.activate([
			stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
		])
		userMessagelabel.translatesAutoresizingMaskIntoConstraints = false
		stackView.addArrangedSubview(userMessagelabel)
		[segmentedSwitch, textInput].forEach {
			if let view = $0 {
				stackView.addArrangedSubview(view)
				view.translatesAutoresizingMaskIntoConstraints = false
			}
		}
		stackView.spacing = 20
		stackView.alignment = .center
	}
	func drawCustomView(in alert: UIAlertController) {
		alert.setValue(self, forKey: "contentViewController")
		view.heightAnchor.constraint(equalToConstant: alertHeight).isActive = true
	}
	
	init(message: String, segmentSelection: [Any]? = nil, inputPlaceHolder: String? = nil) {
		self.userMessagelabel = UILabel()
		userMessagelabel.text = message
		if let selection = segmentSelection {
			segmentedSwitch = UISegmentedControl(items: selection)
			segmentedSwitch!.selectedSegmentIndex = 0
		}else {
			segmentedSwitch = nil
		}
		if let placeHolder = inputPlaceHolder {
			textInput = UITextField()
			textInput!.borderStyle = .roundedRect
			textInput!.placeholder = placeHolder
		}else {
			textInput = nil
		}
		userMessagelabel.isHidden = true
		userMessagelabel.textColor = .systemPink
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
