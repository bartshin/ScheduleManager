//
//  WidgetConfig.swift
//  PixelSchedulerWidgetExtension
//
//  Created by Shin on 4/17/21.
//

import SwiftUI

struct UserConfig {
    
    let character: Character
    let palette: ColorPalette
    
    
    enum Character: String, CaseIterable {
        case princess
        case soldier
        case dragon
        case wizard
        case gargoyle
        case goblin
        case barbarian
        
        var image: UIImage {
            UIImage(named: self.rawValue + "_static")!
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
    }
    
    init() {
        if let storedCharacter = UserDefaults.getPreference(for: .character) {
            self.character = Character(rawValue: storedCharacter)!
        }else {
            self.character = .soldier
        }
        if let storedPalette = UserDefaults.getPreference(for: .colorPalette) {
            self.palette = ColorPalette(rawValue: storedPalette)!
        }else {
            self.palette = .basic
        }
    }
}
