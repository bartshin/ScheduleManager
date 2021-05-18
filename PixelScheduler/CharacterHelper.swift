//
//  CharacterHelper.swift
//  ScheduleManager
//
//  Created by Shin on 3/31/21.
//

import UIKit
import AVFoundation

class CharacterHelper: UIImageView, PlaySoundEffect {
    
    // MARK: Controller
    var settingController: SettingController!
    
    // MARK:- Properties
    
    var guide: UserGuide!
    
    var player: AVAudioPlayer!
    var showQuikHelpCompletion: (() -> Void)?
    var dismissQuikHelpCompletion: (() -> Void)?
    // MARK:- User intents
    
    @objc func showQuikHelp() {
        guard guide != nil else { return }
        let hapticGenerator = UIImpactFeedbackGenerator()
        hapticGenerator.prepare()
        if let viewcontroller = findViewController(from: self.superview!) ,
           let quikHelpVC = viewcontroller.storyboard?.instantiateViewController(identifier: QuikHelpVC.storyboadID) as? QuikHelpVC {
            
            quikHelpVC.characterLocation = superview!.convert(center, to: superview)
            quikHelpVC.modalTransitionStyle = .crossDissolve
            quikHelpVC.isModalInPresentation = true
            quikHelpVC.settingController = settingController
            quikHelpVC.instructions = guide.instruction
            quikHelpVC.dismissCompletion = dismissQuikHelpCompletion
            viewcontroller.present(quikHelpVC, animated: true) { [weak weakSelf = self] in
                if weakSelf != nil {
                    hapticGenerator.generateFeedback(for: weakSelf!.settingController.hapticMode)
                    weakSelf!.playSound(AVAudioPlayer.quikHelp)
                }
            }
        }
        if let aditionalTask = showQuikHelpCompletion {
            aditionalTask()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(showQuikHelp)))
        
    }
    func load() {
        loadGif(name: settingController.character.idleGif)
    }
    
    func findViewController(from startView: UIView) -> UIViewController? {
        if let nextResponder = startView.next as? UIViewController {
            return nextResponder
        } else if let nextView = startView.next as? UIView {
            return findViewController(from: nextView)
        } else {
            return nil
        }
    }
}
