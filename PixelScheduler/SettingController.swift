//
//  SettingController.swift
//  ScheduleManager
//
//  Created by Shin on 3/6/21.
//

import Foundation
import SwiftUI

class SettingController: ObservableObject {
    
    private(set) var palette: ColorPalette
    private(set) var visualMode: VisualMode
    private(set) var hapticMode: HapticMode
    private(set) var character: Character
    private(set) var soundEffect: SoundEffect
    private(set) var dateLanguage: DateLanguage
    private(set) var isFirstOpen: Bool
    private(set) var icloudBackup: ICloudBackup
    @Published private(set) var isPurchased: Bool
    private let purchasedUserDefaultKey = "Purchased"
    var collectionBookmark: String?
    
    func changePalette(to newPalette: ColorPalette) {
        self.palette = newPalette
        UserDefaults.setPreference(for: .colorPalette, value: newPalette.rawValue)
    }
    
    func changeVisualMode(to newMode: VisualMode) {
        self.visualMode = newMode
        UserDefaults.setPreference(for: .visualMode, value: newMode.rawValue)
    }
    
    func changeHapticMode(to newMode: HapticMode) {
        self.hapticMode = newMode
        UserDefaults.setPreference(for: .hapticFeedback, value: newMode.rawValue)
    }
    
    func changeSoundEffect(to newMode: SoundEffect) {
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
    
    func changeCharacter(to newCharacter: Character) {
        self.character = newCharacter
        UserDefaults.setPreference(for: .character, value: newCharacter.rawValue)
    }
    
    func changeDateLanguage(to newLanguage: DateLanguage) {
        self.dateLanguage = newLanguage
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
    
    func changeIcloudBackup(to state: ICloudBackup) {
        self.icloudBackup = state
        UserDefaults.setPreference(for: .icloudBackup, value: state.rawValue)
    }
    
    init() {
        if let paletteChosen = UserDefaults.getPreference(for: .colorPalette) {
            self.palette = ColorPalette(rawValue: paletteChosen)!
        }else {
            self.palette = .basic
        }
        if let visualModeChosen = UserDefaults.getPreference(for: .visualMode){
            self.visualMode = VisualMode(rawValue: visualModeChosen)!
        }else {
            self.visualMode = .system
        }
        if let hapticValue = UserDefaults.getPreference(for: .hapticFeedback) {
            self.hapticMode = HapticMode(rawValue: hapticValue)!
        }else {
            self.hapticMode = .strong
        }
        if let soundValue = UserDefaults.getPreference(for: .soundEffect) {
            self.soundEffect = SoundEffect(rawValue: soundValue)!
        }else {
            self.soundEffect = .on
        }
        if let bookmark = UserDefaults.getPreference(for: .collectionBookmark) {
            self.collectionBookmark = bookmark
        }else {
            self.collectionBookmark = nil
        }
        if let dateLanguageSaved = UserDefaults.getPreference(for: .dateLanguage) {
            self.dateLanguage = DateLanguage(rawValue: dateLanguageSaved)!
        }else {
            self.dateLanguage = .korean
        }
        if let characterSaved = UserDefaults.getPreference(for: .character) {
            self.character = Character(rawValue: characterSaved)!
        }else {
            self.character = .soldier
        }
        if let _ = UserDefaults.getPreference(for: .firstOpen) {
            self.isFirstOpen = false
        }else {
            self.isFirstOpen = true
        }
        
        if let backup = UserDefaults.getPreference(for: .icloudBackup) {
            self.icloudBackup = ICloudBackup(rawValue: backup)!
        }else {
            self.icloudBackup = .off
        }
        
        if (UserDefaults.getPreference(for: .premiumPackage) != nil) ||
            UserDefaults.standard.bool(forKey: InAppProducts.product){
            self.isPurchased = true
        }else {
            self.isPurchased = false
        }
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
