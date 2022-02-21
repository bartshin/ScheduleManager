//
//  PlatformerView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/02/18.
//

import SwiftUI
import SpriteKit

struct PlatformerView: View {
	
	@EnvironmentObject var taskController: TaskModelController
	@EnvironmentObject var settingController: SettingController
	@EnvironmentObject var states: ViewStates
	@State private var platfomerScene: PlatformerScene
 
	init(taskController: EnvironmentObject<TaskModelController>,
			 settingController: EnvironmentObject<SettingController>,
			 states: EnvironmentObject<ViewStates>) {
		_taskController = taskController
		_settingController = settingController
		_states = states
		_platfomerScene = .init(initialValue:	PlatformerScene(
			taskController: taskController.wrappedValue,
			settingController: settingController.wrappedValue,
			states: states.wrappedValue))
	}
	var body: some View {
		GeometryReader { geometry in
			ZStack {
				SpriteView(scene: platfomerScene)
					.onAppear {
						platfomerScene.size = geometry.size
					}
				if states.presentingTaskId != nil {
					drawTaskBoard(in: geometry.size)
				}
				if states.floatingViewsAreCollapsed || states.presentingTaskId == nil {
					drawAttackButton(in: geometry.size)
				}
			}
			.onAppear {
				states.showTask = { taskId in
					platfomerScene.showTask(taskId: taskId)
					if settingController.soundEffect == .on {
						SoundEffect.playSound(.teleport)
					}
				}
			}
		}
	}
	
	private func drawTaskBoard(in size: CGSize) -> some View {
		let boardSize = CGSize(width: size.width * 0.9,
													 height: size.height * 0.9)
		return TaskBoardView()
			.frame(width: boardSize.width,
						 height: boardSize.height)
			.offset(x: (states.floatingViewsAreCollapsed ? boardSize.width * 1: 0) + taskBoardOffset)
			.background(
				Image("iron_board")
					.resizable()
					.frame(width: boardSize.width,
								 height: boardSize.height)
					.offset(x: (states.floatingViewsAreCollapsed ? boardSize.width * 1: 0) + taskBoardOffset)
					.gesture(moveTaskBoard(in: size))
			)
			.transition(.move(edge: .trailing))
	}
	
	private func drawAttackButton(in size: CGSize) -> some View {
		
		Button {
			platfomerScene.triggerAttack()
		}label: {
			TodoListView.createButtonImage(for: Image("sword").resizable())
		}
		.frame(width: 50, height: 50)
		.position(x: size.width * 0.1,
							y: size.height * 0.9)
		.opacity(states.showingFloatingButton ? 1: 0)
		.disabled(!states.showingFloatingButton)
	}
	
	@State private var taskBoardOffset: CGFloat = 0
	private func moveTaskBoard(in size: CGSize) -> some Gesture {
		DragGesture()
			.onChanged { dragValue in
				guard  !states.isCategoryExpanded else {
								return
							}
				taskBoardOffset = dragValue.translation.width
			}
			.onEnded { dragValue in
				guard !states.isCategoryExpanded else {
								return
							}
				var hideTaskBoard: Bool? = nil
				if !states.floatingViewsAreCollapsed,
					 dragValue.translation.width > size.width * 0.3{
					hideTaskBoard = true
				}else if states.floatingViewsAreCollapsed,
								 dragValue.translation.width < size.width * -0.3 {
					hideTaskBoard = false
				}
				withAnimation {
					taskBoardOffset = 0
					if hideTaskBoard == nil {
						return
					}else if hideTaskBoard! {
						states.floatingViewsAreCollapsed = true
					}else {
						states.floatingViewsAreCollapsed = false
					}
				}
			}
			.simultaneously(
				with: TapGesture()
					.onEnded {
						if states.floatingViewsAreCollapsed {
							withAnimation {
								states.floatingViewsAreCollapsed = false
							}
						}
					}
			)
	}
}
