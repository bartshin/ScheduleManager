//
//  ChangingColorButtonStyle.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/02/11.
//

import SwiftUI

struct ChangingColorButtonStyle: ButtonStyle{
	
	let defaultColor: Color
	let activeColor: Color
	let activeBinding: Binding<Bool>?
	
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.foregroundColor(configuration.isPressed || (activeBinding != nil && activeBinding!.wrappedValue) ? activeColor: defaultColor)
	}
}
