//
//  TaskCollectionVC.swift
//  ScheduleManager
//
//  Created by Shin on 3/24/21.
//

import UIKit
import Combine
import AVFoundation

class TaskCollectionVC: UIViewController
//, PlaySoundEffect
{
    
    // MARK: Controller
    var taskModelController: TaskModelController!
    var settingController: SettingController!
    
    // MARK: - Properties

    private let tableView: UITableView
    private let headerView: CustomTableHeaderFooter
    @Published var selectedCollection: TaskCollection? {
        didSet {
            settingController.collectionBookmark = selectedCollection?.title
        }
    }
    private let footerView: CustomTableHeaderFooter
    private var allCollections: [TaskCollection] {
        didSet {
            tableView.reloadData()
        }
    }
    var isExtended = false {
        didSet {
            tableView.isScrollEnabled = isExtended
            tableView.allowsSelection = isExtended
            headerView.title!.text = isExtended ? "컬렉션 닫기" : "컬렉션 열기"
            headerView.image!.image = isExtended ? closeIcon.withTintColor(settingController.palette.tertiary) :
                openIcon.withTintColor(settingController.palette.tertiary)
            tableView.reloadData()
        }
    }
    
    var player: AVAudioPlayer!
    private let hapticGenarator = UIImpactFeedbackGenerator()
    private weak var addNewCollectionAction: UIAlertAction?
    private weak var duplicationMessage: UILabel?
    private var obeserveTableCancellable: AnyCancellable?
    private let toggleTrigger: () -> Void
    private let scrollIcon = UIImage(systemName: "scroll")!
    private let puzzleIcon = UIImage(systemName: "puzzlepiece")!
    private let closeIcon = UIImage(systemName: "tray.and.arrow.up")!
    private let openIcon = UIImage(systemName: "tray.and.arrow.down.fill")!
    
    init(tableView: UITableView, taskModelController: TaskModelController, settingController: SettingController, toggle trigger: @escaping () -> Void) {
        
        self.taskModelController = taskModelController
        self.settingController = settingController
        let collections = Array(taskModelController.table.keys)
        allCollections = collections
        selectedCollection = collections.first { $0.title == settingController.collectionBookmark } ?? collections.first
        self.toggleTrigger = trigger
        
        self.tableView = tableView
        self.headerView = CustomTableHeaderFooter(
            for: .CustomHeader,
            title: "컬렉션 보기",
            image: openIcon)
        let footerButton = UIButton()
        footerButton.setTitle("새 컬렉션 추가", for: .normal)
        self.footerView = CustomTableHeaderFooter(for: .CustomFooter, onlyFor: footerButton)
        super.init(nibName: nil, bundle: nil)
        
        headerView.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self, action: #selector(tapHeader)))
        footerView.button!.addTarget(self, action: #selector(tapFooterButton), for: .touchUpInside)
        obeserveTableCancellable = taskModelController.$table.sink(receiveValue: { [weak weakSelf = self] changedTable in
            weakSelf?.allCollections = Array(changedTable.keys)
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func tableWillAppear() {
        applyUI()
        tableView.reloadData()
    }
    private func applyUI() {
        headerView.title!.textColor = settingController.palette.primary
        headerView.image!.tintColor = settingController.palette.tertiary
        footerView.button!.setTitleColor(settingController.palette.secondary, for: .normal)
        headerView.contentView.backgroundColor = settingController.palette.quaternary
        footerView.contentView.backgroundColor =  settingController.palette.quaternary.withAlphaComponent(0.2)
    }
    private func getIcon(for style: TaskCollection.Style)  -> UIImage {
        switch style {
        case .list:
            return scrollIcon
        case .puzzle:
            return puzzleIcon
        }
    }
    @objc private func tapHeader() {
        if selectedCollection != nil, !allCollections.contains(selectedCollection!) {
            selectedCollection = allCollections.first
        }
        toggleTrigger()
        tableView.reloadData()
    }
    @objc private func tapFooterButton() {
        let alert = UIAlertController(title: "새 컬렉션",
                                                   message: nil,
                                                   preferredStyle: .alert)
        let contentVC = CustomAlertViewController(
            message: "중복된 컬렉션입니다",
            segmentSelection: [ scrollIcon,
                                puzzleIcon],
            inputPlaceHolder: "제목을 입력하세요")
        contentVC.segmentedSwitch?.selectedSegmentTintColor = settingController.palette.tertiary.withAlphaComponent(0.5)
        contentVC.drawCustomView(in: alert)
        contentVC.textInput?.addTarget(self, action: #selector(titleInputChanged(_:)), for: .editingChanged)
        let addAction = UIAlertAction(
            title: "추가",
            style: .default)
        {[self] _ in
            let style: TaskCollection.Style = contentVC.segmentedSwitch!.selectedSegmentIndex == 0 ? .list : .puzzle
            let title = contentVC.textInput!.text!
            taskModelController.addNewCollection(
                TaskCollection(style: style, title: title))
        }
        
        addAction.isEnabled = false
        duplicationMessage = contentVC.userMessagelabel
        self.addNewCollectionAction = addAction
        let cancelAction = UIAlertAction(title: "취소",
                                         style: .destructive)
        alert.addAction(cancelAction)
        alert.addAction(addAction)
        alert.applyColorScheme(settingController.visualMode)
        present(alert, animated: true)
    }
    @objc private func titleInputChanged(_ textField: UITextField) {
        guard let title = textField.text else {
            addNewCollectionAction?.isEnabled = false
            return
        }
        if allCollections.contains(where: { $0.title == title}) {
            addNewCollectionAction?.isEnabled = false
            duplicationMessage?.isHidden = false
        }else {
            addNewCollectionAction?.isEnabled = true
            duplicationMessage?.isHidden = true
        }
    }
}

extension TaskCollectionVC: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isExtended ? allCollections.count : 1
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: CollectionCell
        if let dequeuedCell = tableView.dequeueReusableCell(withIdentifier: CollectionCell.reuseID, for: indexPath) as? CollectionCell {
            cell = dequeuedCell
        }else {
            cell = CollectionCell(style: .default, reuseIdentifier: CollectionCell.reuseID)
        }
        cell.backgroundColor = settingController.palette.quaternary.withAlphaComponent(1 - CGFloat(indexPath.row) * 0.15)
        if isExtended {
            let collection = allCollections[indexPath.row]
            cell.icon.image = getIcon(for: collection.style)
            cell.titleLabel.text = collection.title
        }else{
            if let selectedCollection = selectedCollection {
                cell.icon.image = getIcon(for: selectedCollection.style)
                cell.titleLabel.text = selectedCollection.title
            }else{
                cell.icon.image = nil
                cell.titleLabel.text?.removeAll()
            }
        }
        cell.titleLabel.textColor = settingController.palette.primary
        cell.icon.tintColor = settingController.palette.tertiary
        return cell
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard isExtended else { return }
        cell.alpha = 0
        let transform = CATransform3DTranslate(CATransform3DIdentity, 0, -200, 0)
        cell.layer.transform = transform
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: 0.5,
            delay: 0,
            options: .curveEaseOut) {
            cell.alpha = 1
            cell.layer.transform = CATransform3DIdentity
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        headerView
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        50
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if !isExtended { return 0 }
        // Storyboard row height 70
        return tableView.visibleSize.height - ( 70 * CGFloat(allCollections.count + 1))
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        footerView
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard allCollections.count > indexPath.row else {
            assertionFailure()
            return }
        selectedCollection = allCollections[indexPath.row]
        toggleTrigger()
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard isExtended else { return nil }
        hapticGenarator.prepare()
        let deleteAction = UIContextualAction(
            style: .destructive,
            title: "삭제") { [self] action, _, completionHandler in
            let deleteAlert = UIAlertController(
                title: "컬렉션 삭제",
                message: "컬렉션의 내용도 같이 삭제됩니다",
                preferredStyle: .alert)
            let deleteAction = UIAlertAction(
                title: "삭제",
                style: .destructive) { [weak weakSelf = self] _ in
                guard let toDelete = weakSelf?.allCollections[indexPath.row] else {
                    return
                }
//                playSound(AVAudioPlayer.delete)
                weakSelf?.taskModelController.deleteCollection(toDelete)
            }
            let cancellAction = UIAlertAction(
                title: "취소",
                style: .default)
            deleteAlert.addAction(deleteAction)
            deleteAlert.addAction(cancellAction)
            deleteAlert.applyColorScheme(settingController.visualMode)
            self.present(deleteAlert, animated: true)
            hapticGenarator.generateFeedback(for: settingController.hapticMode)
            completionHandler(true)
        }
        deleteAction.backgroundColor = .systemPink
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard isExtended else { return nil }
        let renameAction = UIContextualAction(
            style: .normal,
            title: "타이틀 변경") { [self] action, _, completionHandler in
            let renameAlert = UIAlertController(
                title: "타이틀 변경",
                message: nil,
                preferredStyle: .alert )
            let contentVC = CustomAlertViewController(
                message: "중복된 이름입니다",
                inputPlaceHolder: "새로운 이름을 입력해주세요")
            contentVC.drawCustomView(in: renameAlert)
            let changeAction = UIAlertAction(
                title: "변경", style: .default) { [weak weakSelf = self] _ in
                guard let newTitle = contentVC.textInput?.text else { return }
                var newCollection = allCollections[indexPath.row]
                newCollection.title = newTitle
                weakSelf?.taskModelController.changeCollection(from: allCollections[indexPath.row], to: newCollection)
            }
            changeAction.isEnabled = false
            let cancelAction = UIAlertAction(
                title: "취소", style: .cancel)
            self.addNewCollectionAction = changeAction
            self.duplicationMessage = contentVC.userMessagelabel
            contentVC.textInput!.addTarget(self, action: #selector(titleInputChanged(_:)), for: .editingChanged)
            renameAlert.addAction(cancelAction)
            renameAlert.addAction(changeAction)
            self.present(renameAlert, animated: true)
            completionHandler(true)
        }
        renameAction.backgroundColor = .systemBlue
        return UISwipeActionsConfiguration(actions: [renameAction])
    }
}
