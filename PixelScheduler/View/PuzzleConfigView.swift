//
//  PuzzleConfigView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/02/15.
//

import SwiftUI

struct PuzzleConfigView: View {
	
	@Environment(\.colorScheme) var colorScheme
	@EnvironmentObject var taskController: TaskModelController
	@EnvironmentObject var settingController: SettingController
	@Binding var showingCollection: (TaskCollection?)
	@Binding var isPresenting: Bool
	@Binding var alert: (CharacterAlert<Text, Text>?)
	@State private var puzzleBackground: TaskCollection.PuzzleBackground
	@State private var numRows: Int
	@State private var numColumns: Int
	
	init(presenting: Binding<Bool>,
			 showingCollection: Binding<TaskCollection?>,
			 alert: Binding<CharacterAlert<Text, Text>?>) {
		_isPresenting = presenting
		_showingCollection = showingCollection
		_alert = alert
		if let config = showingCollection.wrappedValue?.puzzleConfig {
			_puzzleBackground = .init(initialValue: config.backgroundImage)
			_numRows = .init(initialValue: config.numRows)
			_numColumns = .init(initialValue: config.numColumns)
		}else {
			_puzzleBackground = .init(initialValue: .backToSchool)
			_numRows = .init(initialValue: 4)
			_numColumns = .init(initialValue: 4)
		}
		
	}
	
	var body: some View {
		GeometryReader { geometry in
			VStack(spacing: 20) {
				HStack {
					if showingCollection?.puzzleConfig != nil {
						closeButton
					}
					Spacer()
					settingLabel
					Spacer()
					confirmButton
				}
				numRowPicker
				numColumnPicker
				imagePicker
					.frame(width: geometry.size.width * 0.6)
				Spacer()
			}
			.padding(.vertical, geometry.size.height * 0.2)
			.padding(.horizontal, geometry.size.width * 0.2)
			.background(
				Image("puzzle_sheaves")
					.resizable()
					.renderingMode(.template)
					.foregroundColor(isDarkMode ? .black: .white)
					.scaleEffect(CGSize(width: 1.5,
															height: 1.3))
					.shadow(color: .gray,
									radius: 5,
									x: 10,
									y: 20)
			)
		}
	}
	
	private var settingLabel: some View {
		let text: String
		switch settingController.language {
		case .korean:
			text = "설정"
		case .english:
			text = "Settings"
		}
		return Text(text)
			.withCustomFont(size: .headline,
											for: settingController.language)
	}
	
	private var closeButton: some View {
		Button {
			withAnimation(.spring()) {
				isPresenting = false
			}
		} label: {
			TodoListView.createButtonImage(for: Image(systemName: "xmark"), color: Color(.lightGray))
				.frame(width: 50, height: 50)
		}
	}
	
	private var confirmButton: some View {
		Button {
			guard let showingCollection = showingCollection else {
				return
			}
			guard let taskCount = taskController.table[showingCollection]?.count,
						taskCount < numColumns * numRows else {
							let title: String
							let message: String
							let dismiss: String
							switch settingController.language {
							case .english:
								title = "Invaild config"
								message = "Puzzles in collection are more than selected number of puzzle pieces"
								dismiss = "OK"
							case .korean:
								title = "설정 실패"
								message = "해당 모음에 들어있는 퍼즐이 선택된 퍼즐 갯수보다 많습니다"
								dismiss = "확인"
							}
							alert = .init(title: title,
														message: message,
														action: {},
														label: {
								Text(dismiss)
							})
							return
						}
			var newCollection = showingCollection
			newCollection.puzzleConfig = TaskCollection.PuzzleConfig(
				backgroundImage: puzzleBackground,
				numRows: numRows,
				numColumns: numColumns)
			taskController.changeCollection(from: showingCollection, to: newCollection)
			self.showingCollection = newCollection
			withAnimation (.spring()) {
				isPresenting = false
			}
		}label: {
			Image("checkmark_button")
				.resizable()
				.frame(width: 50, height: 50)
		}
	}
	
	private var numRowPicker: some View {
		let labelText: String
		switch settingController.language {
		case .korean:
			labelText = "열 개수"
		case .english:
			labelText = "Rows"
		}
		return HStack {
			Text(labelText)
				.withCustomFont(size: .subheadline, for: settingController.language)
			Picker(selection: $numRows) {
				ForEach(3..<7) { number in
						Text(String(number))
						.tag(number)
				}
			} label: {
				EmptyView()
			}
			.pickerStyle(.segmented)
		}
	}
	
	private var numColumnPicker: some View {
		let labelText: String
		switch settingController.language {
		case .korean:
			labelText = "행 개수"
		case .english:
			labelText = "Columns"
		}
		return HStack {
			Text(labelText)
				.withCustomFont(size: .subheadline, for: settingController.language)
			Picker(selection: $numColumns) {
				ForEach(3..<6) { number in
					Text(String(number))
						.tag(number)
				}
			} label: {
				EmptyView()
			}
			.pickerStyle(.segmented)
		}
	}
	
	private var imagePicker: some View {
		let labelText: String
		switch settingController.language {
		case .korean:
			labelText = "퍼즐 이미지"
		case .english:
			labelText = "Puzzle Image"
		}
		
		return VStack {
			Text(labelText)
				.withCustomFont(size: .headline, for: settingController.language)
			
			Picker(selection: $puzzleBackground) {
				
				ForEach(TaskCollection.PuzzleBackground.allCases, id: \.rawValue) { background in
					ZStack {
						Image(uiImage: background.image)
							.resizable()
							.opacity(background == puzzleBackground ? 1: 0.2)
							.zIndex(background == puzzleBackground ? 1: 0)
						Text(background.pickerName)
							.font(.subheadline)
							.fontWeight(.heavy)
							.foregroundColor(.white)
							.zIndex(2)
					}
					.frame(width: 200, height: 150)
					
					.tag(background)
				}
			} label: {
				EmptyView()
			}
			.pickerStyle(.wheel)
		}
	}
	
	private var isDarkMode: Bool {
		switch settingController.visualMode {
		case .dark:
			return true
		case .light:
			return false
		case .system:
			return colorScheme == .dark
		}
	}
	
}
