//
//  PuzzleEditVC.swift
//  ScheduleManager
//
//  Created by Shin on 3/30/21.
//

import UIKit

class EditPuzzleVC: UIViewController {
    
    var settingController: SettingController!
    
    static let storyboardID = "PuzzleEditVC"
    @IBOutlet weak private var puzzleImageView: UIImageView!
    @IBOutlet weak private var puzzleTextInput: UITextField!
    @IBOutlet weak private var confirmButton: UIButton!
    @IBOutlet weak private var changeTextButton: UIButton!
    @IBOutlet weak private var priorityPicker: UISegmentedControl!
    private var selectedPriority: Int {
        priorityPicker.selectedSegmentIndex + 1
    }
    var puzzleImage: UIImage?
    var task: Task?
    var changeTask: (Task, Task) -> Void = {_,_ in}
    var addNewTask: (Task) -> Void = {_ in}
    var flipPuzzle: () -> Void = {}
    
    @IBAction private func tapConfirmButton(_ sender: UIButton) {
        self.dismiss(animated: true) { [self] in
            
            if var taskToComplete = task ,
               !taskToComplete.completed {
                taskToComplete.completed = true
                changeTask(task!, taskToComplete)
                flipPuzzle()
            }else {
                let newTask = Task(
                    text: puzzleTextInput.text ?? "",
                    priority: selectedPriority)
                addNewTask(newTask)
            }
        }
    }
    
    @IBAction func tapEditButton(_ sender: UIButton) {
        guard var changedTask = task else { return }
        changedTask.text = puzzleTextInput.text ?? ""
        changedTask.priority = selectedPriority
        changeTask(task!, changedTask)
        dismiss(animated: true)
    }
    
    @IBAction private func tapCancelButton(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        puzzleImageView.image = puzzleImage
        if let taskToDisplay = task {
            if taskToDisplay.completed {
                puzzleTextInput.text = taskToDisplay.text + " (완료)"
                puzzleTextInput.textColor = .lightGray
                priorityPicker.isEnabled = false
                puzzleTextInput.isEnabled = false
                confirmButton.isHidden = true
            }else {
                puzzleTextInput.text = taskToDisplay.text
                changeTextButton.isHidden = false
                confirmButton.setTitle("완료", for: .normal)
            }
            priorityPicker.selectedSegmentIndex = taskToDisplay.priority - 1
        }else {
            confirmButton.setTitle("추가", for: .normal)
            priorityPicker.selectedSegmentIndex = 2
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyColorScheme(settingController.visualMode)
    }
    
    override func updateViewConstraints() {
        self.view.frame.size.height = UIScreen.main.bounds.height / 2
        self.view.frame.origin.y = 150
        self.view.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: 10.0)
                super.updateViewConstraints()
    }
}
extension UIView {
  func roundCorners(corners: UIRectCorner, radius: CGFloat) {
       let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
       let mask = CAShapeLayer()
       mask.path = path.cgPath
       layer.mask = mask
   }
}
