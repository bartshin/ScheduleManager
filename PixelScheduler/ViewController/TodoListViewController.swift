//
//  TodoListViewController.swift
//  ScheduleManager
//
//  Created by Shin on 3/24/21.
//

import UIKit
import Combine
import AVFoundation

class TodoListViewController: UIViewController, PlaySoundEffect {
    
    // MARK: Controllers
    var settingController: SettingController!
    var scheduleModelController: ScheduleModelController!
    var taskModelController: TaskModelController!
    
    // View controllers
    private(set) lazy var collectionVC = TaskCollectionVC(
        tableView: collectionTableView,
        taskModelController: taskModelController,
        settingController: settingController,
        toggle: toggleCollectionView)
    var taskContainerVC: ToggleableContainerVC!

    // MARK:- Properties
    @IBOutlet private weak var collectionTableView: UITableView!
    @IBOutlet weak var collectionViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var taskContainerView: UIView!
    @IBOutlet private weak var floatingButton: UIButton!
    @IBOutlet weak var characterView: CharacterHelper!

    private var observeCollection: AnyCancellable?
    private let pencilIcon = UIImage(named: "pencil")!
    private let puzzleIcon = UIImage(named: "puzzle")!
    
    private var calculatedCollectionHeight: CGFloat {
        if collectionVC.isExtended {
            return view.bounds.height * 0.8
        }else {
            return min(view.bounds.height * 0.15, 100)
        }
    }
    
    var player: AVAudioPlayer!
    
    // MARK:- User intents
    
    @IBAction private func tapFloatingButton(_ sender: UIButton) {
        
        // List view floating button
        if collectionVC.selectedCollection?.style == .list {
            taskContainerVC.listVC.presentEditTaskAlert()
        }
        // Puzzle view foating button
        else  if collectionVC.selectedCollection?.style == .puzzle {
            if !taskContainerVC.puzzleVC.presentEditPuzzleVC() {
                let alert = UIAlertController(
                    title: "퍼즐 추가 실패",
                    message: "퍼즐 개수를 변경해 주세요", preferredStyle: .alert)
                let dismissAction = UIAlertAction(
                    title: "확인", style: .default)
                alert.addAction(dismissAction)
                present(alert, animated: true)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionTableView.delegate = collectionVC
        collectionTableView.dataSource = collectionVC
        addChild(collectionVC)
        collectionViewHeight.constant = calculatedCollectionHeight
        characterView.transform = CGAffineTransform(scaleX: -1, y: 1)
        characterView.settingController = settingController
        taskContainerVC.listVC.characterViewUpward = characterView
        observeCollection = collectionVC.$selectedCollection.sink { [self] selected in
            if let selected = selected {
                taskContainerVC.updateUI(for: selected)
                floatingButton.setBackgroundImage(selected.style == .list ? pencilIcon : puzzleIcon, for: .normal)
                floatingButton.isHidden = false
            }else {
                floatingButton.isHidden = true
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        characterView.load()
        applyColorScheme(settingController.visualMode)
        tabBarController?.applyColorScheme(settingController.visualMode)
        collectionVC.tableWillAppear()
        characterView.alpha = 1
        changeGuide()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if segue.identifier == SegueID.TaskContainerSegue.rawValue,
                 let containerVC = segue.destination as? ToggleableContainerVC{
            containerVC.taskModelController = taskModelController
            containerVC.settingController = settingController
            taskContainerVC = containerVC
        }
    }
    
    private func toggleCollectionView() {
        collectionVC.isExtended.toggle()
        taskContainerView.isHidden = true
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: 0.5,
            delay: 0,
            options: .curveEaseOut) {
            [self] in
            collectionViewHeight.constant = calculatedCollectionHeight
            collectionTableView.layoutIfNeeded()
            taskContainerView.layoutIfNeeded()
        } completion: { [ self] _ in
            if !collectionVC.isExtended,
               collectionVC.selectedCollection != nil {
                taskContainerVC.updateUI(for: collectionVC.selectedCollection!)
                taskContainerView.isHidden = false
            }
        }

        // Play sound effect
        playSound(collectionVC.isExtended ? AVAudioPlayer.openDrawer:  AVAudioPlayer.closeDrawer)
        floatingButton.isHidden = collectionVC.isExtended
        changeGuide()
    }
    
    
    private func changeGuide() {
        if collectionVC.isExtended {
            characterView.guide = .editCollection
        }else {
            characterView.guide = collectionVC.selectedCollection?.style == .list ? .todoList: .todoPuzzle
        }
    }
    
    enum SegueID: String {
        case TaskContainerSegue
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }
}


