//
//  CharacterNode.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/02/01.
//

import SpriteKit
import AVFoundation

class CharacterNode: SKSpriteNode {
	
	static let nodeSize = CGSize(width: 160, height: 100)
	private let character: SettingKey.Character
	
	var isMeleeType: Bool {
		character.projectile == nil
	}
	private(set) var projectileNode: SKNode?
	
	typealias AnimationResource = (textures: [SKTexture], duration: Double)
	private var moveResource: AnimationResource = ([], 0)
	private var idleResource: AnimationResource = ([], 0)
	private var attackResource: AnimationResource = ([], 0)
	private var idleAnimation: SKAction!
	private var attackAnimation: SKAction!
	private(set) var actionsToPerform = [SKAction]()
	private(set) var currentActionKey = ""
	private let jumpSoundAction = SKAction.playSoundFileNamed("jump", waitForCompletion: true)
	private lazy var attackSoundAction = SKAction.playSoundFileNamed(character.attackSound, waitForCompletion: false)
	var isFalling = false
	
	init(character: SettingKey.Character) {
		self.character = character
		let texture = SKTexture(image: character.staticImage)
		super.init(texture: texture, color: .clear, size: Self.nodeSize)
		
		name = "character"
		
		physicsBody = SKPhysicsBody(texture: texture, size: size)
		physicsBody?.mass = 1
		physicsBody?.allowsRotation = false
		
		loadTextures()
		initAnimations()
	}
	
	func isSame(with character: SettingKey.Character) -> Bool {
		self.character == character
	}
	
	private func loadTextures() {
		guard let idleResource = UIImage.getFramesFromGif(name: character.idleGif),
					let moveResource = UIImage.getFramesFromGif(name: character.moveGif),
		let attackResource = UIImage.getFramesFromGif(name: character.attackGif) else {
						assertionFailure("Fail to load idel textures for \(character).")
						return
					}
		self.moveResource = (textures: moveResource.frames.compactMap {
			SKTexture(image: $0)
		}, duration: moveResource.duration)
		self.idleResource = (textures: idleResource.frames.compactMap {
			SKTexture(image: $0)
		}, duration: idleResource.duration)
		self.attackResource = (textures: attackResource.frames.compactMap({
			SKTexture(image: $0)
		}), duration: attackResource.duration)
		
		guard let projectile = character.projectile else {
			return
		}
		switch projectile {
		case .gif(let fileName):
			guard let resource = UIImage.getFramesFromGif(name: fileName) else {
				assertionFailure("Unable to load projectile gif")
				return
			}
			let textures = resource.frames.compactMap {
				SKTexture(image: $0)
			}
			projectileNode = SKSpriteNode(texture: textures.first!, size: textures.first!.size())
			projectileNode!.run(.repeatForever(.animate(with: textures, timePerFrame: resource.duration / Double(textures.count))))
		case .image(let fileName):
			projectileNode = SKSpriteNode(imageNamed: fileName)
			(projectileNode as! SKSpriteNode).size = CGSize(
				width: size.width / 2,
				height: size.height * 0.2)
		}
		projectileNode!.setScale(frame.size.width / projectileNode!.frame.size.width * 0.5)
	}
	
	private func initAnimations() {
		idleAnimation = SKAction.animate(with: idleResource.textures, timePerFrame: idleResource.duration / Double(idleResource.textures.count))
		attackAnimation = SKAction.animate(with: attackResource.textures, timePerFrame: attackResource.duration / Double(attackResource.textures.count))
	}
	
	func addWalkAction(to destination: CGPoint) {
		
		let distance = sqrt(position.calcDistanceSquared(to: destination))
		let duration = Double(distance)/300
		let frameCounts = min(max(duration/moveResource.duration * Double(moveResource.textures.count), 1), Double(moveResource.textures.count))
		
		let animation = SKAction.animate(with: Array(moveResource.textures[0..<Int(frameCounts)]), timePerFrame: duration/frameCounts)
		
		let action = SKAction.group([animation, SKAction.move(to: destination, duration: duration)])
		addAction(action, with: "walk")
	}
	
	func addJumpAction(from start: CGPoint, to end: CGPoint, withSound: Bool) {
		let path = UIBezierPath()
		let controlPoint = CGPoint(
			x: start.x * 0.6 + end.x * 0.4,
			y: end.y * 1.3)
		path.move(to: start)
		path.addQuadCurve(
			to: end,
			controlPoint: controlPoint)
		
		var actions = [SKAction.follow(
			path.cgPath,
			asOffset: false,
			orientToPath: false,
			speed: 500)]
		
		if withSound,
			 !AVAudioSession.sharedInstance().isOtherAudioPlaying{
			actions.append(jumpSoundAction)
		}
		addAction(SKAction.group(actions), with: "jump")
	}
	
	func addIdleAction() {
		let idleAction = SKAction.repeatForever(idleAnimation)
		addAction(idleAction, with: "idle")
	}
	
	func addAttackAction(withSound: Bool) {
		var actions = [SKAction]()
		if withSound,
			 !AVAudioSession.sharedInstance().isOtherAudioPlaying {
			actions.append(attackSoundAction)
		}
		actions.append(attackAnimation)
		addAction(SKAction.group(actions), with: "attack")
	}
	
	private func addAction(_ action: SKAction, with key: String) {
		let changeKey = SKAction.run { [weak weakSelf = self] in
			weakSelf?.currentActionKey = key
		}
		actionsToPerform.append(.group([action, changeKey]))
	}
	
	func consumeActions() {
		run(.sequence(actionsToPerform))
		actionsToPerform.removeAll()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
