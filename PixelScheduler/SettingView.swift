//
//  SettingView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/05.
//

import SwiftUI

struct SettingView: View {
	@EnvironmentObject var settingController: SettingController
	@EnvironmentObject var scheduleController: ScheduleModelController
	@EnvironmentObject var taskController: TaskModelController
	
	var body: some View {
		SettingVCRepresentable(settingController: settingController, scheduleController: scheduleController, taskController: taskController)
	}
}





struct SettingVCRepresentable: UIViewControllerRepresentable {
	
	let settingController: SettingController
	let scheduleController: ScheduleModelController
	let taskController: TaskModelController
	
	func makeUIViewController(context: Context) -> UINavigationController{
		let storyboard = UIStoryboard.init(name: "Setting", bundle: nil)
		let settingVC = storyboard.instantiateViewController(withIdentifier: "SettingViewController") as! SettingViewController
		settingVC.settingController = settingController
		settingVC.scheduleModelController = scheduleController
		settingVC.taskModelController = taskController
		let navigationVC = UINavigationController(rootViewController: settingVC)
		return navigationVC
	}
	
	func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
		
	}
	
}
