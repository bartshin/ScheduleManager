//
//  AddSchduleView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/25.
//

import SwiftUI

struct AddSchduleView: View {
	@EnvironmentObject var scheduleController: ScheduleModelController
	@EnvironmentObject var settingController: SettingController
	
	let scheduleToModify: Schedule?
	
    var body: some View {
		VStack {
			scheduleTitle
		}
		.background(Color(settingController.palette.tertiary.withAlphaComponent(0.3)))
    }
	
	private var scheduleTitle: some View {
		HStack {
			
		}
	}
}

struct AddSchduleView_Previews: PreviewProvider {
    static var previews: some View {
		AddSchduleView(scheduleToModify: nil)
			.environmentObject(ScheduleModelController())
			.environmentObject(SettingController())
    }
}
