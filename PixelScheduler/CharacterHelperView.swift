//
//  CharacterHelperView.swift
//  PixelScheduler
//
//  Created by Shin on 3/31/21.
//

import SwiftUI
import AVFoundation

struct CharacterHelperView<AB1: View, AB2: View>: View
{
	@EnvironmentObject var settingController: SettingController
	
	private var showQuickHelpTrigger: Binding<Bool>?
	private let character: SettingKey.Character
	private var alert: Binding<CharacterAlert<AB1, AB2>?>?
	private let guide: CharacterPresentingGuide
	private let helpWindowSize: CGSize
	private let balloonStartPosition: CGPoint
	var player: AVAudioPlayer!
	
	@State private var isShowingQuickHelp: Bool = false
	
	private func setShowingQuickHelp(_ newValue: Bool) {
		if let showQuickHelpTrigger = showQuickHelpTrigger {
			showQuickHelpTrigger.wrappedValue = newValue
		}
		withAnimation {
			isShowingQuickHelp = newValue
		}
	}
	
	var isShowingAlert: Bool {
		alert?.wrappedValue != nil
	}
	
	
	init(character: SettingKey.Character, guide: CharacterPresentingGuide,
			 alertToPresent: Binding<CharacterAlert<AB1, AB2>?>? = nil, helpWindowSize: CGSize, balloonStartPosition: CGPoint) {
		self.character = character
		self.guide = guide
		self.helpWindowSize = helpWindowSize
		self.balloonStartPosition = balloonStartPosition
		self.alert = alertToPresent
		self.showQuickHelpTrigger = nil
	}
	
	/// Create hidden view just show alert
	init(character: SettingKey.Character, guide: CharacterPresentingGuide,
			 showingQuickHelp: Binding<Bool>,
			 alertToPresent: Binding<CharacterAlert<AB1, AB2>?>? = nil, helpWindowSize: CGSize, balloonStartPosition: CGPoint) {
		self.character = character
		self.guide = guide
		self.helpWindowSize = helpWindowSize
		self.balloonStartPosition = balloonStartPosition
		self.alert = alertToPresent
		showQuickHelpTrigger = showingQuickHelp
	}
	
	var body: some View {
		
		ZStack {
			if isShowingQuickHelp || isShowingAlert {
				showBackgroundBlur {
					if isShowingQuickHelp {
						setShowingQuickHelp(false)
					}
				}
				.frame(width: UIScreen.main.bounds.size.width * 2,
					   height: UIScreen.main.bounds.size.height * 2)
				.position(x: UIScreen.main.bounds.size.width/2,
						  y: UIScreen.main.bounds.size.height/2)

			}
			Group {
				if let showQuickHelpTrigger = showQuickHelpTrigger {
					characterGif
						.onChange(of: showQuickHelpTrigger.wrappedValue) { isShowing in
							if isShowing, isShowingAlert {
								showQuickHelpTrigger.wrappedValue = false
								return
							}
							withAnimation {
								isShowingQuickHelp = isShowing
							}
						}
				}else {
					characterGif
				}
			}
			
				.overlay(
					Group {
						if isShowingQuickHelp {
							quickHelpView
						}
						else if let alert = alert?.wrappedValue{
							drawAlertWindow(alert)
						}
					}
						.position(x: UIScreen.main.bounds.size.width*0.4,
											y: UIScreen.main.bounds.size.height*0.4)
				)
		}
	}
	
	private var characterGif: some View {
		GIFImage(name: character.idleGif)
			.frame(width: 80, height: 80)
			.opacity(showQuickHelpTrigger != nil ? 0: 1)
			.onTapGesture {
				withAnimation {
					if !isShowingAlert {
						setShowingQuickHelp(true)
					}
				}
			}
	}
	
	private var quickHelpView: some View {
		QuickHelpVCRepresentable(
			settingController: settingController,
			isPresenting: .init(get: {
				isShowingQuickHelp
			}, set: {
				setShowingQuickHelp($0)
			}),
			guide: guide)
			.frame(width: helpWindowSize.width,
						 height: helpWindowSize.height * 0.8)
			.background(
				drawBackgroundBalloon(size: helpWindowSize)
					.offset(y: helpWindowSize.height * -0.1)
					.scaleEffect(CGSize(width: 1.1, height: 1))
			)
			.position(x: balloonStartPosition.x,
								y: balloonStartPosition.y)
	}
	
	private func drawBackgroundBalloon(size: CGSize) -> some View {
		Balloon()
			.size(size)
			.stroke(.black, lineWidth: 2)
			.background(
				Balloon()
					.size(size)
					.fill(Color(settingController.palette.quaternary))
			)
	}
	
	private var alertWindowSize: CGSize {
		CGSize(width: UIScreen.main.bounds.size.width * 0.6,
					 height: UIScreen.main.bounds.size.height * 0.5)
	}
	
	private func drawAlertWindow(_ alert: CharacterAlert<AB1, AB2>) -> some View {
		VStack {
			Text(alert.title)
				.font(.title3)
				.foregroundColor(Color(settingController.palette.primary))
				.frame(height: alertWindowSize.height * 0.1)
			Divider()
				.frame(height: 2)
				.background(Color.black)
				.padding(.bottom, 20)
				.offset(x: -2)
			Text(alert.message)
				.font(.body)
				.foregroundColor(Color(settingController.palette.secondary))
			Spacer()
			HStack(spacing: 20) {
				Button(action: {
					alert.primaryAction()
					self.alert?.wrappedValue = nil
				},
							 label: alert.primaryLabel)
				if let secondaryAction = alert.secondaryAction,
					 let secondaryLabel = alert.secondaryLabel {
					Button(action: {
						secondaryAction()
						self.alert?.wrappedValue = nil
					},
								 label: secondaryLabel)
				}
			}
		}
		.padding(.horizontal, 15)
		.padding(.vertical, 40)
		.frame(width: alertWindowSize.width,
					 height: alertWindowSize.height)
		.background(
			drawBackgroundBalloon(size: alertWindowSize)
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
	private var tableView = UITableView(frame: .zero, style: .grouped)
	var dismiss: (() -> Void)
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.addSubview(tableView)
		tableView.translatesAutoresizingMaskIntoConstraints = false
		tableView.allowsSelection = false
		tableView.showsVerticalScrollIndicator = false
		tableView.register(InstructionCell.self, forCellReuseIdentifier: cellReuseID)
		tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
		tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
		tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
		tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
		tableView.backgroundColor = .clear
		view.backgroundColor = .clear
		tableView.dataSource = self
		tableView.delegate = self
		tableView.rowHeight = UITableView.automaticDimension
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
		cell.backgroundColor = .clear
		return cell
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		30
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
		private var contentHeight: CGFloat = 0
		
		func setGuide(_ guide: CharacterPresentingGuide, at index: Int, color: UIColor) {
			self.guide = guide
			self.textView.attributedText = guide.instructions[index].1
			self.textView.textColor = color
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
			textView.heightAnchor.constraint(equalTo: contentView.heightAnchor, constant: -20).isActive = true
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
	}
	
	
	init(settingController: SettingController,
		 isPresenting: Binding<Bool>,
		 guide: CharacterPresentingGuide) {
		self.settingController = settingController
		self.isPresenting = isPresenting
		self.guide = guide
	}
}

struct CharacterAlert<BV1: View, BV2: View> {
	
	let title: String
	let message: String
	
	let primaryAction: () -> Void
	let primaryLabel: () -> BV1
	let secondaryAction: (() -> Void)?
	let secondaryLabel: (() -> BV2)?
	
	init(title: String, message: String, action: @escaping() -> Void, @ViewBuilder label: @escaping () -> BV1) {
		self.title = title
		self.message = message
		self.primaryAction = action
		self.primaryLabel = label
		self.secondaryAction = nil
		self.secondaryLabel = nil
	}
	
	init(title: String, message: String, primaryAction: @escaping () -> Void, @ViewBuilder primaryLabel: @escaping () -> BV1, secondaryAction: @escaping () -> Void, @ViewBuilder secondaryLabel: @escaping () -> BV2) {
		self.title = title
		self.message = message
		self.primaryAction = primaryAction
		self.primaryLabel = primaryLabel
		self.secondaryAction = secondaryAction
		self.secondaryLabel = secondaryLabel
	}
}
