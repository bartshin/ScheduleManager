//
//  HolidayDictionary.swift
//  PixelScheduler
//
//  Created by bart Shin on 09/06/2021.
//

import Foundation

struct HolidayDictionay {
	
	typealias English = String
	typealias Korean = String
	
	static func engToKor(from english: English) -> Korean? {
		guard let index = englishHolidays.firstIndex(of: english) else {
			return nil
		}
		return koreanHolidays[index]
	}
	
	static func korToEng(from korean: Korean) -> English? {
		guard let index = koreanHolidays.firstIndex(of: korean) else {
			return nil
		}
		return englishHolidays[index]
	}
	
	static var englishHolidaysWithOutSpace: [English] {
		englishHolidays.compactMap {
			$0.replacingOccurrences(of: " ", with: "").lowercased()
		}
	}
	
	static var koreanHolidaysWithOutSpace: [Korean] {
		koreanHolidays.compactMap {
			$0.replacingOccurrences(of: " ", with: "")
		}
	}
	
	static let englishHolidays: [English] = [
		"New Year's Day",
		"Seollal Holiday",
		"Seollal",
		"Valentine's Day",
		"Independence Movement Day",
		"March Equinox",
		"Arbor Day",
		"Labor Day",
		"Children's Day",
		"Parents' Day",
		"Teacher's Day",
		"Buddha's Birthday",
		"Memorial Day",
		"June Solstice",
		"Constitution Day",
		"Liberation Day",
		"Chuseok Holiday",
		"Chuseok",
		"September Equinox",
		"Armed Forces Day",
		"National Foundation Day",
		"Hangeul Proclamation Day",
		"Halloween",
		"December Solstice",
		"Christmas Eve",
		"Christmas Day",
		"New Year's Eve"
	]
	
	static let koreanHolidays: [Korean] = [
		"신정",
		"설날 연휴",
		"설날",
		"발렌타인 데이",
		"삼일절",
		"춘분",
		"식목일",
		"근로자의 날",
		"어린이날",
		"어버이날",
		"스승의날",
		"석가탄신일",
		"현충일",
		"하지",
		"제헌절",
		"광복절",
		"추석 연휴",
		"추석",
		"추분",
		"국군의 날",
		"개천절",
		"한글날",
		"할로윈 데이",
		"동지",
		"크리스마스 이브",
		"크리스마스",
		"섣달 그믐날"
	]
}
