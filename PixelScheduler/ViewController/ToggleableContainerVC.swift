//
//  ToggleableContainerVC.swift
//  ScheduleManager
//
//  Created by Shin on 3/26/21.
//

import UIKit

class ToggleableContainerVC: UIViewController {
    
    // MARK: Controllers
    var taskModelController: TaskModelController! 
    var settingController: SettingController!
    
    private(set) lazy var listVC: ListViewController = {
        // Instantiate View Controller
        var viewController = storyboard!.instantiateViewController(withIdentifier: ListViewController.storyboardID) as! ListViewController
        viewController.taskModelController = taskModelController
        viewController.settingController = settingController
        return viewController
    }()
    private(set) lazy var puzzleVC: PuzzleViewController = {
        // Instantiate View Controller
        var viewController = storyboard!.instantiateViewController(withIdentifier: PuzzleViewController.storyboardID) as! PuzzleViewController
        viewController.taskModelController = taskModelController
        viewController.settingController = settingController
        return viewController
    }()
    
    // MARK:- User intents
    
    func updateUI(for collection: TaskCollection) {
        
        switch collection.style {
        case .list:
            listVC.currentCollection = collection
        case .puzzle:
            puzzleVC.currentCollection = collection
        }
        
        if let currentVC = children.first {
            if currentVC is ListViewController ,
               collection.style == .puzzle {
                remove(asChildViewController: listVC)
                add(asChildViewController: puzzleVC)
            }else if currentVC is PuzzleViewController,
                     collection.style == .list{
                remove(asChildViewController: puzzleVC)
                add(asChildViewController: listVC)
            }
        }else {
            add(asChildViewController: collection.style == .list ? listVC : puzzleVC)
        }
        switch collection.style {
        case .list:
            listVC.updateList()
        case .puzzle:
            puzzleVC.updatePuzzle()
        }
        
    }
    
    private func add(asChildViewController viewController: UIViewController) {
        // Add Child View Controller
        addChild(viewController)

        UIView.transition(
            with: viewController.view,
            duration: 0.5,
            options: .transitionCrossDissolve) { [self] in
            view.addSubview(viewController.view)
        }

        // Configure Child View
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Notify Child View Controller
        viewController.didMove(toParent: self)
    }
    private func remove(asChildViewController viewController: UIViewController) {
        // Notify Child View Controller
        viewController.willMove(toParent: nil)

        // Remove Child View From Superview
        viewController.view.removeFromSuperview()

        // Notify Child View Controller
        viewController.removeFromParent()
    }
    
}
