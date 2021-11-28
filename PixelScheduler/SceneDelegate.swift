
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    let scheduleModelController = ScheduleModelController()
    let settingController = SettingController()
    let taskModelController = TaskModelController()
    let notificationCenter = UNUserNotificationCenter.current()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        // Inject Model controller
		notificationCenter.delegate = self
		let tabViewController = UIHostingController(
			rootView: MainTabView()
				.environmentObject(scheduleModelController)
				.environmentObject(taskModelController)
				.environmentObject(settingController)
		)
		window?.rootViewController = tabViewController
		window?.makeKeyAndVisible()
		

//        let tabBarController = window?.rootViewController as! UITabBarController
//        if let scheduleVC = tabBarController.viewControllers?.first as? CalendarViewController {
//            scheduleVC.modelController = scheduleModelController
//            scheduleVC.settingController = settingController
//        }
//        if let todoListVC = tabBarController.viewControllers?[1] as? TodoListViewController {
//            todoListVC.scheduleModelController = scheduleModelController
//            todoListVC.settingController = settingController
//            todoListVC.taskModelController = taskModelController
//        }
//        if let settingNavigationVC = tabBarController.viewControllers?[2] as? UINavigationController,
//           let settingVC = settingNavigationVC.visibleViewController as?
//        SettingViewController
//        {
//            settingVC.scheduleModelController = scheduleModelController
//            settingVC.taskModelController = taskModelController
//            settingVC.settingController = settingController
//        }
   
        do {
            // Get User Schedule
            try scheduleModelController.retrieveUserData()
            // Get User Task
            try taskModelController.retrieveUserData()
            
            // Get Holiday data
            try scheduleModelController.checkHolidayData(for: Date().year,
                                                         about: HolidayGather.CountryCode.korea)
            try scheduleModelController.checkHolidayData(for: Date().year + 1,
                                                         about: HolidayGather.CountryCode.korea)
        }catch {
            assertionFailure("Fail to restore data \n \(error.localizedDescription)")
//					DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//							tabBarController.showAlertForDismiss(
//								title: "불러오기 실패",
//								message: "데이터가 손상되었거나 시스템 오류가 있습니다",
//						with: self.settingController.visualMode)
//            }
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
        let tabBarController = window?.rootViewController as! UITabBarController
        if (components.host == "schedule" || components.host == "date"),
           let scheduleVC = tabBarController.viewControllers?.first as? CalendarViewController{
            tabBarController.selectedViewController = scheduleVC
            if let dateIntParam = components.queryItems?.first(where: { $0.name == "dateInt"
            }),
            let dateInt = Int(dateIntParam.value!) {
                var navigationVC = scheduleVC.presentedViewController as? UINavigationController
                let dailyVC: DailyViewController
                if navigationVC != nil {
                    dailyVC = navigationVC!.viewControllers.first(where: { $0 is DailyViewController
                    }) as! DailyViewController
                    navigationVC!.popToViewController(dailyVC, animated: false)
                    dailyVC.dateIntShowing = dateInt
                }else {
                    let storyboard = UIStoryboard(name: "Schedule", bundle: nil)
                    navigationVC = storyboard.instantiateViewController(identifier: "DailyNavigationVC")
                    dailyVC = navigationVC?.visibleViewController as! DailyViewController
                    dailyVC.modelController = scheduleModelController
                    dailyVC.settingController = settingController
                    dailyVC.dateIntShowing = dateInt
                    navigationVC!.modalPresentationStyle = .fullScreen
                    navigationVC!.modalTransitionStyle = .coverVertical
                    scheduleVC.present(navigationVC!, animated: false)
                }
                if components.host == "schedule",
                   let idParam = components.queryItems?.first(where: { $0.name == "id"
                   }),
                   let scheduleID = UUID(uuidString: idParam.value!){
                    dailyVC.performSegue(withIdentifier: DailyViewController.SegueID.WidgetSegue.rawValue, sender: scheduleID)
                }
            }else if components.host == "schedule" {
                // New schedule
                if scheduleVC.presentedViewController != nil {
                    scheduleVC.dismiss(animated: false) {
                        scheduleVC.performSegue(withIdentifier: CalendarViewController.SegueID.NewScheduleSegue.rawValue, sender: nil)
                    }
                }else {
                    scheduleVC.performSegue(withIdentifier: CalendarViewController.SegueID.NewScheduleSegue.rawValue, sender: nil)
                }
            }
        } else if components.host == "taskCollection",
                  let todoListVC = tabBarController.viewControllers?[1] as? TodoListViewController,
                  let idParam = components.queryItems?.first(where: { $0.name == "id"
                  }){
            if tabBarController.selectedViewController != todoListVC {
                if let navigationVC = tabBarController.selectedViewController?.presentedViewController as? UINavigationController {
                    navigationVC.dismiss(animated: false)
                }
                tabBarController.selectedViewController = todoListVC
            }
            let collectionID = UUID(uuidString: idParam.value!)
            if let collection = taskModelController.table.keys.first(where: { $0.id == collectionID }),
               todoListVC.collectionVC.selectedCollection != collection{
                todoListVC.collectionVC.selectedCollection = collection
            }
        }
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
