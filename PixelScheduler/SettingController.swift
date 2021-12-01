//
//  SettingController.swift
//  ScheduleManager
//
//  Created by Shin on 3/6/21.
//

import Foundation
import SwiftUI

class SettingController: ObservableObject {
	
	private(set) var palette: SettingKey.ColorPalette
	private(set) var visualMode: SettingKey.VisualMode
	private(set) var hapticMode: SettingKey.HapticMode
	private(set) var character: SettingKey.Character
	private(set) var soundEffect: SettingKey.SoundEffect
	private(set) var language: SettingKey.Language
	private(set) var isFirstOpen: Bool
	private(set) var icloudBackup: SettingKey.ICloudBackup
	private(set) var calendarPaging: SettingKey.CalendarPaging
	@Published private(set) var isPurchased: Bool
	private let purchasedUserDefaultKey = "Purchased"
	var collectionBookmark: String?
	
	func changePalette(to newPalette: SettingKey.ColorPalette) {
		self.palette = newPalette
		UserDefaults.setPreference(for: .colorPalette, value: newPalette.rawValue)
	}
	
	func changeVisualMode(to newMode: SettingKey.VisualMode) {
		self.visualMode = newMode
		UserDefaults.setPreference(for: .visualMode, value: newMode.rawValue)
	}
	
	func changeHapticMode(to newMode: SettingKey.HapticMode) {
		self.hapticMode = newMode
		UserDefaults.setPreference(for: .hapticFeedback, value: newMode.rawValue)
	}
	
	func changeSoundEffect(to newMode: SettingKey.SoundEffect) {
		self.soundEffect = newMode
		UserDefaults.setPreference(for: .soundEffect, value: newMode.rawValue)
	}
	
	func saveCollectionBookmark() -> String? {
		if let title = collectionBookmark {
			UserDefaults.setPreference(for: .collectionBookmark, value: title)
			return title
		}else {
			return nil
		}
	}
	
	func changeCharacter(to newCharacter: SettingKey.Character) {
		self.character = newCharacter
		UserDefaults.setPreference(for: .character, value: newCharacter.rawValue)
	}
	
	func changeDateLanguage(to newLanguage: SettingKey.Language) {
		self.language = newLanguage
		UserDefaults.setPreference(for: .dateLanguage, value: newLanguage.rawValue)
	}
	
	func firstOpened() {
		self.isFirstOpen = false
		UserDefaults.setPreference(for: .firstOpen, value: "Not first")
	}
	
	func observePurchase() {
		NotificationCenter.default.addObserver(
			self, selector: #selector(confirmPurchase), name: .IAPHelperPurchaseNotification, object: nil)
	}
	
	@objc private func confirmPurchase() {
		self.isPurchased = true
		UserDefaults.setPreference(for: .premiumPackage, value: "Purchased")
	}
	
	func changeIcloudBackup(to state: SettingKey.ICloudBackup) {
		self.icloudBackup = state
		UserDefaults.setPreference(for: .icloudBackup, value: state.rawValue)
	}
	
	func changeCalendarPaging(to pagingStytle: SettingKey.CalendarPaging) {
		self.calendarPaging = pagingStytle
		UserDefaults.setPreference(for: .calendarPaging, value: pagingStytle.rawValue)
	}
	
	init() {
		if let paletteChosen = UserDefaults.getPreference(for: .colorPalette) {
			self.palette = SettingKey.ColorPalette(rawValue: paletteChosen)!
		}else {
			self.palette = .basic
		}
		if let visualModeChosen = UserDefaults.getPreference(for: .visualMode){
			self.visualMode = SettingKey.VisualMode(rawValue: visualModeChosen)!
		}else {
			self.visualMode = .system
		}
		if let hapticValue = UserDefaults.getPreference(for: .hapticFeedback) {
			self.hapticMode = SettingKey.HapticMode(rawValue: hapticValue)!
		}else {
			self.hapticMode = .strong
		}
		if let soundValue = UserDefaults.getPreference(for: .soundEffect) {
			self.soundEffect = SettingKey.SoundEffect(rawValue: soundValue)!
		}else {
			self.soundEffect = .on
		}
		if let bookmark = UserDefaults.getPreference(for: .collectionBookmark) {
			self.collectionBookmark = bookmark
		}else {
			self.collectionBookmark = nil
		}
		if let dateLanguageSaved = UserDefaults.getPreference(for: .dateLanguage) {
			self.language = SettingKey.Language(rawValue: dateLanguageSaved)!
		}else {
			self.language = .korean
		}
		if let characterSaved = UserDefaults.getPreference(for: .character) {
			self.character = SettingKey.Character(rawValue: characterSaved)!
		}else {
			self.character = .soldier
		}
		if let _ = UserDefaults.getPreference(for: .firstOpen) {
			self.isFirstOpen = false
		}else {
			self.isFirstOpen = true
		}
		
		if let backup = UserDefaults.getPreference(for: .icloudBackup) {
			self.icloudBackup = SettingKey.ICloudBackup(rawValue: backup)!
		}else {
			self.icloudBackup = .off
		}
		
		if (UserDefaults.getPreference(for: .premiumPackage) != nil) ||
				UserDefaults.standard.bool(forKey: InAppProducts.product){
			self.isPurchased = true
		}else {
			self.isPurchased = false
		}
		
		if let paging = UserDefaults.getPreference(for: .calendarPaging) {
			self.calendarPaging = SettingKey.CalendarPaging(rawValue: paging)!
		}else {
			self.calendarPaging = .pageCurl
		}
//		self.calendarPaging = .scroll
	}
	
}
