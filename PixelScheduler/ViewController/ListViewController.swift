//
//  ListViewController.swift
//  ScheduleManager
//
//  Created by Shin on 3/26/21.
//

import UIKit
import Combine

class ListViewController: UIViewController //,ColorBackground
{
    
    // MARK: Controllers
    var settingController: SettingController!
    var taskModelController: TaskModelController!
    
    // MARK:- Properties
    static let storyboardID = "ListViewController"
    private let cellReuseID = "TaskCell"
    var currentCollection: TaskCollection?
    private var tasks: [Task] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    // UI properties
    private var observeModel: AnyCancellable?
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet weak var backgroundView: UIView!
    let gradient = CAGradientLayer()
    let blurEffectView = UIVisualEffectView()
    let blurEffect = UIBlurEffect()
    var characterViewUpward: UIImageView!
    private var actionNotAllowEmpty: UIAlertAction?
    
    // MARK:- User intents
    
    private func completeTask(_ task: Task) -> Task {
        guard currentCollection != nil else {
            assertionFailure("Cant not find currentCollection in \(self)")
            return task
        }
        var newTask = task
        newTask.completed = true
        taskModelController.changeTask(from: task, to: newTask, in: currentCollection!)
        return newTask
    }
    
    @objc private func tapListLabel(_ sender: UITapGestureRecognizer){
        if let cell = tableView.hitTest(sender.location(in: tableView), with: nil)!.superview?.superview as? ListTaskCell,
           let task = cell.task{
            presentEditTaskAlert(with: task)
        }
    }
    
    func presentEditTaskAlert(with taskToEdit: Task? = nil) {
        let alertTitle: String
        let inputText: String?
        let confirmButtonTitle: String
        if let taskToEdit = taskToEdit {
            alertTitle = "항목 바꾸기"
            inputText = taskToEdit.text
            confirmButtonTitle = "변경"
        }else {
            alertTitle = "새 항목 추가"
            inputText = nil
            confirmButtonTitle = "추가"
        }
        
        let editAlert = UIAlertController(title: alertTitle, message: nil, preferredStyle: .actionSheet)
        let contentVC = CustomAlertViewController(
            message: "", segmentSelection: UIColor.Button.allCases.map { $0.rawValue },
            inputPlaceHolder: "제목을 입력하세요")
        contentVC.textInput!.text = inputText
        
        contentVC.drawCustomView(in: editAlert)
        contentVC.textInput!.addTarget(self, action: #selector(textInputDidChange(_:)), for: .editingChanged)
        contentVC.textInput!.delegate = self
        contentVC.segmentedSwitch!.selectedSegmentIndex = taskToEdit != nil ? taskToEdit!.priority - 1 : 2
        editAlert.applyColorScheme(settingController.visualMode)
        let confirmAction = UIAlertAction(
            title: confirmButtonTitle,
            style: .default) { [self] action in
            guard let title = contentVC.textInput?.text,
            let index = contentVC.segmentedSwitch?.selectedSegmentIndex,
            let collection = currentCollection else { return }
            let userInputTask: Task = Task(text: title, priority: index + 1)
            if taskToEdit != nil {
                taskModelController.changeTask(from: taskToEdit!, to: userInputTask, in: collection)
            }else {
                taskModelController.addNewTask(userInputTask, in: collection)
            }
        }
        self.actionNotAllowEmpty = confirmAction
        if taskToEdit == nil {
            confirmAction.isEnabled = false
        }
        
        let cancelAction = UIAlertAction(
            title: "취소",
            style: .default)
        editAlert.addAction(confirmAction)
        editAlert.addAction(cancelAction)
        present(editAlert, animated: true)
    }
    
    private func deleteTask(_ task: Task) {
        guard currentCollection != nil else {
            assertionFailure("Cant not find currentCollection in \(self)")
            return
        }
        taskModelController.deleteTask(task, in: currentCollection!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
//        initBackground()
        observeModel = taskModelController.$table.sink { [weak weakSelf = self] table in
            if weakSelf != nil, weakSelf!.currentCollection != nil {
                weakSelf!.tasks = table[weakSelf!.currentCollection!] ?? []
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        updateBackground()
        updateList()
    }
    
    func updateList () {
        tasks = taskModelController.table[currentCollection!] ?? []
    }
    
    @objc private func textInputDidChange(_ textField: UITextField) {
        actionNotAllowEmpty?.isEnabled = (textField.text != nil && !textField.text!.isEmpty)
    }
}

extension ListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tasks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseID, for: indexPath) as! ListTaskCell
        cell.settingController = settingController
        cell.task = tasks[indexPath.row]
        cell.titleLabel.textColor = cell.task!.completed ? .lightGray : settingController.palette.primary
        cell.titleLabel.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(tapListLabel(_:))))
        cell.character = settingController.character
        return cell
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell = tableView.cellForRow(at: indexPath) as? ListTaskCell,
              !cell.task!.completed
        else { return nil }
        
        let completeAction = UIContextualAction(
            style: .normal,
            title: nil) { [self] ( _, _, completionHandler) in
            
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: 0.3,
                delay: 0,
                options: .curveLinear) {
                characterViewUpward.alpha = 0
            } completion: { progress in
                cell.spawnCharacter { task in
                    cell.task = completeTask(task)
                    UIView.animate(withDuration: 0.3) {
                        characterViewUpward.alpha = 1
                    }
                }
            }
            completionHandler(true)
        }
        completeAction.image = settingController.character.staticImage 
        completeAction.backgroundColor = settingController.palette.quaternary
        return UISwipeActionsConfiguration(actions: [completeAction])
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let cell = tableView.cellForRow(at: indexPath) as? ListTaskCell
        else { return nil }
        let deleteAction = UIContextualAction(
            style: .normal,
            title: nil) {( _, _, completionHandler) in
            cell.deleteCell { [weak weakSelf = self] task in
                weakSelf?.deleteTask(task)
            }
            completionHandler(true)
        }
        deleteAction.image = cell.task!.completed ? UIImage(systemName: "checkmark")!: UIImage(systemName: "trash")!
        deleteAction.backgroundColor = cell.task!.completed ? .green : .systemPink
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

extension ListViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
