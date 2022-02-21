
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate, ObservableObject {
	
	var window: UIWindow?
	private let scheduleModelController = ScheduleModelController()
	private let settingController = SettingController()
	private lazy var taskModelController = TaskModelController()
	private let notificationCenter = UNUserNotificationCenter.current()
	private var viewStates = ViewStates()
	
	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let _ = (scene as? UIWindowScene) else { return }
		
		notificationCenter.delegate = self
		let colorScheme: ColorScheme
		switch settingController.visualMode {
		case .dark:
			colorScheme = .dark
		case .light:
			colorScheme = .light
		case .system:
			colorScheme = UITraitCollection.current.userInterfaceStyle == .light ? .light: .dark
		}
		let tabView = MainTabView(colorScheme: colorScheme)
			.environmentObject(scheduleModelController)
			.environmentObject(taskModelController)
			.environmentObject(settingController)
			.environmentObject(viewStates)
		
		window?.rootViewController = UIHostingController(rootView: tabView)
		window?.makeKeyAndVisible()
		
		
		do {
			try scheduleModelController.retrieveUserData()
			try scheduleModelController.checkHolidayData(
				for: Date().year,
					 about: HolidayGather.CountryCode.korea)
			try scheduleModelController.checkHolidayData(
				for: Date().year + 1,
					 about: HolidayGather.CountryCode.korea)
		}catch {
			assertionFailure("Fail to load user data \n \(error.localizedDescription)")
		}
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				try self.taskModelController.retrieveUserDataIfNeeded()
			}catch {
				assertionFailure("Fail to get task data \(error.localizedDescription)")
			}
		}
		if settingController.isFirstOpen {
			taskModelController.createDefaultCollection()
		}
		
		if let url = connectionOptions.urlContexts.first?.url {
			UIApplication.shared.open(url)
		}
	}
	
	func sceneWillResignActive(_ scene: UIScene) {
		// Called when the scene will move from an active state to an inactive state.
		// This may occur due to temporary interruptions (ex. an incoming phone call).
		
		if let collectionBookmark = settingController.saveCollectionBookmark() {
			taskModelController.storeWidgetData(bookmark: collectionBookmark)
		}
		scheduleModelController.storeWidgetData()
		if settingController.icloudBackup == .on {
			DispatchQueue.global(qos: .background).async { [self] in
				try? scheduleModelController.backup()
				try? taskModelController.backup()
			}
		}
	}
	
	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		guard let url = URLContexts.first?.url else {
			assertionFailure("Fail to open url \n \(URLContexts)")
			return }
		handleURL(url)
	}
	
	func sceneDidDisconnect(_ scene: UIScene) {
		// Called as the scene is being released by the system.
		// This occurs shortly after the scene enters the background, or when its session is discarded.
		// Release any resources associated with this scene that can be re-created the next time the scene connects.
		// The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
	}
	
	func sceneDidBecomeActive(_ scene: UIScene) {
		// Called when the scene has moved from an inactive state to an active state.
		// Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
		UIApplication.shared.applicationIconBadgeNumber = 0
	}
	
	func sceneWillEnterForeground(_ scene: UIScene) {
		// Called as the scene transitions from the background to the foreground.
		// Use this method to undo the changes made on entering the background.
		scheduleModelController.notificationContoller.checkAuthorized()
	}
	
	func sceneDidEnterBackground(_ scene: UIScene) {
		// Called as the scene transitions from the foreground to the background.
		// Use this method to save data, release shared resources, and store enough scene-specific state information
		// to restore the scene back to its current state.
	}
	
	private func handleURL(_ url: URL) {
		guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
			assertionFailure("Fail to resolve url \(url)")
			return
		}
		if (components.host == "schedule" || components.host == "date") {
			viewStates.mainTabViewTab = .scheduleTab
			if let dateIntParam = components.queryItems?.first(where: { $0.name == "dateInt"
							}),
			let dateToShow = Int(dateIntParam.value!)?.toDate	{
				viewStates.scheduleViewDate = dateToShow
				viewStates.weeklyViewDateInt = dateToShow.toInt
				if let idParam = components.queryItems?.first(where: { $0.name == "id"
				}),
					 let scheduleID = UUID(uuidString: idParam.value!){
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){ [weak weakSelf = self] in
						weakSelf?.viewStates.presentingScheduleId = scheduleID
					}
				}
			}
			
			else {
				viewStates.isShowingNewScheduleSheet = true
			}
		}
		else if components.host == "taskCollection",
						let idParam = components.queryItems?.first(where: { $0.name == "id"
						}),
						let collectionID = UUID(uuidString: idParam.value!),
						let collection = taskModelController.table.keys.first(where: { $0.id == collectionID }){
			viewStates.isCategoryExpanded = false
			viewStates.currentShowingCollection = collection
			
			viewStates.mainTabViewTab = .todoTab
		}
		
//		let tabBarController = window?.rootViewController as! UITabBarController
//		if (components.host == "schedule" || components.host == "date")
//			 ,let scheduleVC = tabBarController.viewControllers?.first as? CalendarViewController
//		{
//			tabBarController.selectedViewController = scheduleVC
//			if let dateIntParam = components.queryItems?.first(where: { $0.name == "dateInt"
//			}),
//				 let dateInt = Int(dateIntParam.value!) {
//				var navigationVC = scheduleVC.presentedViewController as? UINavigationController
//				let dailyVC: DailyViewController
//				if navigationVC != nil {
//					dailyVC = navigationVC!.viewControllers.first(where: { $0 is DailyViewController
//					}) as! DailyViewController
//					navigationVC!.popToViewController(dailyVC, animated: false)
//					dailyVC.dateIntShowing = dateInt
//				}else {
//					let storyboard = UIStoryboard(name: "Schedule", bundle: nil)
//					navigationVC = storyboard.instantiateViewController(identifier: "DailyNavigationVC")
//					dailyVC = navigationVC?.visibleViewController as! DailyViewController
//					dailyVC.modelController = scheduleModelController
//					dailyVC.settingController = settingController
//					dailyVC.dateIntShowing = dateInt
//					navigationVC!.modalPresentationStyle = .fullScreen
//					navigationVC!.modalTransitionStyle = .coverVertical
//					scheduleVC.present(navigationVC!, animated: false)
//				}
//				if components.host == "schedule",
//					 let idParam = components.queryItems?.first(where: { $0.name == "id"
//					 }),
//					 let scheduleID = UUID(uuidString: idParam.value!){
//					dailyVC.performSegue(withIdentifier: DailyViewController.SegueID.WidgetSegue.rawValue, sender: scheduleID)
//				}
//			}else if components.host == "schedule" {
//				// New schedule
//				if scheduleVC.presentedViewController != nil {
//					scheduleVC.dismiss(animated: false) {
//						scheduleVC.performSegue(withIdentifier: CalendarViewController.SegueID.NewScheduleSegue.rawValue, sender: nil)
//					}
//				}else {
//					scheduleVC.performSegue(withIdentifier: CalendarViewController.SegueID.NewScheduleSegue.rawValue, sender: nil)
//				}
//			}
//		} else if components.host == "taskCollection",
//							let todoListVC = tabBarController.viewControllers?[1] as? TodoListViewController,
//							let idParam = components.queryItems?.first(where: { $0.name == "id"
//							}){
//			if tabBarController.selectedViewController != todoListVC {
//				if let navigationVC = tabBarController.selectedViewController?.presentedViewController as? UINavigationController {
//					navigationVC.dismiss(animated: false)
//				}
//				tabBarController.selectedViewController = todoListVC
//			}
//			let collectionID = UUID(uuidString: idParam.value!)
//			if let collection = taskModelController.table.keys.first(where: { $0.id == collectionID }),
//				 todoListVC.collectionVC.selectedCollection != collection{
//				todoListVC.collectionVC.selectedCollection = collection
//			}
//		}
	}
	
}

extension SceneDelegate: UNUserNotificationCenterDelegate {
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		if let urlString = response.notification.request.content.userInfo["urlString"] as? String,
			 let url = URL(string: urlString) {
			handleURL(url)
		}
		completionHandler()
	}
}
