//
//  WidgetConfig.swift
//  PixelSchedulerWidgetExtension
//
//  Created by Shin on 4/17/21.
//

import SwiftUI

struct UserConfig {
	
	let character: SettingKey.Character
	let palette: SettingKey.ColorPalette
	let dateLanguage: SettingKey.DateLanguage
	
	init() {
		if let storedCharacter = UserDefaults.getPreference(for: .character) {
			self.character = SettingKey.Character(rawValue: storedCharacter)!
		}else {
			self.character = .soldier
		}
		if let storedPalette = UserDefaults.getPreference(for: .colorPalette) {
			self.palette = SettingKey.ColorPalette(rawValue: storedPalette)!
		}else {
			self.palette = .basic
		}
		if let storedLanguage = UserDefaults.getPreference(for: .dateLanguage) {
			self.dateLanguage = SettingKey.DateLanguage(rawValue: storedLanguage)!
		}else {
			self.dateLanguage = .korean
		}
	}
}
