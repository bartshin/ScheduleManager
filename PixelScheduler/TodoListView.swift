//
//  TodoListView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/05.
//

import SwiftUI

struct TodoListView: View {
	@EnvironmentObject var settingController: SettingController
	@EnvironmentObject var taskController: TaskModelController
	@EnvironmentObject var states: ViewStates
	
	var body: some View {
		GeometryReader { geometry in
			ZStack {
				mainScene
					.onChange(of: states.presentingTaskId) {
						if $0 != nil {
							withAnimation {
								states.floatingViewsAreCollapsed = false
							}
						}
					}
				if states.isShowingList {
					drawRightBoard(in: geometry.size)
				}
				drawTopBoard(in: geometry.size)
				drawFloatingButtons(in: geometry.size)
				drawHiddenCharacterAlertView(in: geometry.size)
			}
			.edgesIgnoringSafeArea(.top)
		}
		.onChange(of: states.currentShowingCollection) {
			settingController.collectionBookmark = $0?.title
		}
	}
	
	private var mainScene: some View {
	
		return Group {
			if let style = states.currentShowingCollection?.style,
				 style == .puzzle{
				PuzzleView(states: _states)
			}else {
				PlatformerView(taskController: _taskController, settingController: _settingController,
											 states: _states)
			}
		}
	}
	
	private func drawTopBoard(in size: CGSize) -> some View {
		CategoryBoard()
			.frame(width: size.width ,
						 height: size.height * 0.6)
			.position(x: size.width * 0.5,
								y: size.height * (states.isCategoryExpanded ? 0.4: -0.2) + topBoardOffset)
			.gesture(moveTopBoard(in: size))
	}
	
	
	@State private var rightBoardOffset: CGFloat = 0
	private func drawRightBoard(in size: CGSize) -> some View {
		TaskListView(offset: $rightBoardOffset)
			.frame(width: size.width ,
						 height: size.height * 0.9)
			.transition(AnyTransition.move(edge: .trailing))
	}
	
	private func drawFloatingButtons(in size: CGSize) -> some View {
		Group {
			
			VStack(spacing: 30) {
				
				// List Button
				Button {
					withAnimation(.spring()) {
						states.isShowingList = true
						states.presentingTaskId = nil
						states.floatingViewsAreCollapsed = false
						states.isCategoryExpanded = false
					}
				} label: {
					Self.createButtonImage(for: Image(systemName: "list.dash"))
						.frame(width: 50, height: 50)
				}
				
				// New Task button
				Button {
					guard states.currentShowingCollection != nil else {
						return
					}
					withAnimation {
						states.editingTask = .init(text: "", priority: 1)
						states.presentingTaskId = states.editingTask?.id
						states.floatingViewsAreCollapsed = false
					}
				} label: {
					Image("pencil_button")
						.resizable()
						.frame(width: 50, height: 50)
				}
			}
			.position(x: size.width * 0.9,
								y: size.height * 0.9 - 30)
			.opacity(states.showingFloatingButton ? 1 : 0)
			.disabled(!states.showingFloatingButton)
		}
	}
	
	private func drawHiddenCharacterAlertView(in size: CGSize) -> some View {
		CharacterHelperView(
			character: settingController.character,
			guide: .todoList,
			showingQuickHelp: $states.isShowingQuickHelp,
			alertToPresent: $states.alert,
			helpWindowSize: CGSize(width: size.width * 0.9,
														 height: size.height * 0.8),
			balloonStartPosition:
				CGPoint(x: size.width * 0.2,
								y: size.height * 0.3))
			.position(x: size.width * 0.1, y: size.height * -0.05)
	}
	
	@State private var topBoardOffset = CGFloat(0)
	private func moveTopBoard(in size: CGSize) -> some Gesture {
		TapGesture()
			.onEnded {
				guard states.floatingViewsAreCollapsed || states.presentingTaskId == nil else {
								return
							}
				if !states.isCategoryExpanded {
					withAnimation(.spring()) {
						states.isCategoryExpanded = true
						states.floatingViewsAreCollapsed = true
						states.presentingTaskId = nil
						states.isShowingList = false
					}
				}
			}
			.simultaneously(
				with: DragGesture()
					.onChanged { dragValue in
						guard states.floatingViewsAreCollapsed || states.presentingTaskId == nil else {
										return
									}
						topBoardOffset = dragValue.translation.height
					}
					.onEnded{ dragValue in
						guard states.floatingViewsAreCollapsed || states.presentingTaskId == nil else {
										return
									}
						if (!states.isCategoryExpanded && dragValue.translation.height > size.height * 0.15) || (states.isCategoryExpanded && dragValue.translation.height < -size.height * 0.15) {
							withAnimation {
								states.isCategoryExpanded.toggle()
								if states.isCategoryExpanded {
									states.isShowingList = false
								}
								topBoardOffset = 0
							}
						}else {
							withAnimation {
								topBoardOffset = 0
							}
						}
					}
				)
	}
	
}

extension TodoListView {
	
	static func createButtonImage(for image: SwiftUI.Image, color: Color = .white) -> some View {
		ZStack {
			Image("blank_button")
				.resizable()
			image
				.foregroundColor(color)
				.padding(8)
		}
	}
}
