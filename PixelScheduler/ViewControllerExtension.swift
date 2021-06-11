//
//  ViewControllerExtension.swift
//  Schedule_B
//
//  Created by Shin on 2/20/21.
//

import UIKit
import AuthenticationServices

extension UIViewController: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
    func applyColorScheme(_ scheme: SettingKey.VisualMode) {
        switch scheme {
        case .dark:
            overrideUserInterfaceStyle = .dark
        case .light:
            overrideUserInterfaceStyle = .light
        case .system:
            overrideUserInterfaceStyle = .unspecified
        }
    }
}
