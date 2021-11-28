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
							.frame(width: 80, height: 80)
					}
					.position(x: geometry.size.width * 0.9,
							  y: geometry.size.height * 0.9)
					.sheet(isPresented: $isShowingNewScheduleSheet) {
						AddSchduleView(scheduleToModify: nil)
							.environmentObject(scheduleController)
							.environmentObject(settingController)
					}
				}
			}
		}
    }
	
}

