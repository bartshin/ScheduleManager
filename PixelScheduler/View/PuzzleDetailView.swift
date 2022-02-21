//
//  PuzzleDetailView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/02/17.
//

import SwiftUI

struct PuzzleDetailView: View {
	
	@EnvironmentObject var taskController: TaskModelController
	@EnvironmentObject var settingController: SettingController
	let puzzleScene: PuzzleScene
	@Binding var isPresenting: Bool
	@EnvironmentObject var states: ViewStates
	@State private var isShowingLog: Bool = false
	
	var taskPresenting: Task? {
		if let presentingTaskId = states.presentingTaskId {
			return taskController.getTask(by: presentingTaskId, from: states.currentShowingCollection)
		}else {
			return nil
		}
	}

	var body: some View {
		GeometryReader { geometry in
			VStack(spacing: 30) {
				HStack{
					closeButton
					if states.editingTask != nil {
						priorityPicker
							.layoutPriority(-1)
						confirmButton
					}else if let task = taskPresenting {
						Spacer()
						Text(task.text)
						Spacer()
						editButton
					}
				}
				if states.editingTask != nil {
					titleInput
					if isShowingLog {
						createLogView
					}else {
						createLogButton
					}
				}
				if taskPresenting != nil,
					 states.editingTask == nil {
					drawStampButton(in: geometry.size)
					if isShowingLog {
						logView
					}else if !(taskPresenting?.isCompleted ?? true) {
						createLogButton
					}
				}
			}
		}
		.padding(20)
		.onAppear {
			isShowingLog = taskPresenting?.completionLog != nil
		}
	}
	
	@State private var newHistory = Task.CompletionLog.History(addedAmount: 0, date: Date())
	@State private var newLog = Task.CompletionLog(
		unit: "%",
		total: 100,
		histories: [])
	
	private var titleInput: some View {
		TextField("Title", text: .init(get: {
			states.editingTask?.text ?? ""
		}, set: {
			states.editingTask?.text = $0
		}))
			.textFieldStyle(.roundedBorder)
	}
	
	private var createLogButton: some View {
		let text: String
		switch settingController.language {
		case .english:
			text = "Create detail"
		case .korean:
			text = "세부항목 만들기"
		}
		return Button {
			withAnimation(.spring()) {
				isShowingLog = true
			}
		} label: {
			Text(text)
				.withCustomFont(size: .headline, for: settingController.language)
				.foregroundColor(.white)
		}
	}
	
	private var logView: some View {
		Group {
			if let taskPresenting = taskPresenting,
 				let log = taskPresenting.completionLog {
				VStack {
					drawLogTitle(for: log)
					ScrollViewReader { scrollView in
						ScrollView {
							ForEach(log.histories) {
								drawLogHistory($0, in: log)
							}
						}
						.onAppear {
							scrollToLastHistoryIfExist(in: log, scrollView: scrollView)
						}
						.onReceive(taskController.objectWillChange) { _ in
							scrollToLastHistoryIfExist(in: log, scrollView: scrollView)
						}
					}
					if log.current < log.total {
						drawLogInput(for: log)
					}
				}
			}else {
				createLogView
			}
		}
	}
	
	private func scrollToLastHistoryIfExist(in log: Task.CompletionLog, scrollView: ScrollViewProxy) {
		if let lastHistory = log.histories.last {
			withAnimation {
				scrollView.scrollTo(lastHistory.id, anchor: nil)
			}
		}
	}

	private func drawLogTitle(for log: Task.CompletionLog) -> some View {
		let detailText: String
		let totalText: String
		switch settingController.language {
		case .english:
			detailText = "Details"
			totalText = "Total"
		case .korean:
			detailText = "상세"
			totalText = "총"
		}
		
		return HStack {
			Text(detailText)
			Text("(\(totalText) \(log.total.stringTrimedDecimalIfZero)\(log.unit))")
		}
		.font(.headline)
	}
	
	private func drawLogInput(for log: Task.CompletionLog) -> some View {
		HStack(spacing: 10) {
			TextField("", text: .init(get: {
				newHistory.addedAmount.stringTrimedDecimalIfZero
			}, set: { input in
				let newAmount = min((Double(input) ?? 0), log.total - log.current)
				newHistory = .init(addedAmount: newAmount, date: Date())
			}))
				.keyboardType(.numbersAndPunctuation)
				.textFieldStyle(.roundedBorder)
				.frame(width: 100)
			Text(log.unit)
				.font(.headline)
			Button {
				var newTask = taskPresenting!
				newTask.completionLog?.addHistory(newHistory)
				taskController.changeTask(from: taskPresenting!, to: newTask, in: states.currentShowingCollection!)
				newHistory = Task.CompletionLog.History(addedAmount: 0, date: Date())
			hideKeyboard()
			}label: {
				TodoListView.createButtonImage(for: Image(systemName: "plus"))
					.frame(width: 40, height: 40)
			}
		}
	}
	
	private func drawLogHistory(_ history: Task.CompletionLog.History, in log: Task.CompletionLog) -> some View {
		let addedText: String
		
		switch settingController.language {
		case .english:
			addedText = "added"
		case .korean:
			addedText = "추가"
		}
		
		return	VStack(alignment: .trailing) {
			HStack {
				Text(history.addedAmount.stringTrimedDecimalIfZero + log.unit)
				Text(addedText)
				Text("(~\(log.calcAccumulation(to: history.date).stringTrimedDecimalIfZero)\(log.unit))")
					.font(.caption)
			}
			.font(.body)
			Text(history.date.dayShortString + "  " + history.date.trimTimeString())
				.font(.caption)
				.foregroundColor(.gray)
			Divider()
		}
		.padding(.leading, 50)
		.id(history.id)
	}

	private var createLogView: some View {
		VStack {
			createLogLabel
			HStack(spacing: 20) {
				totalLabel
				TextField("Total", text: .init(get: {
					newLog.total.stringTrimedDecimalIfZero
				}, set: { input in
					newLog.total = Double(input) ?? 0
				}))
					.keyboardType(.numbersAndPunctuation)
					.textFieldStyle(.roundedBorder)
					.frame(width: 100)
				TextField("Unit", text: $newLog.unit)
					.textFieldStyle(.roundedBorder)
					.frame(width: 50)
			}
			if states.editingTask == nil {
				confirmLogButton
			}
		}
	}
	
	private var confirmLogButton: some View {
		let text: String
		switch settingController.language {
		case .korean:
			text = "확인"
		case .english:
			text = "Done"
		}
		
		return Button {
			guard !newLog.unit.isEmpty ,
						newLog.total > 0 else {
							// TODO: Show error message to user about invalid input
							fatalError()
						}
			var task = taskPresenting!
			task.completionLog = newLog
			taskController.changeTask(from: taskPresenting!,
																to: task,
																in: states.currentShowingCollection!)
		} label: {
			Text(text)
				.withCustomFont(size: .headline, for: settingController.language)
		}
	}
	
	private var createLogLabel: some View {
		let text: String
		switch settingController.language {
		case .english:
			text = "Set total amount to complete"
		case .korean:
			text = "완료할 양을 정하기"
		}
		return Text(text)
			.withCustomFont(size: .subheadline, for: settingController.language)
	}
	
	private var totalLabel: some View {
		let text: String
		switch settingController.language {
		case .english:
			text = "Total"
		case .korean:
			text = "총"
		}
		return Text(text)
			.withCustomFont(size: .body, for: settingController.language)
	}
	
	private var closeButton: some View {
		Button {
			if states.editingTask == nil ||
					(states.editingTask != nil && taskController.getTask(by: states.presentingTaskId!, from: states.currentShowingCollection) == nil) {
				puzzleScene.endPresenting()
				withAnimation (.spring()) {
					isPresenting = false
					states.floatingViewsAreCollapsed = true
				}
			}
			states.editingTask = nil
		} label: {
			TodoListView.createButtonImage(for: Image(systemName: "xmark"))
				.frame(width: 40, height: 40)
		}
	}
	
	private var confirmButton: some View {
		Button {
			guard var taskEdited = states.editingTask,
						let collection = states.currentShowingCollection else {
							assertionFailure("No task to save")
							return
						}
			if let presentingTaskId = states.presentingTaskId,
				 let oldTask = taskController.getTask(by: presentingTaskId, from: collection) {
				taskController.changeTask(from: oldTask, to: taskEdited, in: collection)
				withAnimation {
					states.editingTask = nil
				}
			}else {
				if isShowingLog {
					taskEdited.completionLog = newLog
				}
				taskController.addNewTask(taskEdited, in: collection)
				states.editingTask = nil
				withAnimation {
					isPresenting = false
					states.floatingViewsAreCollapsed = true
				}
				puzzleScene.endPresenting()
			}
		} label: {
			Image("checkmark_button")
				.resizable()
				.frame(width: 40, height: 40)
		}
	}
	
	private var priorityPicker: some View {
		Picker(selection: .init(get: {
			states.editingTask?.priority ?? 1
		}, set: {
			states.editingTask?.priority = $0
		})) {
			ForEach(1..<6) { number in
				Image(systemName: "\(number).circle")
					.foregroundColor(.byPriority(number))
					.rotationEffect(Angle(degrees: 90))
					.tag(number)
			}
		} label: {
			EmptyView()
		}
		.pickerStyle(.inline)
		.rotationEffect(Angle.init(degrees: -90))
		.frame(height: 50)
		.frame(maxWidth: 100)
		.clipped()
		.padding(30)
	}
	
	private var editButton: some View {
		Button {
			guard let task = taskController.getTask(by: states.presentingTaskId!, from: states.currentShowingCollection) else {
				assertionFailure("Cannot find task to edit")
				return
			}
			withAnimation {
				states.editingTask = task
			}
		}label: {
			Image("pencil_button")
				.resizable()
				.frame(width: 40, height: 40)
		}
	}
	
	private func drawStampButton(in size: CGSize) -> some View {
		guard let task = taskController.getTask(by: states.presentingTaskId!, from: states.currentShowingCollection) else {
			fatalError("Cannot find task to complete")
		}
		let radius = min(size.width * 0.3, size.height * 0.3)
		let buttonSize = CGSize(width: radius, height: radius)
		return Button {
			var newTask = task
			newTask.isCompleted = !task.isCompleted
			taskController.changeTask(from: task, to: newTask, in: states.currentShowingCollection!)
			if newTask.isCompleted,
				 settingController.soundEffect == .on {
				SoundEffect.playSound(.coinBonus)
			}
		} label: {
			ZStack {
				Image("completed_stamp\(task.text.count % 4 + 1)")
					.resizable()
					.renderingMode(.template)
					.foregroundColor(task.isCompleted ? .red: .byPriority(task.priority))
					.frame(width: buttonSize.width,
								 height: buttonSize.height)
					.background(
						Circle()
							.stroke(task.isCompleted ? .red: .gray, lineWidth: 2)
							.frame(width: buttonSize.width * 1.2,
										 height: buttonSize.height * 1.2)
					)
					.opacity(getStampOpacity(for: task))
				if let completionLog = task.completionLog {
					drawPartialComplete(log: completionLog)
				}
			}
		}
	}
	
	private func drawPartialComplete(log: Task.CompletionLog) -> some View {
		let doneText: String
		switch settingController.language {
		case .korean:
			doneText = "완료"
		case .english:
			doneText = "Done"
		}
		
		let percentage = (log.current / log.total) * 100
		let percentageRounded = (percentage * 100).rounded() / 100
		
		return Text("\(percentageRounded.stringTrimedDecimalIfZero)% \(doneText)")
			.foregroundColor(Color(settingController.palette.primary))
			.padding(3)
			.background(
				RoundedRectangle(cornerRadius: 10)
					.fill(Color(.systemBackground))
			)
	}
	
	private func getStampOpacity(for task: Task) -> CGFloat {
		if let log = task.completionLog {
			return CGFloat(log.current / log.total)
		}else {
			return task.complete ? 1: 0.3
		}
	}
}
