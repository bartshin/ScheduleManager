//
//  ChangeCharacterVC.swift
//  PixelScheduler
//
//  Created by Shin on 3/30/21.
//

import UIKit
import AVFoundation

class SelectCharacterVC: UIViewController
//, PlaySoundEffect
{
	
	var settingController: SettingController!
	
	private let cellReuseID = "SelectCharacterCell"
	var allCharacters: [SettingKey.Character] {
		SettingKey.Character.allCases
	}
	private var selectedCharacter: SettingKey.Character?
	
	var player: AVAudioPlayer!
	
	private var wealkInAnimation: UIViewPropertyAnimator!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var backgroundPreview: UIImageView!
	@IBOutlet weak var characterPreview: UIImageView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.dataSource = self
		tableView.delegate = self
		backgroundPreview.image = UIImage(named: "background_\(Int.random(in: 1...6))")
	}
}

extension SelectCharacterVC: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		allCharacters.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseID) as! SelectCharacterCell
		let character = allCharacters[indexPath.row]
		cell.imageview.image = character.staticImage
		if character.isFree || settingController.isPurchased {
			cell.label.text = character.koreanName
		}else {
			cell.label.text = character.koreanName + " (프리미엄)"
		}
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let character = allCharacters[indexPath.row]
		if selectedCharacter == character { return }
		characterPreview.layer.removeAllAnimations()
		characterPreview.loadGif(name: character.moveGif)
		let transform = CATransform3DTranslate(CATransform3DIdentity, -500, 0, 0)
		characterPreview.layer.transform = transform
		if character.isFree || settingController.isPurchased {
			settingController.changeCharacter(to: character)
		}
		selectedCharacter = character
		
		UIViewPropertyAnimator.runningPropertyAnimator(
			withDuration: 3,
			delay: 0,
			options: .curveLinear) {
//			self.playSound(character.rawValue)
			self.characterPreview.layer.transform = CATransform3DIdentity
		} completion: { [weak weakSelf = self] progress in
			if progress == .end {
				if let selected = weakSelf?.selectedCharacter,
					 selected == character{
					weakSelf?.characterPreview.image = character.staticImage
				}
			}
		}
	}
}
