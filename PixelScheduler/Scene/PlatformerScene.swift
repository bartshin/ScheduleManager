//
//  PlatformerScene.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/01/31.
//

import SwiftUI
import SpriteKit
import Combine
import AVFAudio

class PlatformerScene: SKScene {
	
	@Environment(\.colorScheme) var colorScheme
	private let settingController: SettingController
	private let taskController: TaskModelController
	private let states: ViewStates
	private var statesObservers = [AnyCancellable]()
	
	private var character: CharacterNode!
	private var taskControllerObserver: AnyCancellable?
	private var characterChangedObserver: AnyCancellable?
	private var ground: SKNode!
	private var groundYPosition: CGFloat {
		size.height * 0.05
	}
	private var background: SKNode!
	private var tileCountForFloor = 5
	private let leftTileTexture = SKTexture(imageNamed: "tile_left")
	private let centerTileTexture = SKTexture(imageNamed: "tile_center")
	private let rightTileTexture = SKTexture(imageNamed: "tile_right")
	private let floorHeight: CGFloat = 90
	private var currentFloors = [SKNode]()

	private var lastTimeTouchObject = Date()
	private var taskInObjects = [SKNode: Task]()
	typealias AnimationResource = (textures: [SKTexture], duration: Double)
	private var chestResources = [AnimationResource]()
	private var coinResources = [AnimationResource]()
	private var explosionResource: AnimationResource!
	private let fallingSoundAction = SKAction.playSoundFileNamed("fall", waitForCompletion: true)
	private let explosionSoundAction = SKAction.playSoundFileNamed("explosion", waitForCompletion: false)
	
	init(taskController: TaskModelController, settingController: SettingController, states: ViewStates) {
		self.taskController = taskController
		self.settingController = settingController
		self.states = states
		self.lastAppliedSort = states.taskSort
		super.init(size: .zero)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func didMove(to view: SKView) {
		physicsWorld.contactDelegate = self
		
		initBackground()
		initGround()
		initCamera()
		addCharacterNode(settingController.character)
		loadTextures()
		observeCharacterChange()
		observeStates()
		observeTaskController()
		character.addIdleAction()
		character.consumeActions()
	}
	
	// MARK: - Init
	
	private func addCharacterNode(_ characterToSet: SettingKey.Character, to position: CGPoint? = nil) {
		character?.removeFromParent()
		character = CharacterNode(character: characterToSet)
		character.name = "character"
		character.physicsBody?.categoryBitMask = ObjectType.character.rawValue
		character.physicsBody?.collisionBitMask = ObjectType.tile.rawValue
		character.physicsBody?.contactTestBitMask = ObjectType.object.rawValue
		character.position = position ?? CGPoint(
			x: size.width/2,
			y: groundYPosition + 30)
		character.zPosition = Layer.character.rawValue
		addChild(character)
	}
	
	private func initBackground() {
		background?.removeFromParent()
		let colorScheme: ColorScheme
		switch settingController.visualMode {
		case .light:
			colorScheme = .light
		case .dark:
			colorScheme = .dark
		case .system:
			colorScheme = self.colorScheme
		}
		let backgroundImageName = "background_\(colorScheme == .light ? "light": "dark")_\(Int.random(in: 1...(colorScheme == .light ? 4: 2)))"
		let backgroundImage = UIImage(named: backgroundImageName)!
		
		backgroundColor = backgroundImage.areaAverage()
		let background = SKSpriteNode(imageNamed: backgroundImageName)
		
		background.name = "background"
		background.alpha = 0.8
		background.zPosition = Layer.background.rawValue
		background.position = CGPoint(x: frame.midX - (character?.position.x ?? 0) * 0.1, y: frame.midY)
		
		let scale = size.height * CGFloat(max(currentFloors.count, 5))/5 / background.size.height
		background.yScale = scale
		self.background = background
		addChild(background)
	}
	
	private func initGround() {
		ground = SKNode()
		ground.name = "ground"
		var tiles = [SKSpriteNode]()
	
		let firstTile = SKSpriteNode(texture: leftTileTexture)
		firstTile.position = CGPoint(
			x: 0,
			y: groundYPosition)
		let centerTileWidth = centerTileTexture.size().width
		let tileCount = Int(size.width / centerTileWidth) + 1
		
		addChild(firstTile)
		tiles.append(firstTile)
		for i in 1...tileCount {
			let tile = i == tileCount ? SKSpriteNode(texture: rightTileTexture): SKSpriteNode(texture: centerTileTexture)
			let lastTile = tiles.last!
			tile.position = CGPoint(
				x: lastTile.position.x + lastTile.frame.size.width,
				y: lastTile.position.y)
			ground.addChild(tile)
			tiles.append(tile)
		}
		
		tiles.forEach {
			$0.zPosition = Layer.tile.rawValue
			$0.physicsBody = SKPhysicsBody(rectangleOf: $0.size)
			$0.physicsBody?.isDynamic = false
			$0.physicsBody?.categoryBitMask = ObjectType.tile.rawValue
			
		}
		addChild(ground)
	}
	
	private func initCamera() {
		let camera = SKCameraNode()
		addChild(camera)
		self.camera = camera
	}
	
	private func initDecorations() {
		ground.children.forEach {
			if $0.name == "decorationObject" {
				$0.removeFromParent()
			}
		}
		let count = Int.random(in: 1...3)
		var objectNumbers = Set<Int>()
		var objectXPositions = Set<CGFloat>()
		for _ in 0..<count {
			var number = Int.random(in: 1...15)
			while objectNumbers.contains(number) {
				number = Int.random(in: 1...15)
			}
			objectNumbers.insert(number)
			let object = SKSpriteNode(imageNamed: "background_object" + String(number))
			object.name = "decorationObject"
			object.setScale(1.3)
			var xPosition = CGFloat.random(in: 50...size.width - 50)
			while objectXPositions.contains(where: {
				abs($0 - xPosition) < 50
			}) {
				xPosition = CGFloat.random(in: 50...size.width - 50)
			}
			objectXPositions.insert(xPosition)
			object.position = CGPoint(x: xPosition,
																y: groundYPosition + object.size.height * CGFloat.random(in: 0.4...0.8))
			object.zPosition = Layer.decorationObject.rawValue
			
			ground.addChild(object)
		}
	}
	
	// MARK: - User intents
	
	func triggerAttack() {
		guard character.currentActionKey != "attack" else {
			return
		}
		character.removeAction(forKey: "idle")
		character.addAttackAction(withSound: settingController.soundEffect == .on)
		character.addIdleAction()
		character.consumeActions()
		let attackNode: SKNode
		let isLookingRightSide = character.xScale > 0
		if character.isMeleeType {
			attackNode = SKShapeNode(circleOfRadius: 30)
			(attackNode as! SKShapeNode).fillColor = .clear
			(attackNode as! SKShapeNode).strokeColor = .clear
			
			attackNode.physicsBody = SKPhysicsBody(circleOfRadius: 30, center: .zero)
			
		}else {
			attackNode = character.projectileNode!
			attackNode.physicsBody = SKPhysicsBody(texture: (attackNode as! SKSpriteNode).texture!, size: attackNode.frame.size)
			attackNode.xScale = abs(attackNode.xScale) * ( isLookingRightSide ? 1: -1)
			attackNode.alpha = 1
		}
		
		attackNode.position = CGPoint(
			x: character.position.x + character.frame.size.width * (isLookingRightSide ? 0.2: -0.2),
			y: character.position.y)
		
		attackNode.physicsBody?.usesPreciseCollisionDetection = true
		attackNode.physicsBody?.isDynamic = false
		attackNode.physicsBody?.categoryBitMask = ObjectType.characterAttack.rawValue
		attackNode.physicsBody?.contactTestBitMask = ObjectType.object.rawValue
		attackNode.zPosition = Layer.characterAttack.rawValue
		attackNode.name = "characterAttack"
		addChild(attackNode)
		let rangeDistance = character.isMeleeType ? character.frame.size.width * 0.5: frame.size.width * 0.5
		let moveForwardAction = SKAction.move(
			by: .init(dx: rangeDistance * ( isLookingRightSide ? 1: -1), dy: 0), duration: 0.5)
		
		attackNode.run(moveForwardAction) {
			attackNode.removeFromParent()
		}
	}
	
	func showTask(taskId: Task.ID) {
		guard let (object, _) = taskInObjects.first(where: { (object, task) in
			task.id == taskId
		})else {
			assertionFailure("Cannot find object for contain task")
			return
		}
		let ground = object.parent!
		let actions: [SKAction] = [
			.colorize(with: .gray, colorBlendFactor: 0.8, duration: 0.5),
			.run {
				self.character.position = CGPoint(x: ground.position.x + object.position.x,
																		 y: ground.position.y + object.position.y)
			},
			.colorize(with: .clear, colorBlendFactor: 0, duration: 0.1)
		]
		background.run(.sequence(actions))
	
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard !states.isCategoryExpanded,
					let touch = touches.first else {
						return
					}
		let touchedLocation = touch.location(in: self.view)
		var location = CGPoint(x: min(max(50, touchedLocation.x), size.width - 50),
													 y: size.height - touchedLocation.y)
		if let camera = self.camera {
			location = CGPoint(x: location.x + camera.position.x - size.width/2,
												 y: location.y + camera.position.y - size.height/2)
		}
		let yOffset = location.y - character.position.y
		
		// Show quick help when character is tapped
		if character.position.y < frame.size.height * 0.2,
			abs(location.x - character.position.x) < 30,
			 abs(location.y - (character.position.y - character.size.height/2)) < 50,
			 !character.isFalling,
			 states.presentingTaskId == nil{
			states.isShowingQuickHelp = true
			return
		}
		
		character.removeAction(forKey: "idle")
		
		// Turn character direction
		if location.x < character.position.x{
			character.xScale = -1
		}else {
			character.xScale = 1
		}
		
		// Walk
		if yOffset < floorHeight * 0.5,
			 character.currentActionKey != "jump"{
			
			let destination = CGPoint(x: location.x,
																y: character.position.y)
		
			character.addWalkAction(to: destination)
			character.addIdleAction()
		}
		
		// Jump
		else if yOffset < floorHeight * 1.5 ,
						character.currentActionKey != "jump"{
			
			var locationToJump: CGPoint? = nil
			let nextFloor = findNextFloor(from: character.position.y)
			let toRightSide = nextFloor % 2 == 0
			if toRightSide, location.x > size.width/2 {
				locationToJump = CGPoint(x: size.width/2 - centerTileTexture.size().width, y: character.position.y)
			}else if !toRightSide, location.x < size.width/2 {
				locationToJump = CGPoint(x: size.width/2 + centerTileTexture.size().width, y: character.position.y)
			}
			if currentFloors.count < nextFloor {
				locationToJump = nil
			}
	
			if let locationToJump = locationToJump  {
				// Go to location where character can jump to next floor
				character.addWalkAction(to: locationToJump)
				let floor = findNextFloor(from: location.y)
				character.addJumpAction(
					from: locationToJump,
					to: CGPoint(x: location.x,
											y: calcYPostion(for: floor)), withSound: settingController.soundEffect == .on)
				
			}else {
				// Just jump to touched location
				character.addJumpAction(from: character.position,
																to: location, withSound: settingController.soundEffect == .on)
			}
			character.addIdleAction()
		}
		character.consumeActions()
	}
	
	private func findNextFloor(from yPosition: CGFloat
	) -> Int {
		
		var floor = 0
		while true {
			if yPosition < calcYPostion(for: floor) {
				break
			}else {
				floor += 1
			}
		}
		return floor
	}
	
	private func loadTextures() {
		let priorities = [1, 2, 3, 4, 5]
		priorities.forEach { priority in
			guard let chestResource = UIImage.getFramesFromGif(name: "chest_" + UIColor.nameByPriority(priority)),
			let coinResource = UIImage.getFramesFromGif(name: "coin_" + UIColor.nameByPriority(priority)) else {
				fatalError("Unable to load gif")
			}
			chestResources.append(( chestResource.frames.compactMap({
				SKTexture(image: $0)
			}),  chestResource.duration))
			coinResources.append((
				coinResource.frames.compactMap({
					SKTexture(image: $0)
				}),
				coinResource.duration
			))
		}
		
		guard let explosionResource = UIImage.getFramesFromGif(name: "explosion") else {
			fatalError("Unable to load gif")
		}
		self.explosionResource = (explosionResource.frames.compactMap({
			SKTexture(image: $0)
		}), explosionResource.duration)
	}
	
	// MARK: - Update
	override func update(_ currentTime: TimeInterval) {
		guard let characterVelocityVertical = character.physicsBody?.velocity.dy else {
			return
		}
		
		if character.currentActionKey == "walk",
			characterVelocityVertical != 0 {
			states.presentingTaskId = nil
		}
		
		if settingController.soundEffect == .on,
			 !AVAudioSession.sharedInstance().isOtherAudioPlaying,
				characterVelocityVertical < -700,
			 character.currentActionKey != "jump",
			 !character.isFalling,
			 abs(character.position.x - size.width/2) < 50{
			character.isFalling = true
		
			character.run(fallingSoundAction) {[weak weakSelf = self] in
				weakSelf?.character.isFalling = false
			}
		}
	}
	
	override func didSimulatePhysics() {
		guard let currentCameraPosition = camera?.position else {
			return
		}
		let cameraPositionCandidate = CGPoint(
			x: character.position.x * 0.05 + size.width/2,
			y: character.position.y + frame.size.height * 0.3)
		if currentCameraPosition == .zero {
			camera!.position = cameraPositionCandidate
		}
		else if (cameraPositionCandidate.y < currentCameraPosition.y || abs(cameraPositionCandidate.y - currentCameraPosition.y) > frame.size.height * 0.3),
			 currentCameraPosition != .zero{
			camera!.run(.move(to: cameraPositionCandidate, duration: 0.5))
		}
	}
	
	private func observeCharacterChange() {
		characterChangedObserver = settingController.$character.sink { [self] newCharacter in
			guard !character.isSame(with: newCharacter) else {
				return
			}
			let currentCharacterPosition = character.position
			character.removeFromParent()
			addCharacterNode(newCharacter, to: currentCharacterPosition)
		}
	}
	private var lastAppliedSort: Task.Sort
	private var lastShownCollection: TaskCollection?
	private func observeStates() {
		guard statesObservers.isEmpty else {
			return
		}
		let sortObserver = states.$taskSort.sink { [weak self] newSort in
			guard let strongSelf = self else {
				return
			}
			if newSort != strongSelf.lastAppliedSort,
				 let collection = strongSelf.states.currentShowingCollection{
				strongSelf.lastAppliedSort = newSort
				strongSelf.showCollection(collection, by: newSort)
			}
		}
		let collectionObserver = states.$currentShowingCollection.sink { [weak self] newCollection in
			guard let strongSelf = self,
			newCollection?.style == .list else {
				return
			}
			if let newCollection = newCollection,
				 newCollection != strongSelf.lastShownCollection {
				strongSelf.lastShownCollection = newCollection
				strongSelf.showCollection(newCollection)
			}
		}
		statesObservers = [sortObserver, collectionObserver]
	}
	
	private func observeTaskController() {
		taskControllerObserver =  taskController.objectWillChange.sink { [weak self] _ in
			guard let strongSelf = self,
						let currentCollection = strongSelf.states.currentShowingCollection,
						currentCollection.style == .list,
						var tasksUpdated = strongSelf.taskController.table[currentCollection] else {
				return
			}
			strongSelf.taskInObjects.forEach { (object, task) in
				strongSelf.updateObjectIfNeeded(object: object, for: task, in: &tasksUpdated)
			}
			let currentPresentingTasks: Set<Task> = Set(strongSelf.taskInObjects.values)
			let newTask = tasksUpdated.filter {
				!currentPresentingTasks.contains($0)
			}
			newTask.forEach(strongSelf.addTaskToScene(_:))
		}
	}
	
	private func updateObjectIfNeeded(object: SKNode, for task: Task, in newTasks: inout [Task]) {
		guard let taskToUpdate = newTasks.first(where: { $0.id == task.id
		}) else {
			removeTask(task, in: object)
			return
		}
		guard task != taskToUpdate else {
			return // Not needed
		}
		
		guard let (floorNumber, floorToUpdate) = currentFloors.enumerated().first( where: { (index, floor) in
			guard let object = floor.children.first(where: {
				$0.name?.hasPrefix("object") ?? false
			}) else {
				assertionFailure("Floor without chest")
				return false
			}
			return taskInObjects[object]?.id == task.id
		}) else {
			assertionFailure("Fail to find floor node")
			return
		}
		
		let object = floorToUpdate.children.first {
			$0.name?.hasPrefix("object") ?? false
		}!
		
		let isRightSide = (floorNumber + 1) % 2 == 0
		taskInObjects.removeValue(forKey: object)
		let newObject = createObject(for: taskToUpdate, isRightSide: isRightSide)
		let yOffset: CGFloat
		if !task.isCompleted, taskToUpdate.isCompleted {
			yOffset = 10
		}
		else if task.isCompleted, !taskToUpdate.isCompleted {
			yOffset = -10
		}else {
			yOffset = 0
		}
		newObject.position = CGPoint(x: object.position.x,
																 y: object.position.y + yOffset)
		object.removeFromParent()
		floorToUpdate.addChild(newObject)
		taskInObjects[newObject] = taskToUpdate
	}
	
	private func showCollection(_ colleciton: TaskCollection, by sort: Task.Sort? = nil) {
		guard let tasks = taskController.table[colleciton]?.sorted(by: sort?.function ?? states.taskSort.function) else {
			return
		}
		character?.position = CGPoint(x: size.width/2,
																	y: groundYPosition + 30)
		initDecorations()
		currentFloors.removeAll()
		enumerateChildNodes(withName: "floor") { node, _ in
			node.removeFromParent()
		}
		taskInObjects.removeAll()
		guard
			!tasks.isEmpty else {
				return
			}
		tasks.forEach(addTaskToScene(_:))
		initBackground()
	}
	
	private func addTaskToScene(_ task: Task) {
		let nextFloor = currentFloors.count + 1
		let isRightSide = nextFloor % 2 == 0
		let floor = createFloor(to: nextFloor)
		let object = createObject(for: task, isRightSide: isRightSide)
		taskInObjects[object] = task
		addChild(floor)
		currentFloors.append(floor)
		floor.addChild(object)
		object.position = CGPoint(x: (CGFloat(tileCountForFloor/2) + (isRightSide ? 2: 0)) * centerTileTexture.size().width ,
															y: object.size.height * 0.6)
	}
	
	private func calcYPostion(for floor: Int) -> CGFloat {
		CGFloat(floor) * floorHeight + groundYPosition + 20
	}
	
	private func createFloor(to floor: Int) -> SKNode {
		let yPosition = calcYPostion(for: floor)
		let isRightSide = floor % 2 == 0
		let floor = SKNode()
		floor.name = "floor"
		let tileSize = centerTileTexture.size()
		for i in 1...tileCountForFloor {
		
			let tile: SKSpriteNode
			if i == 1 {
				tile = SKSpriteNode(texture: leftTileTexture)
			}else if i == tileCountForFloor {
				tile = SKSpriteNode(texture: rightTileTexture)
			}else {
				tile = SKSpriteNode(texture: centerTileTexture)
			}
			tile.position = CGPoint(x: tileSize.width * CGFloat(i), y: 0)
			floor.addChild(tile)
			tile.physicsBody = SKPhysicsBody(
				rectangleOf: tileSize)
			tile.physicsBody?.isDynamic = false
			tile.physicsBody?.categoryBitMask = ObjectType.tile.rawValue
			tile.physicsBody?.collisionBitMask = ObjectType.character.rawValue
			tile.zPosition = Layer.tile.rawValue
		}
		let xPosition: CGFloat = isRightSide ? size.width * 0.55: size.width * -0.05
		floor.position = CGPoint(x: xPosition,
														 y: yPosition)
		
		return floor
	}
	
	private func createObject(for task: Task, isRightSide: Bool?) -> SKSpriteNode {
		let resource: AnimationResource = task.isCompleted ? coinResources[task.priority - 1] : chestResources[task.priority - 1]
		let objectNode = SKSpriteNode(texture: resource.textures.first!)
		objectNode.name = "object" + task.id.uuidString

		objectNode.size = task.isCompleted ? CGSize(width: 80, height: 80) : CGSize(width: 80, height: 60)
		objectNode.physicsBody = SKPhysicsBody(texture: resource.textures.first!, size: objectNode.size)
		objectNode.physicsBody?.isDynamic = true
		objectNode.physicsBody?.categoryBitMask = ObjectType.object.rawValue
		objectNode.physicsBody?.collisionBitMask = 0
		objectNode.physicsBody?.affectedByGravity = false
		objectNode.physicsBody?.contactTestBitMask = ObjectType.character.rawValue | ObjectType.characterAttack.rawValue
		objectNode.zPosition = Layer.object.rawValue
		objectNode.run(.repeatForever(.animate(with: resource.textures, timePerFrame: resource.duration/Double(resource.textures.count))))
		
		let labelNode = SKLabelNode(fontNamed: settingController.language.font)
		
		labelNode.text = task.text
		if task.text.count > 8 {
			labelNode.numberOfLines = 2
			labelNode.fontSize *= max(8 / CGFloat(task.text.count), 0.5)
			labelNode.text?.insert("\n", at: task.text.index(task.text.startIndex, offsetBy: 10))
		}
		labelNode.fontColor = task.isCompleted ? .gray: .byPriority(task.priority)
		labelNode.position = CGPoint(
			x: labelNode.frame.size.width * (isRightSide == nil ? 0 : ((isRightSide! ? -0.2: 0.2))),
			y: objectNode.size.height/2)
		let labelBackground = SKSpriteNode(imageNamed: "wooden_board")
		labelBackground.zPosition = -1
		labelBackground.size = CGSize(width: labelNode.frame.size.width + 20,
																	height: labelNode.frame.size.height * 1.5)
		labelBackground.position = CGPoint(x: 0,
																			 y: labelNode.frame.size.height * 0.4)
		labelNode.addChild(labelBackground)
		
		objectNode.addChild(labelNode)
		return objectNode
	}
	
	private func removeTask(_ task: Task, in object: SKNode) {
		guard let floor = object.parent,
		let floorIndex = currentFloors.firstIndex(of: floor) else {
			assertionFailure("Object is not on floor")
			return
		}
		taskInObjects[object] = nil
		floor.run(.fadeOut(withDuration: 0.5)) {
			floor.removeFromParent()
		}
		currentFloors.remove(at: floorIndex)
	}
	
	private enum ObjectType: UInt32 {
		case character = 1
		case tile = 2
		case object = 4
		case characterAttack = 8
	}
	
	private enum Layer: CGFloat {
		case explosion = 6
		case character = 5
		case characterAttack = 4
		case object = 3
		case tile = 2
		case decorationObject = 1
		case background = 0
	}
}

extension PlatformerScene: SKPhysicsContactDelegate {
	
	func didBegin(_ contact: SKPhysicsContact) {
		guard Date().timeIntervalSince(lastTimeTouchObject) > 0.5 else {
			return
		}
		
		if (contact.bodyA.node?.name == "character" &&
				contact.bodyB.node?.name?.hasPrefix("object") ?? false) {
			presentTaskIfNeeded(contact.bodyB.node!)
		} else if (
			contact.bodyA.node?.name?.hasPrefix("object") ?? false &&
							 contact.bodyB.node?.name == "character") {
			presentTaskIfNeeded(contact.bodyA.node!)
		}
		else if (contact.bodyA.node?.name == "characterAttack" && contact.bodyB.node?.name?.hasPrefix("object") ?? false) {
			if destroyChestIfNeeded(contact.bodyB.node!, withSound: settingController.soundEffect == .on) {
				contact.bodyA.node!.run(.fadeOut(withDuration: 0.2))
			}
		}
		else if (contact.bodyA.node?.name?.hasPrefix("object")  ?? false) && contact.bodyB.node?.name == "characterAttack" {
			if destroyChestIfNeeded(contact.bodyA.node!, withSound: settingController.soundEffect == .on) {
				contact.bodyB.node!.run(.fadeOut(withDuration: 0.2))
			}
		}
	}
	
	private func presentTaskIfNeeded(_ object: SKNode) {
		if states.currentShowingCollection != nil,
			 let task = taskInObjects[object],
			 states.presentingTaskId != task.id {
			withAnimation {
				states.presentingTaskId = task.id
			}
			lastTimeTouchObject = Date()
		}
	}
	
	private func destroyChestIfNeeded(_ chest: SKNode, withSound: Bool) -> Bool {
		guard let task = taskInObjects[chest],
					let collection = states.currentShowingCollection,
		!task.isCompleted else {
			return false
		}
		guard let floor = chest.parent else {
			fatalError("Chest is not on floor")
		}
		taskInObjects[chest] = nil
		let explosionNode = SKSpriteNode(texture: explosionResource.textures.first!, size: explosionResource.textures.first!.size())
		explosionNode.position = CGPoint(x: chest.position.x,
																		 y: chest.position.y + 50)
		explosionNode.zPosition = Layer.explosion.rawValue
		chest.removeFromParent()
		floor.addChild(explosionNode)
		
		let explosionAnimation = SKAction.animate(with: explosionResource.textures, timePerFrame: explosionResource.duration / Double(explosionResource.textures.count))
		let scaleAction = SKAction.scale(to: 1.3, duration: explosionResource.duration)
		var explosionAction = [explosionAnimation, scaleAction]
		if withSound, !AVAudioSession.sharedInstance().isOtherAudioPlaying {
			explosionAction.append(explosionSoundAction)
		}
		
		var newTask = task
		newTask.isCompleted = true
		let floorNumber = currentFloors.firstIndex(of: floor)!
		let isRightSide = (floorNumber + 1) % 2 == 0
		let coin = createObject(for: newTask, isRightSide: isRightSide)
		coin.alpha = 0
		coin.position = CGPoint(x: chest.position.x,
														y: chest.position.y + 10)
		floor.addChild(coin)
		taskInObjects[coin] = newTask
		taskController.changeTask(from: task, to: newTask, in: collection)
		explosionNode.run(.group(explosionAction)) {
			coin.run(.fadeIn(withDuration: 0.5))
		}
		return true
	}
	
	func didEnd(_ contact: SKPhysicsContact) {
		if (contact.bodyA.node?.name == "character" && contact.bodyB.node?.name?.hasPrefix("object") ?? false ) ||  (contact.bodyA.node?.name?.hasPrefix("object") ?? false &&
							 contact.bodyB.node?.name == "character"),
			 Date().timeIntervalSince(lastTimeTouchObject) > 0.5{
			withAnimation {
				states.presentingTaskId = nil
			}
			lastTimeTouchObject = Date()
		}
	}
}

