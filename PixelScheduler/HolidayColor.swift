//
//  HolidayColor.swift
//  PixelScheduler
//
//  Created by bart Shin on 09/06/2021.
//

import SwiftUI

protocol HolidayColor {
	var colorPalette: SettingKey.ColorPalette! { get }
}

extension HolidayColor {
	func getFontColor(for date: Date, with holiday: HolidayGather.Holiday?) -> Color {
		if holiday != nil {
			if date.weekDay == 1 || holiday!.type == .national {
				return Color.red
			}else if date.weekDay == 7 {
				return Color.blue
			}else {
				return Color(colorPalette.tertiary)
			}
		}else {
			if date.weekDay == 1 {
				return Color.pink
			}else if date.weekDay == 7 {
				return Color.blue
			}else {
				return Color(colorPalette.primary)
			}
		}
	}
}
