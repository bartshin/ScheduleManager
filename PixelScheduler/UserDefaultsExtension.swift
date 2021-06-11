//
//  UserDefaultsExtension.swift
//  PixelScheduler
//
//  Created by Shin on 4/17/21.
//

import Foundation

extension UserDefaults {
	
	enum PreferenceKey: String {
		case visualMode
		case colorPalette
		case hapticFeedback
		case collectionBookmark
		case character
		case firstOpen
		case soundEffect
		case icloudBackup
		case premiumPackage
		case dateLanguage
		case calendarPaging
	}
	
	static var appGroup: UserDefaults{
		UserDefaults(suiteName: "group.bartshin.com.github.pxscheduler")!
	}
	
	static func setPreference(for key: PreferenceKey, value: Any) {
		UserDefaults.appGroup.setValue(value, forKey: key.rawValue)
		
	}
	static func getPreference(for key: PreferenceKey) -> String? {
		UserDefaults.appGroup.string(forKey: key.rawValue)
	}
}
