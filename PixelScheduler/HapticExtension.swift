//
//  HapticExtension.swift
//  ScheduleManager
//
//  Created by Shin on 3/25/21.
//

import UIKit

extension UIImpactFeedbackGenerator {
    func generateFeedback(for mode: SettingKey.HapticMode) {
        switch mode {
        case .off:
            break
        case .weak:
            impactOccurred(intensity: 0.7)
        case .strong:
            impactOccurred(intensity: 1)
        }
        
    }
}
