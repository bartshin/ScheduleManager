//
//  CustomAlertViewController.swift
//  PixelScheduler
//
//  Created by Shin on 3/25/21.
//

import UIKit

class CustomAlertViewController: UIViewController {
	
	let userMessagelabel: UILabel
	let segmentedSwitch: UISegmentedControl?
	var textInputs: [UITextField]
	var alertSize = CGSize(width: 300, height: 150)
	
	init(message: String, segmentSelection: [Any]? = nil, inputPlaceHolders: [String] = []) {
		self.userMessagelabel = UILabel()
		userMessagelabel.text = message
		if let selection = segmentSelection {
			segmentedSwitch = UISegmentedControl(items: selection)
			segmentedSwitch!.selectedSegmentIndex = 0
		}else {
			segmentedSwitch = nil
		}
		textInputs = []
		userMessagelabel.isHidden = true
		userMessagelabel.textColor = .systemPink
		super.init(nibName: nil, bundle: nil)
		view = UIView()
		view.translatesAutoresizingMaskIntoConstraints = false
		inputPlaceHolders.forEach { placeHolder in
			let textInput = UITextField()
			textInput.borderStyle = .roundedRect
			textInput.placeholder = placeHolder
			textInputs.append(textInput)
		}
	}
	
	func drawCustomView(in alert: UIAlertController) {

		alert.view.addSubview(view)
		alert.setValue(self, forKey: "contentViewController")
		view.heightAnchor.constraint(equalToConstant: alertSize.height).isActive = true
		view.widthAnchor.constraint(equalToConstant: alertSize.width).isActive = true
		addItems()
	}
	
	private func addItems() {
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
		([segmentedSwitch] + textInputs).forEach {
			if let view = $0 {
				stackView.addArrangedSubview(view)
				view.translatesAutoresizingMaskIntoConstraints = false
				if view is UITextField {
					view.widthAnchor.constraint(equalTo: view.superview!.widthAnchor).isActive = true
				}
			}
		}
		
		stackView.spacing = 20
		stackView.alignment = .center
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
