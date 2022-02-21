//
//  PuzzleView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/02/14.
//

import SwiftUI
import SceneKit

struct PuzzleView: View {

	@EnvironmentObject var settingController: SettingController
	@EnvironmentObject var taskController: TaskModelController
	@EnvironmentObject var states: ViewStates
	@State private var puzzleScene: PuzzleScene
	@State private var presentingConfig: Bool
	@State private var presentingTask = false
	
	init(states: EnvironmentObject<ViewStates>) {
		_states = states
		_puzzleScene = .init(
			initialValue: PuzzleScene(states: states.wrappedValue))
		_presentingConfig = .init(initialValue: states.wrappedValue.currentShowingCollection?.puzzleConfig == nil )
	}
	
	var body: some View {
		GeometryReader { geometry in
			ZStack {
				if presentingConfig{
					Color(settingController.palette.quaternary.withAlphaComponent(0.5))
						.transition(.opacity)
					PuzzleConfigView(presenting: .init(get: {
						presentingConfig
					}, set: {
						presentingConfig = $0
						states.floatingViewsAreCollapsed = !$0
					}),
													 showingCollection: $states.currentShowingCollection,
													 alert: $states.alert)
						.frame(width: geometry.size.width ,
									 height: geometry.size.height)
						.position(x: geometry.size.width/2,
											y: geometry.size.height/2)
						.transition(.move(edge: .leading))
						.onAppear {
							withAnimation {
								states.floatingViewsAreCollapsed = false
							}
						}
				}
				else {
					SceneView(scene: puzzleScene.scene,
										pointOfView: puzzleScene.cameraNode,
										options: [])
						.gesture(
							DragGesture(minimumDistance: 0)
								.onEnded{ dragValue in
									guard states.floatingViewsAreCollapsed,
												!states.isCategoryExpanded else {
													return
												}
									let location = dragValue.startLocation
									puzzleScene.handleTap(at: location, in: geometry.size) { task in
										withAnimation {
											states.presentingTaskId = task?.id
											presentingTask = true
											states.floatingViewsAreCollapsed = true
										}
									}
								}
						)
					if states.floatingViewsAreCollapsed {
						puzzleSettingButton
							.position(x: geometry.size.width * 0.1,
												y: geometry.size.height * 0.88)
					}
				}
				drawPuzzleDetailView(in: geometry.size)
					.frame(width: geometry.size.width * 0.8,
								 height: geometry.size.height * 0.7)
			}
			.onAppear {
				puzzleScene.settingController = settingController
				puzzleScene.taskController = taskController
				puzzleScene.setUp()
				puzzleScene.collectionDidChanged()
				states.showTask = { taskId in
					do {
						try puzzleScene.showTask(taskId: taskId) { taskId in
							withAnimation {
								states.presentingTaskId = taskId
								presentingTask = true
								states.floatingViewsAreCollapsed = true
							}
						}
					}catch {
						print(error)
					}
				}
			}
			.onChange(of: states.currentShowingCollection) { _ in
				puzzleScene.collectionDidChanged()
				withAnimation(.spring()) {
					presentingConfig = states.currentShowingCollection?.puzzleConfig == nil
				}
			}
			.onChange(of: states.taskSort) { _ in
				puzzleScene.taskSortDidChanged()
			}
			.onChange(of: states.editingTask) {
				if !presentingTask, $0 != nil {
					do {
						try puzzleScene.startPresenting { _ in
							withAnimation {
								presentingTask = true
							}
						}
					}catch {
						guard let error = error as? PuzzleScene.PuzzleError,
									error != .failToFindPiece else {
										assertionFailure("Fail to present piece for unknown issue")
										return
						}
						DispatchQueue.main.async {
							states.editingTask = nil
							states.presentingTaskId = nil
							states.floatingViewsAreCollapsed = true
						}
						showFullPuzzleAlert()
					
					}
				}
			}
			.onChange(of: presentingTask) { _ in
				if settingController.soundEffect == .on {
					SoundEffect.playSound(.puzzleFlip)
				}
			}
		}
	}
	
	private func showFullPuzzleAlert() {
		let title: String
		let message: String
		let dismiss: String
		switch settingController.language {
		case .korean:
			title = "퍼즐 추가 실패"
			message = "퍼즐에 빈 공간이 없습니다 더 큰퍼즐로 변경해주세요"
			dismiss = "확인"
		case .english:
			title = "Fail to add puzzle piece"
			message = "No more space in puzzle board change puzzle size"
			dismiss = "OK"
		}
		states.alert = .init(title: title,
									message: message,
									action: {},
									label: {
			Text(dismiss)
		})
	}
	
	private func drawPuzzleDetailView(in size: CGSize) -> some View {
		
		Group {
			if presentingTask {
				PuzzleDetailView(puzzleScene: puzzleScene,
												 isPresenting: $presentingTask)
					.background(
						showBackgroundBlur(cancelHandler: hideKeyboard)
							.clipShape(RoundedRectangle(cornerRadius: 20))
					)
			}
		}
		.rotation3DEffect(Angle(degrees: presentingTask ? 0: -90), axis: (x: 0, y: 1, z: 0))
		.opacity(presentingTask ? 1: 0)
	}
	
	private var puzzleSettingButton: some View {
		Button {
			withAnimation(.spring()) {
				states.floatingViewsAreCollapsed = false
				presentingConfig = true
			}
		} label: {
			TodoListView.createButtonImage(for: Image(systemName: "gear"))
				.frame(width: 50, height: 50)
		}
	}
}

