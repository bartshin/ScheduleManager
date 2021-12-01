//
//  LanguageDetector.swift
//  PixelScheduler
//
//  Created by bart Shin on 09/06/2021.
//

import NaturalLanguage

struct LanguageDetector {
	
	static func detect(for string: String) -> SettingKey.Language? {
		let recognizer = NLLanguageRecognizer()
		recognizer.processString(string)
		guard let languageCode = recognizer.dominantLanguage?.rawValue,
					let detectedLanguage = Locale.current.localizedString(forIdentifier: languageCode) else {
			return nil
		}
		return SettingKey.Language(rawValue: detectedLanguage.lowercased())
	}
}
