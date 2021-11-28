//
//  MainTabView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/05.
//

import SwiftUI

struct MainTabView: View {
	
	@EnvironmentObject var scheduleController: ScheduleModelController
	@EnvironmentObject var taskController: TaskModelController
	@EnvironmentObject var settingController: SettingController
	@State private var scheduleReferenceDate = Date()
	
    var body: some View {
		TabView {
			ScheduleView(referenceDate: $scheduleReferenceDate)
				.tabItem {
					Image(systemName: "calendar")
				}
			TodoListView()
				.tabItem {
					Image(systemName: "list.bullet.rectangle.portrait")
				}
			SettingView()
				.tabItem {
					Image(systemName: "gearshape")
				}
		}
    }
}
