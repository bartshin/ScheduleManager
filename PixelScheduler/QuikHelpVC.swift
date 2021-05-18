//
//  QuikHelpVC.swift
//  ScheduleManager
//
//  Created by Shin on 3/31/21.
//

import UIKit

class QuikHelpVC: UIViewController {
    
    // MARK: Controller
    var settingController: SettingController!
    
    // MARK:- Properties
    
    static let storyboadID = "QuikHelpVC"
    private let cellReuseID = "InstructionCell"
    var characterLocation: CGPoint!
    @IBOutlet private weak var backgroundBalloon: SpeechBalloon!
    @IBOutlet private weak var tableview: UITableView!
    var instructions: [(String, NSAttributedString)]!
    @IBOutlet weak var balloonVerticalOrigin: NSLayoutConstraint!
    @IBOutlet weak var balloonHorizontalOrigin: NSLayoutConstraint!
    @IBOutlet weak var balloonHeight: NSLayoutConstraint!
    var dismissCompletion: (() -> Void)?
    
    // MARK:- User intents
    
    @IBAction func tapBackButton(_ sender: UIButton) {
        modalTransitionStyle = .crossDissolve
        dismiss(animated: true)
        if let aditionalTask = dismissCompletion {
            aditionalTask()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundBalloon.fillColor = settingController.palette.quaternary
        adjustView()
        tableview.dataSource = self
        tableview.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyColorScheme(settingController.visualMode)
    }
    
    private func adjustView() {
        if characterLocation.x > view.bounds.midX {
            backgroundBalloon.transform = CGAffineTransform(scaleX: -1, y: 1)
            balloonHorizontalOrigin.constant = -30
        }else {
            balloonHorizontalOrigin.constant = 30
        }
        balloonHeight.constant = -characterLocation.y - 100
        balloonVerticalOrigin.constant = characterLocation.y + 20
        backgroundBalloon.width = view.bounds.width * 0.8
        backgroundBalloon.height = view.bounds.height * 0.8 - characterLocation.y
    }
    
}

extension QuikHelpVC: UITableViewDataSource, UITableViewDelegate { 
    
    func numberOfSections(in tableView: UITableView) -> Int {
        instructions.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableview.dequeueReusableCell(withIdentifier: cellReuseID) as!
        InstructionCell
        cell.textview.attributedText = instructions[indexPath.section].1
        cell.textview.textColor = settingController.palette.primary
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        20
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let title =  instructions[section].0
        let header = CustomTableHeaderFooter(for: .CustomHeader, title: title)
        header.title!.font = UIFont(name: "YANGJIN", size: 18)
        header.title!.textColor = settingController.palette.secondary
        return header
    }
}
