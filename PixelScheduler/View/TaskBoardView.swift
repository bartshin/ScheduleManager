//
//  TaskBoardView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/02/10.
//

import SwiftUI

struct TaskBoardView: View {
	@EnvironmentObject var settingController: SettingController
	@EnvironmentObject var taskController: TaskModelController
	@EnvironmentObject var states: ViewStates
	var taskPresenting: Task? {
		guard let taskId = states.presentingTaskId,
					let collection = states.currentShowingCollection else{
						return nil
					}
		return taskController.getTask(by: taskId, from: collection)
	}
	
	@State private var editingTaskId: Task.ID? {
		willSet {
			if let taskId = newValue,
				 let task = taskController.getTask(by: taskId, from: states.currentShowingCollection){
				withAnimation {
					states.editingTask = task
				}
			}
			if newValue == nil {
				withAnimation {
					states.editingTask = nil
				}
			}
		}
	}
	
	var body: some View {
		GeometryReader { geometry in
			ZStack {
				Group {
					if states.editingTask != nil {
						drawTaskEditingView(in: geometry.size)
					}
					else if let task = taskPresenting {
						drawTaskContent(task, in: geometry.size)
					}
				}
				.padding(.top, geometry.size.height * 0.15)
				.padding(.horizontal, geometry.size.width * 0.1)
			}
			.frame(width: geometry.size.width,
						 height: geometry.size.height)
			.onDisappear {
				editingTaskId = nil
			}
		}
	}
	
	@State private var editingTaskCollection: TaskCollection?
	private func drawTaskEditingView(in boardSize: CGSize) -> some View {
		VStack {
			
			HStack {
				if taskPresenting != nil {
					editButton
				}else {
					closeButton
				}
				priorityPicker
				confirmEditButton
			}
			taskNameInput
				.frame(maxWidth: boardSize.width * 0.7)
			
			ScrollView {
				VStack(alignment: .leading) {
					ForEach(taskController.collections.filter({
						$0.style == .list
					}), content: drawSelectButton(for: ))
				}
			}
			.onAppear {
				editingTaskCollection = states.currentShowingCollection
			}
			if taskPresenting != nil {
				deleteButton
			}
			Spacer()
		}
		.padding(.bottom, boardSize.height * 0.15)
	}
	
	private var priorityPicker: some View {
		Picker(selection: .init(get: {
			states.editingTask?.priority ?? 1
		}, set: { priority in
			states.editingTask?.priority = priority
		})) {
			ForEach(1..<6) { priority in
				Image(systemName: "\(priority).circle")
					.foregroundColor(.byPriority(priority))
					.rotationEffect(Angle.init(degrees: 90))
					.tag(priority)
			}
		} label: {
			Image(systemName: "star.circle")
		}
		.pickerStyle(.inline)
		.rotationEffect(Angle.init(degrees: -90))
		.frame(width: 100, height: 50)
		.clipped()
		.padding(30)
	}
	
	private var taskNameInput: some View {
		TextField("Name", text: .init(get: {
			states.editingTask?.text ?? ""
		}, set: { name in
			states.editingTask?.text = name
		}))
			.textFieldStyle(.roundedBorder)
	}
	
	private func drawSelectButton(for collection: TaskCollection) -> some View {
		let title = Text(collection.title)
			.withCustomFont(size: .headline, for: settingController.language)
		let icon = Image(systemName: collection.style.iconImageName)
		return Button {
			withAnimation {
				editingTaskCollection = collection
			}
		}label: {
			HStack {
				title
				icon
			}
			.padding(5)
			.background(
				RoundedRectangle(cornerRadius: 20)
					.stroke()
			)
			.opacity(editingTaskCollection == collection ? 1: 0.3)
		}
		.buttonStyle(ChangingColorButtonStyle(
			defaultColor: Color(settingController.palette.secondary.withAlphaComponent(0.5)),
			activeColor: Color(settingController.palette.primary), activeBinding: .init(get: {
				editingTaskCollection == collection
			}, set: { isSelected in
				if isSelected {
					editingTaskCollection = collection
				}
			})))
	}
	
	private var deleteButton: some View {
		Button {
			guard let task = taskPresenting,
						let collection = states.currentShowingCollection else {
				return
			}
			states.floatingViewsAreCollapsed = true
			states.presentingTaskId = nil
			taskController.deleteTask(task, in: collection)
		} label: {
			TodoListView.createButtonImage(
				for:
						Image(systemName: "trash").renderingMode(.template), color: .red)

		}
		.frame(width: 50, height: 50)
	}
	
	private func drawTaskContent(_ task: Task, in boardSize: CGSize) -> some View {
		VStack {
			HStack {
				closeButton
				Spacer()
				drawStampButton(for: task, in: boardSize)
				Spacer()
				editButton
			}
			.fixedSize(horizontal: false, vertical: true)
			
			Text(task.text)
				.withCustomFont(size: .title, for: settingController.language)
				.foregroundColor(.byPriority(task.priority))
			MarkdownView(markdownText: task.mdText) { text in
				guard let collection = states.currentShowingCollection,
							task.text != text else {
								return
							}
				var newTask = task
				newTask.mdText = text
				taskController.changeTask(from: task, to: newTask, in: collection)
			}
			.frame(height: boardSize.height * 0.8)
		}
	}
	
	private var editButton: some View {
		Button {
			guard states.presentingTaskId != nil else {
				return
			}
			withAnimation {
				if editingTaskId == nil {
					editingTaskId = states.presentingTaskId
				}else {
					editingTaskId = nil
				}
			}
		} label: {
			Group {
				if editingTaskId == nil {
					Image("pencil_button")
						.resizable()
				}else {
					TodoListView.createButtonImage(for: Image(systemName: "xmark"))
				}
			}
			.frame(width: 50, height: 50)
		}
	}
	
	private var closeButton: some View {
		Button {
			withAnimation(.easeIn) {
				states.floatingViewsAreCollapsed = true
			}
			if taskPresenting == nil {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
					states.presentingTaskId = nil
				}
			}
		} label: {
			TodoListView.createButtonImage(for: Image(systemName: "xmark"))
		}
		.frame(width: 50, height: 50)
	}
	
	private var confirmEditButton: some View {
		Button {
			guard let newTask = states.editingTask,
						let collection = states.currentShowingCollection
					 else {
							return
						}
			if let oldTaskId = editingTaskId,
				 let oldTask = taskController.getTask(by: oldTaskId, from: collection){
				if let newCollection = editingTaskCollection,
				newCollection != collection{
					taskController.deleteTask(oldTask, in: collection)
					taskController.addNewTask(newTask, in: newCollection)
				}else {
					taskController.changeTask(from: oldTask, to: newTask, in: collection)
				}
			}else {
				taskController.addNewTask(newTask, in: collection)
			}
			states.floatingViewsAreCollapsed = true
			states.presentingTaskId = nil
			withAnimation {
				editingTaskId = nil
			}
		} label: {
			Image("checkmark_button")
				.resizable()
				.frame(width: 50, height: 50)
		}
	}
	
	private func drawStampButton(for task: Task, in boardSize: CGSize) -> some View {
		let buttonSize = CGSize(width: task.isCompleted ? 60: 50,
														height: task.isCompleted ? 60: 50)
		return Button {
			guard let currentShowingCollection = states.currentShowingCollection else {
				return
			}
			SoundEffect.playSound(.coinBonus)
			var newTask = task
			newTask.isCompleted = !task.isCompleted
			taskController.changeTask(from: task, to: newTask, in: currentShowingCollection)
		}label: {
			Image("completed_stamp\(task.text.count % 4 + 1)")
				.resizable()
				.renderingMode(.template)
				.foregroundColor(task.isCompleted ? .red: .gray)
				.frame(width: buttonSize.width,
							 height: buttonSize.height)
				.background(
					Circle()
						.stroke(task.isCompleted ? .red: .gray, lineWidth: 2)
						.frame(width: buttonSize.width * 1.2,
									 height: buttonSize.height * 1.2)
				)
				.opacity(task.isCompleted ? 1: 0.3)
		}
	}
}
