//
//  ScheduleView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/20.
//

import SwiftUI

struct ScheduleView: View {
	@EnvironmentObject var scheduleController: ScheduleModelController
	@EnvironmentObject var settingController: SettingController
	@Binding var referenceDate: Date
	@State private var isShowingNewScheduleSheet = false
	@State private var scheduleToEdit: Schedule? = nil
	
    var body: some View {
		NavigationView {
			GeometryReader { geometry in
				ZStack {
					CalendarView(referenceDate: $referenceDate)
						.navigationBarTitle("")
						.navigationBarHidden(true)
					Button {
						isShowingNewScheduleSheet = true
					} label: {
						Image("add_schedule_orange")
							.resizable()
							.frame(width: 50, height: 50)
					}
					.position(x: geometry.size.width * 0.9,
							  y: geometry.size.height * 0.9)
					.sheet(isPresented: $isShowingNewScheduleSheet) {
						EditScheduleView(selectedDate: Date())
					}
					.sheet(item: $scheduleToEdit) { schedule in
						EditScheduleView(scheduleToEdit: schedule)
					}
				}
			}
		}
		.environmentObject(scheduleController)
		.environmentObject(settingController)
    }
	
}

