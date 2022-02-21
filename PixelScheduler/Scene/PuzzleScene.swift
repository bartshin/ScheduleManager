//
//  PuzzleScene.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/02/15.
//

import SceneKit
import Combine
import SwiftUI
import PuzzleMaker
import Darwin

class PuzzleScene {
	
	private struct PuzzlePiece {
		let numRow: Int
		let numColumn: Int
		let image: UIImage
		let positionInImage: CGPoint
		var positionOnBoard: CGPoint?
		
		var id: String {
			String(numRow) + String(numColumn)
		}
	}
	
	var taskController: TaskModelController!
	var settingController: SettingController!
	let states: ViewStates
	let scene = SCNScene(named: "Puzzle_scene1.scn")!
	private var taskControllerObserver: AnyCancellable?
	private var settingControllerObserver: AnyCancellable?
	private var lastDrawnCollection: TaskCollection?
	private var tasks: [Task]!
	private var puzzlePieces = [PuzzlePiece]()
	private var presentingPuzzleNode: SCNNode?
	private var needToShowCompleteAnimation = false
	private var isShowingAnimation = false
	
	var cameraNode: SCNNode {
		scene.rootNode.childNode(withName: "camera", recursively: false)!
	}
	private var puzzleFrameNode: SCNNode {
		scene.rootNode.childNode(withName: "puzzleFrame", recursively: false)!
	}
	private var puzzleBoardNode: SCNNode {
		scene.rootNode.childNode(withName: "puzzleBoard", recursively: true)!
	}
	
	init(states: ViewStates) {
		self.states = states
	}
	
	func setUp() {
		scene.background.contents = settingController.palette.quaternary.withAlphaComponent(0.5)
		if settingControllerObserver == nil {
			settingControllerObserver = settingController.objectWillChange.sink {[weak weakSelf = self] _ in
				weakSelf?.scene.background.contents = weakSelf?.settingController.palette.quaternary.withAlphaComponent(0.5)
			}
		}
		if taskControllerObserver == nil {
			taskControllerObserver = taskController.objectWillChange.sink {[weak self] _ in
				guard let strongSelf = self,
							let collection = strongSelf.taskController.collections.first(where: {
								$0.id == strongSelf.states.currentShowingCollection?.id
							}),
							let tasksUpdated = strongSelf.taskController.table[collection],
							collection.puzzleConfig != nil else {
					return
				}
				strongSelf.states.currentShowingCollection = collection
				strongSelf.needToShowCompleteAnimation = strongSelf.tasks.count == collection.puzzleConfig!.numColumns * collection.puzzleConfig!.numRows && tasksUpdated.filter {
					!$0.isCompleted
				}.isEmpty &&
					 !strongSelf.tasks.filter{
						 !$0.isCompleted
					 }.isEmpty
				
				// Prevent chainging position of each piece just modify node in-place
				let currentTasksIds = strongSelf.tasks.compactMap { $0.id }
				
				let newTasks = tasksUpdated.filter {
					!currentTasksIds.contains($0.id)
				}
				var taskDeleted = [Task]()
				let changedTask = strongSelf.tasks.filter { oldTask in
					guard let newTask = tasksUpdated.first(where: {
						$0.id == oldTask.id
					}) else {
						taskDeleted.append(oldTask)
						return false
					}
					return newTask != oldTask
				}
				changedTask.forEach { task in
					let index = strongSelf.tasks.firstIndex(of: task)!
					let numRow = index / collection.puzzleConfig!.numColumns
					let numColumn = index % collection.puzzleConfig!.numColumns
					let piece = strongSelf.puzzlePieces.first {
						$0.numRow == numRow && $0.numColumn == numColumn
					}!
					let node = strongSelf.getNode(for: piece)
					let newTask = tasksUpdated.first {
						$0.id == task.id
					}!
					strongSelf.tasks[index] = newTask
					node.geometry?.firstMaterial?.diffuse.contents = strongSelf.getPuzzleContents(puzzlePiece: piece, for: task)
					node.opacity = strongSelf.getPuzzleOpacity(puzzlePiece: piece, for: task)
				}
				taskDeleted.forEach { task in
					let index = strongSelf.tasks.firstIndex(of: task)!
					let numRow = index / collection.puzzleConfig!.numColumns
					let numColumn = index % collection.puzzleConfig!.numColumns
					let piece = strongSelf.puzzlePieces.first {
						$0.numRow == numRow && $0.numColumn == numColumn
					}!
					let node = strongSelf.getNode(for: piece)
					strongSelf.tasks.remove(at: index)
					node.removeFromParentNode()
				}
				newTasks.forEach { task in
					guard let piece = try? strongSelf.getNextPiece() else {
						assertionFailure("Cannot find node for task")
						return
					}
					let node = strongSelf.getNode(for: piece)
					node.geometry?.firstMaterial?.diffuse.contents = strongSelf.getPuzzleContents(puzzlePiece: piece, for: task)
					node.opacity = strongSelf.getPuzzleOpacity(puzzlePiece: piece, for: task)
					strongSelf.tasks.append(task)
				}
			}
		}
	}
	
	private func getPuzzleContents(puzzlePiece: PuzzlePiece, for task: Task) -> Any {
		if task.isCompleted {
			return puzzlePiece.image
		}else if let completionLog = task.completionLog,
						 completionLog.current != 0{
			return puzzlePiece.image
		}else {
			return puzzlePiece.image.maskWithColor(color: .byPriority(task.priority)) as Any
		}
	}
	
	private func getPuzzleOpacity(puzzlePiece: PuzzlePiece, for task: Task) -> CGFloat {
		if let completionLog = task.completionLog {
			return CGFloat(completionLog.current / completionLog.total)
		}else {
			return 1
		}
	}
	
	private func getNode(for piece: PuzzlePiece) -> SCNNode {
		return puzzleBoardNode.childNode(withName: piece.id + "fixed", recursively: false)!
	}
	
	func collectionDidChanged() {
		if puzzlePieces.isEmpty {
			prepareShowPuzzle()
		}
		guard let collection = states.currentShowingCollection else {
			return
		}
		updateTasks()
		if collection != lastDrawnCollection {
			lastDrawnCollection = collection
			updatePuzzles()
		}
	}
	
	func taskSortDidChanged() {
		updateTasks()
		updatePuzzles()
	}
	
	private func updatePuzzles() {
		puzzlePieces.removeAll()
		puzzleBoardNode.childNodes.forEach {
			$0.removeFromParentNode()
		}
		getPuzzlePieces()
	}
	
	private func updateTasks() {
		guard let collection = states.currentShowingCollection else {
			return
		}
		tasks = taskController.table[collection]?.sorted(by: states.taskSort.function)
	}
	
	func showTask(taskId: Task.ID, completion: @escaping (Task.ID) -> Void) throws {
		
		guard let collection = states.currentShowingCollection,
					let task = taskController.getTask(by: taskId, from: collection),
					let index = tasks.firstIndex(of: task),
					let piece = puzzlePieces.first(where:  {
						$0.numRow == index / collection.puzzleConfig!.numColumns && $0.numColumn == index % collection.puzzleConfig!.numColumns
					}) else {
						throw PuzzleError.failToFindPiece
					}
		let node = getNode(for: piece)
		
		try startPresenting(selectedPuzzleNode: node, taskToPresent: task) { task in
			completion(task!.id)
		}
	}
	
	func handleTap(at location: CGPoint, in size: CGSize, completion: @escaping (Task?) -> Void) {
		guard presentingPuzzleNode == nil, !isShowingAnimation else {
			return
		}
		guard let camera = cameraNode.camera else {
			fatalError()
		}
		let center = CGPoint(x: size.width/2,
												 y: size.height/2)
		let locationFromCenter = CGPoint(x: location.x - center.x,
																		 y: -(location.y - center.y)) // y-axis is reverse
		// Calculate current view size at z == puzzleboard.z what camera see
		let theta = camera.fieldOfView/2 / 180 * .pi
		let currentViewHeight = Float(tan(theta)) * (cameraNode.position.z - puzzleBoardNode.position.z) * 2
		let vRatio = currentViewHeight / Float(size.height)
		let currentViewWidth = Float(size.width / size.height) * currentViewHeight
		let hRatio = currentViewWidth / Float(size.width)
		let locationInView = (x: Float(locationFromCenter.x) * hRatio,
													y: Float(locationFromCenter.y) * vRatio)
		guard abs(locationInView.x) < puzzleBoardNode.size.x/2,
					abs(locationInView.y) < puzzleBoardNode.size.y/2 else {
						print("Tap outside puzzle")
						return
					}
		var distSquare = Float.greatestFiniteMagnitude
		var foundNode: SCNNode? = nil
		puzzleBoardNode.childNodes.forEach { piece in
			let position = (x: piece.position.x, y: piece.position.y)
			let distanceSquare = (locationInView.x - position.x) * (locationInView.x - position.x) + (locationInView.y - position.y) * (locationInView.y - position.y)
			if distSquare > distanceSquare {
				distSquare = distanceSquare
				foundNode = piece
			}
		}
		if foundNode == nil {
			assertionFailure("Cannot find puzzle piece node")
		}
		do {
			try	startPresenting(selectedPuzzleNode: foundNode!, with: completion)
		}catch {
			print(error)
		}
	}
	
	private func prepareShowPuzzle() {
		guard let spotNode = scene.rootNode.childNode(withName: "spot", recursively: false) else{
						return
					}
		spotNode.constraints = [SCNLookAtConstraint(target: puzzleBoardNode)]
		spotNode.runAction(
			.move(to: SCNVector3(x: puzzleBoardNode.position.x,
													 y: puzzleBoardNode.position.y + 10,
													 z: puzzleBoardNode.position.z + 15), duration: 1.5))
		cameraNode.constraints = [SCNLookAtConstraint(target: puzzleBoardNode)]
		cameraNode.runAction(
			.move(to: SCNVector3(x: puzzleBoardNode.position.x,
																		y: puzzleBoardNode.position.y,
																		z: puzzleBoardNode.position.z + 10),
										 duration: 1))
	}
	
	private func loadPuzzles() {
		guard states.currentShowingCollection?.puzzleConfig != nil else {
			return
		}
		
		puzzlePieces.forEach { piece in
			let node = createFixedPuzzleNode(
				for: piece,
					 boardSize:
						CGSize(width: CGFloat(puzzleBoardNode.size.x),
									 height: CGFloat(puzzleBoardNode.size.y)),
					 sourceImageSize: states.currentShowingCollection!.puzzleConfig!.backgroundImage.image.size)
			
			puzzleBoardNode.addChildNode(node)
		}
	}
	
	private func movePuzzlesToDestination() {
		puzzlePieces.forEach { piece in
			guard let position = piece.positionOnBoard,
						let node = puzzleBoardNode.childNode(withName: piece.id, recursively: false) else {
							return
						}
			node.runAction(
				.move(
					to: SCNVector3(
						x: Float(position.x),
						y: Float(position.y),
						z: 0),
					duration: .random(in: 0.5...1.5))) {
						node.position =
						SCNVector3(
							x: Float(position.x),
							y: Float(position.y),
							z: 0)
					}
		}
	}
	
	private func showCompleteAnimation() {
		isShowingAnimation = true
		puzzleBoardNode.childNodes.forEach { pieceNode in
			let fixedPosition = pieceNode.position
			let boardSize = puzzleBoardNode.size
			let moveDuration = TimeInterval.random(in: 1...2)
			
			let randomPosition = SCNVector3(
				x: getRandom(-(boardSize.x/2 + fixedPosition.x), boardSize.x/2 + fixedPosition.x),
				y: getRandom(-(boardSize.y/2 + fixedPosition.y), boardSize.y/2 + fixedPosition.y),
				z: getRandom(fixedPosition.z, cameraNode.position.z/2))
			let randomAngles = SCNVector3(
				x: randomPosition.y > fixedPosition.y ? .random(in: (-.pi/2)...0): .random(in: 0...(.pi/2)),
				y: randomPosition.x > randomPosition.x ? .random(in: (-.pi)/2...0): .random(in: 0...(.pi/2)),
				z:  .random(in: -.pi/4...(.pi/4)))
			pieceNode.eulerAngles = randomAngles
			pieceNode.position = randomPosition
			pieceNode.runAction(.group([
				.move(to: fixedPosition, duration: moveDuration),
				.rotateTo(x: 0, y: 0, z: 0, duration: moveDuration)
			]))
		}
		if settingController.soundEffect == .on
		{
			SoundEffect.playSound(.levelup)
		}
		DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak weakSelf = self] in
			weakSelf?.isShowingAnimation = false
		}
	}
	
	private func getRandom<T>(_ a: T, _ b: T) -> T  where T: BinaryFloatingPoint, T.RawSignificand: FixedWidthInteger {
		 T.random(in: min(a, b)...max(a, b))
	}
	
	private func createFixedPuzzleNode(for piece: PuzzlePiece, boardSize: CGSize, sourceImageSize: CGSize) -> SCNNode{
		
		let (destination, size) = getPositionAndSize(for: piece, sourceImageSize: sourceImageSize, boardSize: boardSize)
		let node = SCNNode(
			geometry: SCNPlane(width: size.width,
												 height: size.height))
		node.position = SCNVector3(x: Float(destination.x),
															 y: Float(destination.y),
															 z: 0)
		let index = puzzlePieces.firstIndex {
			$0.id == piece.id
		}!
		node.name = piece.id + "fixed"
		puzzlePieces[index].positionOnBoard = destination
		let material = SCNMaterial()
		material.isDoubleSided = true
		node.geometry?.materials = [material]
		if let task = getTask(for: piece) {
			material.diffuse.contents = getPuzzleContents(puzzlePiece: piece, for: task)
			node.opacity = getPuzzleOpacity(puzzlePiece: piece, for: task)
		}else {
			material.diffuse.contents = piece.image.maskWithColor(color: .gray)
			node.opacity = 1
		}
		return node
	}
	
	private func getTask(for piece: PuzzlePiece) -> Task? {
		guard let puzzleConfig = states.currentShowingCollection?.puzzleConfig else {
			return nil
		}
		let index = piece.numRow * puzzleConfig.numColumns + piece.numColumn
		guard tasks.count > index else {
			return nil
		}
		return tasks[index]
	}
	
	private func getNextPiece() throws -> PuzzlePiece {
		guard puzzlePieces.count > tasks.count,
					let numColumns = states.currentShowingCollection?.puzzleConfig?.numColumns else {
						throw PuzzleError.full
		}
		let index = tasks.count
		let rowIndex = index / numColumns
		let columnIndex = index % numColumns
		if let piece = puzzlePieces.first(where: {
			$0.numRow == rowIndex && $0.numColumn == columnIndex
		}){
			return piece
		}else {
			throw PuzzleError.failToFindPiece
		}
	}
	
	func startPresenting(selectedPuzzleNode: SCNNode? = nil,  taskToPresent: Task? = nil, with completion: @escaping (Task?) -> Void) throws {
		let puzzleNode: SCNNode
		if selectedPuzzleNode == nil {
			let nextPiece = try getNextPiece()
			let fixedPuzzleNode = getNode(for: nextPiece)
			puzzleNode = fixedPuzzleNode
		}else {
			puzzleNode = selectedPuzzleNode!
		}
		
		let cameraPosition = scene.rootNode.convertPosition(cameraNode.position, to: puzzleBoardNode)
		let moveAction = SCNAction.move(to: SCNVector3(x: cameraPosition.x - puzzleNode.size.x/2,
																									 y: cameraPosition.y - puzzleNode.size.y/2,
																					z: cameraPosition.z/2),
													 duration: 0.5)
		let scaleAction = SCNAction.scale(to: 3, duration: 0.5)
		let flipAction = SCNAction.rotateBy(x: 0,
																				y: .pi,
																				z: 0,
																				duration: 0.5)
		var taskToPresent: Task? = taskToPresent ?? nil
		if taskToPresent == nil {
			if taskToPresent == nil,
				 let selectedPuzzleNode = selectedPuzzleNode,
				 let piece = findPiece(for: selectedPuzzleNode),
				 let task = getTask(for: piece) {
				taskToPresent = task
			}
			else if selectedPuzzleNode == nil {
				taskToPresent = nil
			}else {
				return // User select puzzle piece with empty task
			}
		}
		let completionAction = SCNAction.run {_ in
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				completion(taskToPresent)
			}
		}
		presentingPuzzleNode = puzzleNode
		puzzleNode.runAction(
			.sequence([.group([moveAction, scaleAction]),
								 .group([completionAction, flipAction])]))
	}
	
	func endPresenting() {
		guard let node = presentingPuzzleNode,
		let piece = findPiece(for: node),
		let destianation = piece.positionOnBoard else {
			assertionFailure("Cannot find node editing")
			return
		}
		if let task = getTask(for: piece) {
			node.geometry?.firstMaterial?.diffuse.contents = getPuzzleContents(puzzlePiece:piece, for: task)
			node.opacity = getPuzzleOpacity(puzzlePiece: piece, for: task)
		}else {
			node.geometry?.firstMaterial?.diffuse.contents = piece.image.withTintColor(.gray)
			node.opacity = 1
		}
		let filpAction = SCNAction.rotateBy(x: 0,
																				y: -.pi,
																				z: 0,
																				duration: 0.5)
		let scaleAction = SCNAction.scale(to: 1, duration: 0.5)
		let moveAction = SCNAction.move(
			to: SCNVector3(x: Float(destianation.x),
										 y: Float(destianation.y),
										 z: 0),
			duration: 0.5)
		node.runAction(.sequence([
			filpAction,
			.group([scaleAction, moveAction])
		])) { [weak weakSelf = self] in
			if weakSelf?.needToShowCompleteAnimation ?? false{
				weakSelf?.needToShowCompleteAnimation = false
				DispatchQueue.main.async {
					weakSelf?.showCompleteAnimation()
				}
			}
		}
		presentingPuzzleNode = nil
	}
	
	private func findPiece(for node: SCNNode) -> PuzzlePiece? {
		guard let id = node.name?.replacingOccurrences(of: "fixed", with: "") else {
			return nil
		}
		if let found = puzzlePieces.first(where: {
			$0.id == id
		}) {
				return found
		}else {
			assertionFailure("Cannnot found puzzle piece for \(id)")
			return nil
		}
	}
	
	private func getPositionAndSize(for piece: PuzzlePiece, sourceImageSize: CGSize, boardSize: CGSize) -> (position: CGPoint, size: CGSize) {
		let proportionalSize = CGSize(
			width: piece.image.size.width / sourceImageSize.width,
			height: piece.image.size.height / sourceImageSize.height )
		let proportionalPosition = CGPoint(
			x: piece.positionInImage.x / sourceImageSize.width + proportionalSize.width/2,
			y: piece.positionInImage.y / sourceImageSize.height + proportionalSize.height/2)
		let size = CGSize(width: proportionalSize.width * boardSize.width,
											height: proportionalSize.height * boardSize.height)
		let position = CGPoint(x: proportionalPosition.x * boardSize.width - boardSize.width/2,
													 y: proportionalPosition.y * -boardSize.height + boardSize.height/2)
		return (position, size)
	}
	
	private func getPuzzlePieces() {
		guard let puzzleConfig = states.currentShowingCollection?.puzzleConfig else {
			return
		}
		
		let puzzleImageSource =	puzzleConfig.backgroundImage.image
		let numRows = puzzleConfig.numRows
		let numColumns = puzzleConfig.numColumns
		let darkShadow: AdjustableShadow = (
			color: .darkGray,
			offset: CGSize(width: -1.5, height: -1.5),
			blurRadius: 2)
		let lightShadow: AdjustableShadow = (
			color: .lightGray,
			offset: CGSize(width: 1.5, height: 1.5),
			blurRadius: 2)
		let puzzleMaker = PuzzleMaker(
			image: puzzleImageSource,
			numRows: numRows,
			numColumns: numColumns,
			darkInnerShadow: darkShadow,
			lightInnerShadow: lightShadow
		)
		puzzleMaker.generatePuzzles { [weak self] throwableClosure in
			guard let strongSelf = self else {
				return
			}
			var puzzlePieces = [PuzzlePiece]()
			do {
				let puzzleElements = try throwableClosure()
				for row in 0 ..< numRows {
					for column in 0 ..< numColumns {
						guard let puzzleElement = puzzleElements[row][column] else { continue }
						puzzlePieces.append(PuzzlePiece(
							numRow: row,
							numColumn: column,
							image: puzzleElement.image,
							positionInImage: puzzleElement.position))
					}
				}
				strongSelf.puzzlePieces = puzzlePieces
				strongSelf.loadPuzzles()
			}
			catch {
				print("Error from puzzle maker \(error.localizedDescription)")
			}
		}
	}
	
	enum PuzzleError: String, Error {
		case full
		case failToFindPiece
	}
}

