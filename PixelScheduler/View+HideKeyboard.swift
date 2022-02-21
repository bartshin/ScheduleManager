//
//  View+HideKeyboard.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/02/21.
//

import SwiftUI

extension View {
	func hideKeyboard() {
		UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
	}
}
