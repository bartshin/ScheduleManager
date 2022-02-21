//
//  MainTabView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/05.
//

import SwiftUI

struct MainTabView: View {
	
	@State private var colorScheme: ColorScheme
	@EnvironmentObject var states: ViewStates
	@EnvironmentObject var scheduleController: ScheduleModelController
	@EnvironmentObject var taskController: TaskModelController
	@EnvironmentObject var settingController: SettingController
	
	init(colorScheme: ColorScheme) {
		_colorScheme = .init(initialValue: colorScheme)
	}
	
	var body: some View {
		TabView(selection: $states.mainTabViewTab) {
			ScheduleView()
				.tabItem {
					Image(systemName: "calendar")
				}
				.tag(Tab.scheduleTab)
			TodoListView(settingController: _settingController, taskController: _taskController)
				.tabItem {
					Image(systemName: "list.bullet.rectangle.portrait")
				}
				.tag(Tab.todoTab)
			SettingView()
				.tabItem {
					Image(systemName: "gearshape")
				}
				.tag(Tab.settingTab)
		}
		.environment(\.colorScheme, colorScheme)
		.onChange(of: settingController.visualMode) { visualMode in
			if visualMode == .system {
				colorScheme = UITraitCollection.current.userInterfaceStyle == .dark ? .dark: .light
			}else {
				colorScheme = visualMode == .light ? .light: .dark
			}
		}
	}
	
	enum Tab: Int {
		case scheduleTab
		case todoTab
		case settingTab
	}
}
