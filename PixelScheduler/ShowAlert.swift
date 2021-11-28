//
//  ShowAlert.swift
//  PixelScheduler
//
//  Created by bart Shin on 12/06/2021.
//

import UIKit

extension UIViewController {
	func showAlertForDismiss(title: String, message: String, with colorSceme: SettingKey.VisualMode) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "확인", style: .default))
		alert.applyColorScheme(colorSceme)
		present(alert, animated: true)
	}
}
