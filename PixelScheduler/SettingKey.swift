//
//  SettingKey.swift
//  PixelScheduler
//
//  Created by bart Shin on 09/06/2021.
//

import UIKit

struct SettingKey {
	
	enum CalendarPaging: String {
		case pageCurl
		case scroll
	}
	
	enum ICloudBackup: String {
		case on
		case off
	}
	
	enum PremiumPackage: String {
		case purchased
		case notPurchased
	}
	
	enum SoundEffect: String {
		case on
		case off
	}
	
	enum DateLanguage: String {
		case korean
		case english
		
		var locale: String {
			switch self {
			case .english:
				return "en_US"
			case .korean:
				return "ko_KR"
			}
		}
	}
	
	enum VisualMode: String {
		case system
		case light
		case dark
	}
	enum HapticMode: String {
		case off
		case weak
		case strong
	}
	enum Character: String, CaseIterable {
		case princess
		case soldier
		case dragon
		case wizard
		case gargoyle
		case goblin
		case barbarian
		
		var isFree: Bool {
			switch self {
			case .soldier, .princess, .dragon:
				return true
			default:
				return false
			}
		}
		
		var koreanName: String {
			switch self {
			case .barbarian:
				return "원시인"
			case .dragon:
				return "드래곤"
			case .gargoyle:
				return "가고일"
			case .goblin:
				return "고블린"
			case .princess:
				return "공주"
			case .soldier:
				return "기사"
			case .wizard:
				return "마법사"
			}
		}
		
		var magicGif: String? {
			switch self {
			case .dragon:
				return "dragon_fire"
			case .wizard:
				return ["iceball", "fireball"].randomElement()!
			default:
				return nil
			}
		}
		var arrowImage: UIImage {
			return UIImage(named: ["arrow_wooden", "arrow_gold"].randomElement()!)!
		}
		
		var attackGif: String {
			self.rawValue + "_attack"
		}
		
		var staticImage: UIImage {
			UIImage(named: self.rawValue + "_static")!
		}
		var moveGif: String {
			self.rawValue + "_move"
		}
		var idleGif: String {
			self.rawValue + "_idle"
		}
	}
	
	enum ColorPalette: String, CaseIterable {
		case basic
		case vivid
		case vintage
		case cool
		case pastel
		case coffee
		case forest
		case mint
		case lemonade
		
		var allColors: [UIColor] {
			[primary, secondary, tertiary, quaternary]
		}
		
		var primary: UIColor {
			UIColor(named: "\(self.rawValue)-primary")!
		}
		var secondary: UIColor {
			UIColor(named: "\(self.rawValue)-secondary")!
		}
		var tertiary: UIColor {
			UIColor(named: "\(self.rawValue)-tertiary")!
		}
		var quaternary: UIColor {
			UIColor(named: "\(self.rawValue)-quaternary")!
		}
		
		var isFree: Bool {
			switch self {
			case .basic, .cool, .vintage, .vivid:
				return true
			default:
				return false
			}
		}
	}
}
