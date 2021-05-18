//
//  PuzzleViewController.swift
//  ScheduleManager
//
//  Created by Shin on 3/26/21.
//

import UIKit
import AVFoundation
import PuzzleMaker

class PuzzleViewController: UIViewController, PlaySoundEffect, ColorBackground {
    
    // MARK: Controllers
    var settingController: SettingController!
    var taskModelController: TaskModelController!
    
    // MARK:- Properties
    static let storyboardID = "PuzzleViewController"
    var currentCollection: TaskCollection?
    private var tasks: [Task] {
        taskModelController.table[currentCollection!] ?? []
    }
    private var tasksNotCompletedFirst: [Task] {
        var notCompleted = [Task]()
        var completed = [Task]()
        tasks.forEach {
            if $0.completed {
                completed.append($0)
            }else {
                notCompleted.append($0)
            }
        }
        return notCompleted + completed
    }
    
    private var numPiecesCompleted: Int {
        var numPieces = 0
        tasks.forEach {
            if $0.completed {
                numPieces += 1
            }
        }
        return numPieces
    }
  
    private var minimumZoomScale: CGFloat?
    private var doubleTapToZoom: UITapGestureRecognizer?
    private var singleTapPuzzlePiece: UITapGestureRecognizer?
    
    private var numRows: Int {
        currentCollection!.puzzleConfig!.numRows
    }
    private var numColumns: Int {
        currentCollection!.puzzleConfig!.numColumns
    }
    private var puzzleImage: UIImage {
        get {
            currentCollection!.puzzleConfig!.backgroundImage.image
        }
    }
    private var randomStampImage: UIImage {
        UIImage(named: "completed_stamp" + ["1", "2", "3", "4"].randomElement()!)!
    }
    private var puzzlePieceImages = [Int: UIImage]()
    private var puzzleContainer: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak private var puzzleScrollView: UIScrollView!

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var descriptionView: UITextView!
    var player: AVAudioPlayer!
    let gradient = CAGradientLayer()
    let blurEffectView = UIVisualEffectView()
    let blurEffect = UIBlurEffect()
    
    // MARK:- User intents
    @objc private func zoomToMinimunScale() {
        if minimumZoomScale != nil {
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: 0.3,
                delay: 0,
                options: .curveEaseInOut) {[self] in
                puzzleScrollView.zoomScale = minimumZoomScale!
            }
        }
    }
    @IBAction func tapPuzzleSetting(_ sender: UIButton) {
        if let puzzleSettingVC = storyboard?.instantiateViewController(identifier: PuzzleSettingVC.storyboardID) as? PuzzleSettingVC {
            puzzleSettingVC.confirmSetting = changeSetting(backgound:numRows:numColumns:)
            puzzleSettingVC.selectedBackground = currentCollection!.puzzleConfig?.backgroundImage
            puzzleSettingVC.minimumPuzzlePieces = tasks.count
            puzzleSettingVC.settingController = settingController
            present(puzzleSettingVC, animated: true)
        }
    }
    
    @objc private func tapPuzzlePiece(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: sender.view)
        guard let puzzlePiece = sender.view!.hitTest(location, with: nil) as? UIImageView
             else { return }
        let index = puzzlePiece.tag
        
        if let puzzleEditVC = storyboard?.instantiateViewController(identifier: EditPuzzleVC.storyboardID) as? EditPuzzleVC {
            puzzleEditVC.settingController = settingController
            if isPuzzleComplete(at: index) {
                // Show Completed puzzle
                _ = presentEditPuzzleVC(for: index, pieceToFlip: puzzlePiece)
                
            }else if tasks.count > index {
                // Show Not Completed puzzle to flip
                _ = presentEditPuzzleVC(for: index, pieceToFlip: puzzlePiece)
            }else {
                // New puzzle
                _ = presentEditPuzzleVC()
            }
        }
    }
    func presentEditPuzzleVC(for taskIndex: Int? = nil, pieceToFlip: UIImageView? = nil) -> Bool {
        // without specific index -> create new
        let index = taskIndex ?? tasks.count
        guard index < (numRows * numColumns),
        let editPuzzleVC = storyboard?.instantiateViewController(identifier: EditPuzzleVC.storyboardID) as? EditPuzzleVC else {
            // puzzle has no empty space
            return false
        }
        
        editPuzzleVC.settingController = settingController
        if taskIndex != nil, pieceToFlip != nil {
            editPuzzleVC.task = tasks[taskIndex!]
            editPuzzleVC.puzzleImage = puzzlePieceImages[taskIndex!]
            editPuzzleVC.flipPuzzle = {
                self.flipPuzzle(pieceToFlip!, index: taskIndex!)
            }
            editPuzzleVC.changeTask = changePuzzle(from:to:)
        }else {
            editPuzzleVC.puzzleImage = puzzlePieceImages[index]?.withTintColor(.darkGray)
            editPuzzleVC.addNewTask = addNewPuzzle
        }
        present(editPuzzleVC, animated: true)
        return true
    }

    private func addNewPuzzle(with task: Task) {
        taskModelController.addNewTask(task, in: currentCollection!)
        updatePuzzle()
    }
    private func changePuzzle(from taskToChange: Task, to newTask: Task){
        taskModelController.changeTask(from: taskToChange, to: newTask, in: currentCollection!)
        if !newTask.completed {
            updatePuzzle()
        }
    }
    
    private func flipPuzzle(_ puzzlePiece: UIImageView, index: Int) {
        playSound(AVAudioPlayer.puzzleFlip)
        let visibleImage = puzzlePieceImages[index]
        UIView.transition(
            with: puzzlePiece,
            duration: 1,
            options: [.transitionFlipFromLeft, .showHideTransitionViews]) {
            puzzlePiece.image = visibleImage
        }
        if tasks.count == (numRows * numColumns), numPiecesCompleted == tasks.count {
            displayStamp(animated: true)
        }
        updateDescription()
    }
    
    private func displayStamp(animated: Bool) {
        let generator = UIImpactFeedbackGenerator()
        generator.prepare()
        var origin = puzzleContainer.bounds.origin
        origin.x += puzzleContainer.bounds.width * 0.1
        origin.y += puzzleContainer.bounds.height * 0.1
        let size = CGSize(
            width: puzzleContainer.bounds.width * 0.8,
            height: puzzleContainer.bounds.height * 0.8)
        let completeStamp = UIImageView(
            frame: CGRect(origin: origin, size: size))
        completeStamp.image = randomStampImage
        completeStamp.alpha = animated ? 0 : 1
        puzzleContainer.addSubview(completeStamp)
        if animated {
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: 1,
                delay: 0,
                options: .curveEaseIn) {
                completeStamp.alpha = 1
            } completion: { [weak weakSelf = self] getStamepd in
                if getStamepd == .end, weakSelf != nil {
                    weakSelf!.playSound(AVAudioPlayer.coin)
                    generator.generateFeedback(for: weakSelf!.settingController.hapticMode)
                }
            }
        }
    }
    private func changeSetting(backgound: TaskCollection.PuzzleBackground, numRows: Int, numColumns: Int) {
        var newColection = currentCollection!
        newColection.puzzleConfig!.backgroundImage = backgound
        newColection.puzzleConfig!.numRows = numRows
        newColection.puzzleConfig!.numColumns = numColumns
        taskModelController.changeCollection(from: currentCollection!, to: newColection)
        currentCollection = newColection
        updatePuzzle()
    }
     
    private func isPuzzleComplete(at index: Int) -> Bool {
        tasks.count > index && tasks[index].completed
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initBackground()
        doubleTapToZoom = UITapGestureRecognizer(target: self, action: #selector(zoomToMinimunScale))
        doubleTapToZoom!.numberOfTapsRequired = 2
        doubleTapToZoom?.delaysTouchesBegan = true
        puzzleScrollView.addGestureRecognizer(doubleTapToZoom!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updatePuzzle()
        applyUI()
        updateBackground()
    }
    
    private func setZoomScale() {
        let widthScale = puzzleScrollView.bounds.width / puzzleImage.size.width
        let heightScale = puzzleScrollView.bounds.height / puzzleImage.size.height
        minimumZoomScale = min(widthScale, heightScale)
        puzzleScrollView.minimumZoomScale = minimumZoomScale!
        puzzleScrollView.zoomScale = minimumZoomScale!
        puzzleScrollView.maximumZoomScale = 1
    }
    
    private func applyUI() {
        applyColorScheme(settingController.visualMode)
        descriptionLabel.backgroundColor = settingController.palette.tertiary.withAlphaComponent(0.7)
        descriptionLabel.textColor = settingController.palette.primary
    }
    
    private func updateDescription() {
        guard tasks.count > 0 else { return }
        let description = NSMutableAttributedString()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        tasksNotCompletedFirst.forEach {
            description.append(
                NSAttributedString(
                    string: $0.completed ? "\($0.text) (완료) \n" : $0.text + "\n",
                    attributes: [
                        .font : UIFont.systemFont(ofSize: $0.completed ? 12: 15),
                        .foregroundColor : $0.completed ? UIColor.gray : settingController.palette.primary,
                        .paragraphStyle: paragraphStyle
                    ]
                ))
        }
        descriptionView.attributedText = description
    }
    
    func updatePuzzle() {
        let scrollWidth = puzzleImage.size.width
        let scrollHeight = puzzleImage.size.height
        puzzleScrollView.contentSize = CGSize(width: scrollWidth, height: scrollHeight)
        puzzleScrollView.delegate = self
        let origin = CGPoint(x: puzzleScrollView.bounds.origin.x,
                             y: puzzleScrollView.bounds.origin.y )
        puzzleContainer = UIView(frame:
                                    CGRect(origin: origin,
                                           size: puzzleImage.size))
        if let previousPuzzle = puzzleScrollView.subviews.first {
            previousPuzzle.removeFromSuperview()
        }
        loadPuzzleImage()
        singleTapPuzzlePiece = UITapGestureRecognizer(
            target: self,
            action: #selector(tapPuzzlePiece(_:)))
        singleTapPuzzlePiece!.numberOfTapsRequired = 1
        singleTapPuzzlePiece!.delaysTouchesBegan = true
        singleTapPuzzlePiece!.require(toFail: doubleTapToZoom!)
        puzzleContainer.addGestureRecognizer(singleTapPuzzlePiece!)
        updateDescription()
    }
    
    private func loadPuzzleImage() {
        let darkShadow: AdjustableShadow = (
            color: .darkGray,
            offset: CGSize(width: -1.5, height: -1.5),
            blurRadius: 2)
        let lightShadow: AdjustableShadow = (
            color: .lightGray,
            offset: CGSize(width: 1.5, height: 1.5),
            blurRadius: 2)
        let puzzleMaker = PuzzleMaker(
            image: puzzleImage,
            numRows: numRows,
            numColumns: numColumns,
            darkInnerShadow: darkShadow,
            lightInnerShadow: lightShadow
        )
        puzzleMaker.generatePuzzles { [self] throwableClosure in
            do {
                puzzlePieceImages.removeAll()
                let puzzleElements = try throwableClosure()
                for row in 0 ..< numRows {
                    for column in 0 ..< numColumns {
                        guard let puzzleElement = puzzleElements[row][column] else { continue }
                        let position = puzzleElement.position
                        let image = puzzleElement.image
                        let puzzlePiece =
                            UIImageView(
                                frame: CGRect(x: position.x,
                                              y: position.y,
                                              width:
                                                image.size.width,
                                              height: image.size.height))
                        puzzlePiece.autoresizingMask = [.flexibleWidth,
                                                        .flexibleHeight]
                        puzzlePiece.tag = row * numColumns + column
                        if isPuzzleComplete(at: puzzlePiece.tag) {
                            puzzlePiece.image = image
                        }else if puzzlePiece.tag < tasks.count {
                            puzzlePiece.image = image.withTintColor(
                                UIColor.byPriority(tasks[puzzlePiece.tag].priority).withAlphaComponent(0.4))
                        }else {
                            puzzlePiece.image = image.withTintColor(UIColor.lightGray.withAlphaComponent(0.2))
                        }
                        puzzlePiece.isUserInteractionEnabled = true
                        puzzleContainer.addSubview(puzzlePiece)
                        puzzlePieceImages[puzzlePiece.tag] = image
                    }
                }
                
                puzzleScrollView.addSubview(puzzleContainer)
                if (tasks.count == (numRows * numColumns) && numPiecesCompleted == tasks.count) {
                    displayStamp(animated: false)
                }
                setZoomScale()
            } catch {
                debugPrint(error)
            }
        }
    }
}

extension PuzzleViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        puzzleContainer
    }
}
