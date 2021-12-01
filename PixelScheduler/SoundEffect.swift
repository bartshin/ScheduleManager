//
//  soundEffecter.swift
//  ScheduleManager
//
//  Created by Shin on 3/27/21.
//

import AVFoundation

class SoundEffect {
    private static var player: AVAudioPlayer?
	
    static func playSound(_ sound: Sounds) {
		guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else {
            return
        }
        do {
            try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
            player = try AVAudioPlayer(contentsOf: url)
            player!.volume = 0.5
            player!.prepareToPlay()
            player!.play()
        }catch {
            print("Fail to play sound \n\(error.localizedDescription)")
        }
    }
    
    
	enum Sounds: String {
		case openDrawer = "open_drawer"
		case closeDrawer = "close_drawer"
		case paper = "paper"
		case arrow = "arrow"
		case puzzleFlip = "puzzle_flip"
		case quikHelp = "quik_help"
		case explosion = "explosion"
		case coin = "coin"
		case write = "write"
		case delete = "delete"
	}
}
