//
//  CategoryBoard.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/02/10.
//

import SwiftUI

struct CategoryBoard: View {
	
	@EnvironmentObject var settingController: SettingController
	@EnvironmentObject var taskController: TaskModelController
	@EnvironmentObject var states: ViewStates
	@State private var isEditingCategory = false
	@State private var newCollection: TaskCollection?
	@State private var editingCollection: TaskCollection?
	 
	var body: some View {
		GeometryReader { geometry in
			VStack {
				HStack {
					if isEditingCategory {
						Button {
							withAnimation(.spring()) {
								newCollection = newCollection == nil ? .init(style: .list, title: ""): nil
							}
						} label: {
							TodoListView.createButtonImage(for: Image(systemName: newCollection == nil ? "plus": "xmark"))
						}
						.frame(width: 40, height: 40)
					}
					Spacer()
					Text(categoryString)
						.fontWeight(.heavy)
						.withCustomFont(size: .title, for: settingController.language)
						.foregroundColor(.white)
						.frame(maxWidth: geometry.size.width * 0.5,
									 minHeight: geometry.size.height * 0.3 )
						.background(
							Image("leaf_label")
								.resizable()
						)
					Spacer()
					if newCollection == nil {
						Button {
							withAnimation {
								if isEditingCategory {
									newCollection = nil
								}
								isEditingCategory.toggle()
							}
						}label: {
							Image(isEditingCategory ? "checkmark_button": "pencil_button")
								.resizable()
						}
						.frame(width: 40, height: 40)
					}
				}
				.padding(.top, geometry.size.height * 0.05)
				.padding(.horizontal, geometry.size.width * 0.15)
				if newCollection != nil {
					HStack(spacing: 10) {
						Picker(selection: .init(get: {
							newCollection?.style.rawValue ?? ""
						}, set: { newStyle in
							newCollection?.style = .init(rawValue: newStyle)!
						}), content: {
							ForEach([TaskCollection.Style.list, .puzzle], id: \.rawValue) { style in
								Image(systemName: style.iconImageName)
									.foregroundColor(.white)
									.tag(style.rawValue)
							}
						}, label: {
							EmptyView()
						})
							.pickerStyle(.menu)
							.frame(width: 50, height: 50)
						TextField("Title", text: .init(get: {
							newCollection!.title
						}, set: { newTitle in
							newCollection?.title = newTitle
						}))
							.textFieldStyle(.roundedBorder)
						Button {
							guard let newCollection = newCollection,
										!newCollection.title.isEmpty else {
								return
							}
							taskController.addNewCollection(newCollection)
							withAnimation(.spring()) {
								self.newCollection = nil
							}
						} label: {
							Image(systemName: "checkmark.circle")
								.resizable()
								.foregroundColor(newCollection!.title.isEmpty ? .gray: .white)
								.frame(width: 40, height: 40)
						}
					}
					.padding(.horizontal)
					.frame(height: 60)
				}
				if newCollection == nil {
					let collections = taskController.collections
					if collections.count > 5 {
						ScrollView {
							VStack {
								ForEach(taskController.collections.sorted(by: {
									$0.title < $1.title
								})) {
									drawCollectionLabel($0)
								}
							}
						}
					}else {
						VStack {
							ForEach(taskController.collections) {
								drawCollectionLabel($0)
							}
						}
					}
				}
				if !isEditingCategory {
					Spacer()
					HStack {
						Text(orderString)
							.fontWeight(.heavy)
							.withCustomFont(size: .subheadline, for: settingController.language)
							.foregroundColor(.white)
							.padding(.horizontal, 50)
							.padding(.vertical, 15)
							.background(
								Image("leaf_label")
									.resizable()
							)
						
						ForEach(Task.Sort.allCases) { sort in
							Button {
								withAnimation {
									states.taskSort = sort
								}
							} label: {
								getLabelForTaskSort(sort)
									.frame(width: 30, height: 30)
									.scaleEffect(states.taskSort == sort ? 1.2: 1)
									.opacity(states.taskSort == sort ? 1: 0.4)
									.rotationEffect(states.currentShowingCollection?.style == .puzzle ? Angle(degrees: 150): Angle(degrees: 0))
							}
						}
					}
				}
				Spacer()
			}
			.background(
				Image("wooden_board")
					.resizable()
					.frame(width: geometry.size.width,
								 height: geometry.size.height)
			)
		}
	}
	
	private func drawCollectionLabel(_ collection: TaskCollection) -> some View {
		let language = LanguageDetector.detect(for: collection.title) ?? .english
		let title = Text(collection.title)
			.withCustomFont(size: .headline, for: language)
		let icon = Image(systemName: collection.style.iconImageName)
			.font(.title2)
		return Group {
			if isEditingCategory {
				HStack {
					if editingCollection?.id == collection.id {
						TextField("Collection name", text: .init(get: {
							editingCollection?.title ?? ""
						}, set: { newTitle in
							editingCollection?.title = newTitle
						}))
							.textFieldStyle(.roundedBorder)
							.onDisappear {
								editingCollection = nil
							}
							.frame(maxWidth: 150)
						Button {
							guard let oldCollection = taskController.collections.first(where: {
								$0.id == editingCollection?.id
							}),
										let newCollection = editingCollection else {
											assertionFailure("Cannot find collections to modify")
											return
										}
							taskController.changeCollection(from: oldCollection, to: newCollection)
							withAnimation {
								editingCollection = nil
							}
						} label: {
							Image(systemName: "checkmark.circle")
								.resizable()
								.frame(width: 40, height: 40)
								.foregroundColor(.white)
						}
					}else {
						title
							.onTapGesture {
								withAnimation {
									if editingCollection != nil {
										editingCollection = nil
									}else {
										editingCollection = collection
									}
								}
							}
						Button {
							taskController.deleteCollection(collection)
							if collection == states.currentShowingCollection {
								withAnimation {
									states.currentShowingCollection = nil
								}
							}
						}label: {
							Image(systemName: "trash.circle")
								.resizable()
								.frame(width: 30, height: 30)
								.foregroundColor(.red)
						}
					}
				}
			}else {
				Button {
					withAnimation {
						states.floatingViewsAreCollapsed = true
						states.isCategoryExpanded = false
					}
					states.currentShowingCollection = collection
				} label: {
					HStack {
						title
						icon
					}
				}
				.buttonStyle(ChangingColorButtonStyle(
					defaultColor: .white,
					activeColor: .blue,
					activeBinding: .init(get: {
						states.currentShowingCollection == collection
					}, set: { _ in })))
			}
		}
		.transition(.opacity.combined(with: .slide))
	}
	
	
	private struct ChangingColorButtonStyle: ButtonStyle{
		
		let defaultColor: Color
		let activeColor: Color
		let activeBinding: Binding<Bool>?
		
		func makeBody(configuration: Configuration) -> some View {
			configuration.label
				.foregroundColor(configuration.isPressed || (activeBinding != nil && activeBinding!.wrappedValue) ? activeColor: defaultColor)
		}
	}
	
	
	private var categoryString: String {
		switch settingController.language {
		case .korean:
			return "꾸러미들"
		case .english:
			return "Bundles"
		}
	}
	
	private var orderString: String {
		switch settingController.language {
		case .korean:
			return "정렬"
		case .english:
			return "Sort order"
		}
	}
	
	private func getLabelForTaskSort(_ taskSort: Task.Sort) -> some View {
		
		Group {
			let gradient = Gradient(colors: Array(1...5).compactMap({ Color.byPriority($0)}))
			let icon = Image(systemName: "arrow.up.and.down")
				.resizable()
			switch taskSort {
			case .priorityAscend:
				ZStack {
					LinearGradient(gradient: gradient, startPoint: .bottom, endPoint: .top)
						.mask(icon)
				}
			case .priorityDescend:
				ZStack {
					LinearGradient(gradient: gradient, startPoint: .top, endPoint: .bottom)
						.mask(icon)
				}
			}
		}
		
	}
}
