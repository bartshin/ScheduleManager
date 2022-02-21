//
//  TaskListView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/02/19.
//

import SwiftUI

struct TaskListView: View {
	@EnvironmentObject var settingController: SettingController
	@EnvironmentObject var taskController: TaskModelController
	@EnvironmentObject var states: ViewStates
	@Binding var offset: CGFloat
	
	var body: some View {
		GeometryReader{ geometry in
			VStack(alignment: .leading) {
				titleLabel
				
				if let collection = states.currentShowingCollection,
					 let tasks = taskController.table[collection] {
					ScrollView {
						ForEach(tasks, id: \.id) { task in
							drawLabel(for: task)
							Divider()
								.padding(.horizontal, 100)
						}
					}
				}else {
					emptyTaskLabel
				}
				Spacer()
				closeButton
					.padding(.leading, geometry.size.width * 0.7)
					.padding(.bottom, 50)
			}
			.frame(width: geometry.size.width,
						 height: geometry.size.height)
			.offset(x: (states.floatingViewsAreCollapsed ? geometry.size.width * 1: 0) + offset)
			.background(
				Image("pixel_board")
					.resizable()
					.shadow(color: .gray, radius: 5, x: 10, y: 10)
					.offset(x: (states.floatingViewsAreCollapsed ? geometry.size.width * 1: 0) + offset)
					.gesture(moveBoard(in: geometry.size))
			)
		}
	}
	
	private var titleLabel: some View {
		let emptyTitle: String
		switch settingController.language {
		case .english:
			emptyTitle = "List"
		case .korean:
			emptyTitle = "목록"
		}
		return HStack {
			Spacer()
			Text(states.currentShowingCollection?.title ?? emptyTitle)
				.withCustomFont(size: .title3, for: settingController.language)
				.foregroundColor(.white)
				.offset(y: -20)
			Spacer()
		}
		.frame(minHeight: 120, maxHeight: 150)
		.background(
			Image("title_ribbon")
				.resizable()
		)
		.padding(.top, 30)
	}
	
	private func drawLabel(for task: Task) -> some View {
		HStack {
			Image("coin")
				.resizable()
				.renderingMode(task.isCompleted ? .original: .template)
				.foregroundColor(.byPriority(task.priority))
				.frame(width: 30, height: 30)
			
			Text(task.text)
				.withCustomFont(size: .subheadline, for: settingController.language)
				.foregroundColor(Color(settingController.palette.primary))
		}
		.padding(.horizontal, 80)
		.contentShape(Rectangle())
		.onTapGesture {
			withAnimation {
				states.floatingViewsAreCollapsed = true
				states.isShowingList = false
			}
			states.showTask?(task.id)
		}
	}
	
	private var emptyTaskLabel: some View {
		let text: String
		switch settingController.language {
		case .korean:
			text = "화면 위쪽에서 모음을 먼저 골라주세요"
		case .english:
			text = "Choose your collection first at top of screen"
		}
		return Text(text)
			.withCustomFont(size: .title2, for: settingController.language)
			.foregroundColor(Color(settingController.palette.primary))
			.padding(80)
	}
	
	private var closeButton: some View {
		Button {
			withAnimation(.spring()) {
				states.floatingViewsAreCollapsed = true
			}
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
				states.isShowingList = false
			}
		}label: {
			TodoListView.createButtonImage(for: Image(systemName: "xmark"))
				.frame(width: 50, height: 50)
		}
	}
	
	private func moveBoard(in size: CGSize) -> some Gesture {
		DragGesture()
			.onChanged { dragValue in
				guard states.floatingViewsAreCollapsed || states.presentingTaskId == nil else {
					return
				}
				offset = dragValue.translation.width
			}
			.onEnded{ dragValue in
				var hideBoard: Bool? = nil
				if !states.floatingViewsAreCollapsed,
					 dragValue.translation.width > size.width * 0.3{
					hideBoard = true
				}else if states.floatingViewsAreCollapsed,
								 dragValue.translation.width < size.width * -0.3 {
					hideBoard = false
				}
				withAnimation(.spring()) {
					offset = 0
					if hideBoard == nil {
						return
					}else if hideBoard! {
						states.floatingViewsAreCollapsed = true
					}else {
						states.floatingViewsAreCollapsed = false
					}
				}
				if hideBoard != nil {
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
						withAnimation {
							states.isShowingList = !(hideBoard!)
						}
					}
				}
			}
	}
}

struct TaskListView_Previews: PreviewProvider {
	static let taskController: TaskModelController = {
		let controller = TaskModelController()
		controller.createDefaultCollection()
		return controller
	}()
	
	static let states: ViewStates = {
		let states = ViewStates()
		states.currentShowingCollection = taskController.collections.first
		return states
	}()
	
	static var previews: some View {
		TaskListView(offset: .constant(0))
			.environmentObject(SettingController())
			.environmentObject(taskController)
			.environmentObject(ViewStates())
			.frame(width: 400, height: 700)
			.border(.red)
	}
}
