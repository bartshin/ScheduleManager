//
//  soundEffecter.swift
//  ScheduleManager
//
//  Created by Shin on 3/27/21.
//

import AVFoundation

protocol PlaySoundEffect: AnyObject {
    var player: AVAudioPlayer! { get set }
    var settingController: SettingController! { get }
}

extension PlaySoundEffect {
    
    func playSound(_ soundFile: String) {
        guard settingController.soundEffect == .on,
            let url = Bundle.main.url(forResource: soundFile, withExtension: "wav") else {
            return
        }
        do {
            try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
            player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.5
            player.prepareToPlay()
            player.play()
        }catch {
            print("Fail to play sound \n\(error.localizedDescription)")
        }
    }
    
    
}
extension AVAudioPlayer {
    static let openDrawer = "open_drawer"
    static let closeDrawer = "close_drawer"
    static let paper = "paper"
    static let arrow = "arrow"
    static let puzzleFlip = "puzzle_flip"
    static let quikHelp = "quik_help"
    static let explosion = "explosion"
    static let coin = "coin"
    static let write = "write"
    static let delete = "delete"
}
