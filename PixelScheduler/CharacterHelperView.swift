//
//  CharacterHelperView.swift
//  PixelScheduler
//
//  Created by Shin on 3/31/21.
//

import SwiftUI
import AVFoundation

struct CharacterHelperView: View
//, PlaySoundEffect
{
	@EnvironmentObject var settingController: SettingController
	@State private var isShowingQuickHelp = false
	let character: SettingKey.Character
	let guide: CharacterPresentingGuide
	let helpWindowSize: CGSize
	let characterLocation: CGPoint
	var player: AVAudioPlayer!
	
	var body: some View {
		
		GIFImage(name: character.idleGif)
			.frame(width: 80, height: 80)
			.onTapGesture {
				withAnimation {
					isShowingQuickHelp = true
				}
			}
			.overlay(
				Group {
					if isShowingQuickHelp {
						QuickHelpVCRepresentable(settingController: settingController,
												 isPresenting: $isShowingQuickHelp,
												 guide: guide)
							.frame(width: helpWindowSize.width,
								   height: helpWindowSize.height)
							.background(
						Balloon()
							.size(helpWindowSize)
							.stroke(.black, lineWidth: 2)
						)
					}
				}
					.position(x: UIScreen.main.bounds.width*0.4,
							  y: UIScreen.main.bounds.height*0.4)
			)
	}
	
	
}

class QuickHelpVC: UIViewController {
	
	// MARK: Controller
	var settingController: SettingController
	
	// MARK: - Properties
	
	static let storyboadID = "QuikHelpVC"
	private let cellReuseID = "InstructionCell"
	var guide: CharacterPresentingGuide
	private var tableView = UITableView()
	var dismiss: (() -> Void)
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.addSubview(tableView)
		tableView.translatesAutoresizingMaskIntoConstraints = false
		tableView.register(InstructionCell.self, forCellReuseIdentifier: cellReuseID)
		tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
		tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
		tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
		tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
		tableView.backgroundColor = .clear
		view.backgroundColor = .clear
		tableView.dataSource = self
		tableView.delegate = self
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		applyColorScheme(settingController.visualMode)
	}
	
	init(settingController: SettingController,
		 guide: CharacterPresentingGuide, dismiss: @escaping () -> Void) {
		self.settingController = settingController
		self.guide = guide
		self.dismiss = dismiss
		super.init(nibName: nil, bundle: nil)
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}

extension QuickHelpVC: UITableViewDataSource, UITableViewDelegate {
	
	func numberOfSections(in tableView: UITableView) -> Int {
		guide.instructions.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		1
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseID) as!
		InstructionCell
		
		cell.setGuide(guide, at: indexPath.section, color: settingController.palette.primary)
		return cell
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		20
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let title =  guide.instructions[section].0
		let header = CustomTableHeaderFooter(for: .CustomHeader, title: title)
		header.title!.font = UIFont(name: "YANGJIN", size: 18)
		header.title!.textColor = settingController.palette.secondary
		return header
	}
	
	class InstructionCell: UITableViewCell {
		
		private var guide: CharacterPresentingGuide?
		private var textView: UITextView
		private var textColor: UIColor?
		
		func setGuide(_ guide: CharacterPresentingGuide, at index: Int, color: UIColor) {
			self.guide = guide
			self.textView.attributedText = guide.instructions[index].1
			self.textView.textColor = color
			textView.sizeToFit()
		}
		
		override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
			textView = UITextView()
			textView.translatesAutoresizingMaskIntoConstraints = false
			textView.backgroundColor = .clear
			textView.textContainer.lineBreakMode = .byWordWrapping
			textView.isScrollEnabled = false
			textView.isEditable = false
			textView.isSelectable = false
			super.init(style: style, reuseIdentifier: reuseIdentifier)
			contentView.addSubview(textView)
			textView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
			textView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
			textView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.8).isActive = true
		}
		
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
}


struct QuickHelpVCRepresentable: UIViewControllerRepresentable {
	
	private let settingController: SettingController
	private var isPresenting: Binding<Bool>
	private let guide: CharacterPresentingGuide
	
	func makeUIViewController(context: Context) -> some UIViewController {
		QuickHelpVC(settingController: settingController,
					guide: guide) {
			withAnimation {
				isPresenting.wrappedValue = false
			}
		}
	}
	
	func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
		print("There is something to update for Quickhelp view")
	}
	
	
	init(settingController: SettingController,
		 isPresenting: Binding<Bool>,
		 guide: CharacterPresentingGuide) {
		self.settingController = settingController
		self.isPresenting = isPresenting
		self.guide = guide
	}
}
