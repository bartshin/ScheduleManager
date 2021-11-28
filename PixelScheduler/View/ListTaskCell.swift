//
//  TaskCell.swift
//  ScheduleManager
//
//  Created by Shin on 3/27/21.
//

import UIKit
import AVFoundation

class ListTaskCell: UITableViewCell
//, PlaySoundEffect
{
	
	var player: AVAudioPlayer!
	var settingController: SettingController!
	
	// MARK:- Properties
	
	var task: Task? {
		didSet {
			if task != nil {
				updateUI()
			}
		}
	}
	@IBOutlet private(set) weak var titleLabel: PaddingLabel!
	@IBOutlet private weak var groundTile: TileView!
	@IBOutlet weak var backgroundObjectRight: UIImageView!
	@IBOutlet weak var backgroundObjectLeft: UIImageView!
	@IBOutlet weak var distanceObjectLeft: NSLayoutConstraint!
	@IBOutlet weak var distanceObjectRight: NSLayoutConstraint!
	
	@IBOutlet private weak var objectView: UIImageView!
	@IBOutlet private weak var characterView: UIImageView!
	@IBOutlet private weak var reward: UIImageView!
	@IBOutlet private weak var distantCharterObject: NSLayoutConstraint!
	
	
	var character: SettingKey.Character!
	private var colorAttachment: String {
		switch task!.priority {
		case 1:
			return "_red"
		case 2:
			return "_orange"
		case 3:
			return "_yellow"
		case 4:
			return "_green"
		case 5:
			return "_blue"
		default:
			return ""
		}
	}
	
	// MARK:- User Intents
	
	func spawnCharacter(taskHandler: @escaping (Task) -> Void) {
		guard task != nil else {
			print("Can't find task \n \(self)")
			return
		}
//		playSound(character.rawValue)
		switch character {
		// Melee character
		case .barbarian, .gargoyle, .princess, .soldier:
			moveToObject { [self] in
				destroyObject(attack: true) {
					spawnCoin (with: {
						characterView.layer.transform = CATransform3DTranslate(CATransform3DIdentity, 200, 0, 0)
					} ,taskHandler: taskHandler)
				}
			}
		// Range character
		case .dragon, .goblin, .wizard:
			fireGun { [self] in
				reward.isHidden = true
				destroyObject(attack: false) {
					spawnCoin(with: {
						characterView.layer.transform = CATransform3DTranslate(CATransform3DIdentity, -400, 0, 0)
						
					}, taskHandler: taskHandler)
				}
			}
			
		default:
			break
		}
	}
	
	private func fireGun(afterHit nextAnimation: @escaping () -> Void) {
		distantCharterObject.constant = bounds.width / 2
		characterView.loadGif(name: character.attackGif)
		characterView.isHidden = false
		characterView.animationRepeatCount = 1
		let firstAnimator = UIViewPropertyAnimator(
			duration: 1,
			curve: .easeIn) { [self] in
			characterView.layer.transform = CATransform3DTranslate(CATransform3DIdentity, 10, 0, 0)
		}
		firstAnimator.addCompletion { [self] progress in
			if progress == .end {
				characterView.loadGif(name: character.moveGif)
				if character == .wizard || character == .dragon {
					reward.loadGif(name: character.magicGif!)
				}else if character == .goblin {
					reward.image = character.arrowImage
				}
				reward.isHidden = false
				reward.layer.transform = CATransform3DTranslate(CATransform3DIdentity, -200, 0, 0)
				let secondAnimator = UIViewPropertyAnimator(
					duration: 0.5,
					curve: .linear) { [weak weakSelf = self] in
					if weakSelf != nil {
						weakSelf!.reward.layer.transform = CATransform3DIdentity
					}
				}
				secondAnimator.addCompletion { progress in
					if progress == .end {
						nextAnimation()
					}
				}
				secondAnimator.startAnimation()
			}
		}
		firstAnimator.startAnimation()
	}
	
	private func moveToObject(then nextAnimation: @escaping () -> Void) {
		distantCharterObject.constant = 0
		characterView.loadGif(name: character.moveGif)
		characterView.isHidden = false
		characterView.layer.transform = CATransform3DTranslate(CATransform3DIdentity, -200, 0, 0)
		
		UIViewPropertyAnimator.runningPropertyAnimator(
			withDuration: 2,
			delay: 0,
			options: .curveEaseIn) { [self] in
			characterView.layer.transform = CATransform3DIdentity
		} completion: {  [weak weakSelf = self] progress in
			if progress == .end {
				if weakSelf != nil {
					nextAnimation()
				}
			}
		}
	}
	
	private func destroyObject(attack: Bool, then nextAnimation: @escaping () -> Void) {
		if attack {
			characterView.loadGif(name: character.attackGif)
			characterView.animationRepeatCount = 1
		}
//		playSound(AVAudioPlayer.explosion)
		objectView.loadGif(name: "explosion")
		objectView.animationRepeatCount = 1
		UIViewPropertyAnimator.runningPropertyAnimator(
			withDuration: 0.8,
			delay: 0.3,
			options: .curveLinear) { [weak weakSelf = self] in
			weakSelf?.objectView.alpha = 0
		} completion: { progress in
			if progress == .end {
				nextAnimation()
			}
		}
	}
	
	private func spawnCoin(with syncAnimation: @escaping () -> Void, taskHandler: @escaping (Task) -> Void) {
		objectView.alpha = 1
		objectView.loadGif(name: "coin" + colorAttachment)
		characterView.loadGif(name: character.moveGif)
		UIViewPropertyAnimator.runningPropertyAnimator(
			withDuration: 1,
			delay: 0,
			options: .curveEaseIn) {
			syncAnimation()
		} completion: { progress in
			taskHandler(self.task!)
		}
	}
	
	func deleteCell(taskHandler: @escaping (Task) ->Void ) {
		guard let taskToDelete = task else { return }
		let generator = UIImpactFeedbackGenerator()
		generator.prepare()
//		playSound( task!.completed ? AVAudioPlayer.coin: AVAudioPlayer.delete )
		UIViewPropertyAnimator.runningPropertyAnimator(
			withDuration: 0.5,
			delay: 0,
			options: .curveEaseIn) {
			self.contentView.alpha = 0.5
		} completion: { progress in
			if progress == .end {
				taskHandler(taskToDelete)
				generator.generateFeedback(for: self.settingController.hapticMode)
			}
		}
	}
	
	private func updateUI(){
		titleLabel.text = task!.text
		titleLabel.textColor = task!.completed ? .gray: settingController.palette.primary
		reward.isHidden = true
		characterView.isHidden = true
		contentView.alpha = 1
		if task!.completed {
			objectView.loadGif(name: "coin" + colorAttachment)
		}else {
			objectView.loadGif(name: "chest" + colorAttachment)
		}
	}
	
	override func draw(_ rect: CGRect) {
		super.draw(rect)
		let objectNum = Int.random(in: 1...2)
		backgroundObjectLeft.image = UIImage(named: "background_object\(Int.random(in: 1...9))")
		
		distanceObjectLeft.constant = CGFloat.random(in: -groundTile.bounds.width / 3...0)
		backgroundObjectLeft.setNeedsDisplay()
		if objectNum == 2 {
			backgroundObjectRight.image = UIImage(named: "background_object\(Int.random(in: 1...9))")
			backgroundObjectRight.isHidden = false
			distanceObjectRight.constant = CGFloat.random(in: 0...30)
			backgroundObjectRight.setNeedsDisplay()
			
		}else {
			backgroundObjectRight.isHidden = true
		}
		
	}
}
