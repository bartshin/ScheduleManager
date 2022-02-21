//
//  ColorBackgroundProtocol.swift
//  PixelScheduler
//
//  Created by Shin on 3/26/21.
//

import UIKit

protocol ColorBackground: UIViewController {
    var settingController: SettingController { get set }
    var gradient: CAGradientLayer { get }
    var blurEffect: UIBlurEffect { get }
    var blurEffectView: UIVisualEffectView { get }
    var backgroundView: UIView! { get }
}

extension ColorBackground {
    
     func updateBackground() {
        let blurEffect: UIBlurEffect
        if traitCollection.userInterfaceStyle == .light {
            gradient.colors = [settingController.palette.tertiary.withAlphaComponent(0.1).cgColor, settingController.palette.tertiary.withAlphaComponent(0.5).cgColor]
            blurEffect = UIBlurEffect(style: .extraLight)
        }else {
            gradient.colors = [
                settingController.palette.tertiary.withAlphaComponent(0.5).cgColor, settingController.palette.tertiary.withAlphaComponent(1).cgColor
            ]
            blurEffect = UIBlurEffect(style: .dark)
        }
        blurEffectView.effect = blurEffect
    }
    func initBackground() {
		
        // Set the size of the layer to be equal to size of the display.
        gradient.frame = view.bounds
        blurEffectView.frame = view.bounds
        
        // Rasterize this static layer to improve app performance.
        gradient.shouldRasterize = true
        // Apply the gradient to the backgroundGradientView.
        backgroundView.layer.addSublayer(gradient)
        backgroundView.addSubview(blurEffectView)
    }
}
