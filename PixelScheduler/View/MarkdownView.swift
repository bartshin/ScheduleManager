//
//  MarkdownView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/02/04.
//

import SwiftUI
import Notepad
import Down
import WebKit

struct MarkdownView: View {
	@State private var isEditing: Bool
	@State private var isShowingFullScreen = false
	@StateObject private var styler: MarkDownStyler
	
	@EnvironmentObject var settingController: SettingController
	private let saveText: (String) -> Void
	
	init(markdownText: String?, saveText: @escaping (String) -> Void) {
		_isEditing = .init(initialValue: markdownText == nil || markdownText!.isEmpty)
		_styler = .init(wrappedValue: MarkDownStyler(text: markdownText))
		self.saveText = saveText
	}
	
	var body: some View {
		GeometryReader { geometry in
			VStack {
				topToolbar
				Group {
					if isEditing {
						MarkdownEditorView(coordinator: styler, needKeyboardToolbar: true)
							.onDisappear {
								saveText(styler.text)
							}
						
					}else {
						MarkdownViewer(markdownText: styler.text)
					}
				}
				.frame(width: geometry.size.width,
							 height: geometry.size.height * 0.5)
			}
			
		}
		.onAppear {
			styler.userLanguage = settingController.language
		}
		.sheet(isPresented: $isShowingFullScreen, onDismiss: {
			saveText(styler.text)
		}) {
			if isEditing {
				VStack {
					editorToolbar
						.padding()
					MarkdownEditorView(coordinator: styler, needKeyboardToolbar: false)
						.onDisappear {
							saveText(styler.text)
						}
				}
			}else {
				HStack {
					fullScreenButton
					editButton
				}
				MarkdownViewer(markdownText: styler.text)
			}
		}
	}
	
	@State private var presentingAttachment: Attachment?
	
	private var editorToolbar: some View {
		VStack(spacing: 20) {
			ScrollView(.horizontal, showsIndicators: true){
				HStack {
					fullScreenButton
					editButton
					ForEach(InlineStyle.allCases, content: drawButton(for:))
					ForEach(OneLineStyle.allCases, content: drawButton(for:))
					Button {
						withAnimation(.spring()) {
							presentingAttachment = presentingAttachment == nil ? .link: nil
						}
					} label: {
						TodoListView.createButtonImage(for: Image(systemName: Attachment.link.iconName))
							.frame(width: 40, height: 40)
					}
				}
			}
			if let attachment = presentingAttachment{
				showInputHelper(for: attachment)
			}
		}
	}
	
	private func drawButton<T>(for style: T) -> some View where T: Style{
		Button {
			if let inLineStyle = style as? InlineStyle {
				styler.addInlineStyle(inLineStyle)
			}else if let oneLineStyle = style as? OneLineStyle {
				styler.addOnelineStyle(oneLineStyle)
			}
		}label: {
			TodoListView.createButtonImage(for: Image(systemName: style.iconName))
				.frame(width: 40, height: 40)
		}
	}
	
	@State private var linkName = ""
	@State private var linkAddress = ""
	@State private var isImageLink = false
	
	private func showInputHelper(for attachment: Attachment) -> some View {
		let name: String
		let address: String
		switch settingController.language {
		case .korean:
			name = "링크 이름"
			address = "링크 주소"
		case .english:
			name = "Link name"
			address = "Link URL"
		}
		return HStack {
			Picker(selection: $isImageLink) {
				Image(systemName: "photo").tag(true)
				Image(systemName: "link").tag(false)
			} label: {
				Text("Link type")
			}
			TextField(name, text: $linkName)
				.textFieldStyle(.roundedBorder)
			TextField(address, text: $linkAddress)
				.textFieldStyle(.roundedBorder)
			Button {
				styler.addLink(isImage: isImageLink,
											 name: linkName,
											 url: linkAddress)
				withAnimation(.spring()) {
					presentingAttachment = nil
				}
			} label: {
				Image(systemName: "checkmark")
			}
		}
		.onAppear {
			linkName = ""
			linkAddress = ""
		}
		.transition(.move(edge: .bottom).combined(with: .opacity))
	}
	
	private var topToolbar: some View {
		HStack {
			fullScreenButton
			editButton
		}
	}
	
	private var fullScreenButton: some View {
		Button {
			withAnimation {
				isShowingFullScreen.toggle()
			}
		} label: {
			TodoListView.createButtonImage(for: Image(
				systemName: isShowingFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"))
			.frame(width: 40, height: 40)
		}
	}
	
	private var editButton: some View {
		Button {
			withAnimation {
				isEditing.toggle()
			}
		} label: {
			TodoListView.createButtonImage(for: Image(systemName: isEditing ? "doc.text": "keyboard"))
				.frame(width: 40, height: 40)
		}
	}
	
}

fileprivate protocol Style: Identifiable, CaseIterable{
	var iconName: String { get }
	var action: Selector { get }
	var index: Int { get }
	
	init(index: Int)
}

fileprivate enum InlineStyle: String, Style {
	
	case bold = "**"
	case italic = "*"
	
	var id: String {
		self.rawValue
	}
	
	var offset: Int {
		self.rawValue.count
	}
	
	init(index: Int) {
		self = Self.allCases[index]
	}
	
	var index: Int {
		Self.allCases.firstIndex(of: self)!
	}
	
	var iconName: String {
		switch self {
		case .bold:
			return "bold"
		case .italic:
			return "italic"
		}
	}
	
	var action: Selector {
		#selector(MarkDownStyler.tapInlineStyleButton(_:))
	}
}

fileprivate enum OneLineStyle: String, Style {

	case orderedList
	case unOderedList
	case bigTitle
	case smallTitle
	
	var id: String {
		self.rawValue
	}
	
	init(index: Int) {
		self = Self.allCases[index]
	}
	
	var index: Int {
		Self.allCases.firstIndex(of: self)!
	}
	
	var iconName: String {
		switch self {
		case .orderedList:
			return "list.number"
		case .unOderedList:
			return "list.bullet"
		case .bigTitle:
			return "textformat.size.larger"
		case .smallTitle:
			return "textformat.size.smaller"
		}
	}
	
	var action: Selector {
		#selector(MarkDownStyler.tapOnelineStyleButton(_:))
	}
}

fileprivate enum Attachment: String, Style {
	case link
	
	var id: String {
		self.rawValue
	}
	
	init(index: Int) {
		self = Self.allCases[index]
	}
	
	var index: Int {
		Self.allCases.firstIndex(of: self)!
	}
	
	var iconName: String {
		switch self {
		case .link:
			return "paperclip"
		}
	}
	
	var action: Selector {
		#selector(MarkDownStyler.tapAttachmentButton(_:))
	}
}

fileprivate class MarkDownStyler: NSObject, ObservableObject {
	@Published var text: String
	private let storage = Storage()
	var notepad: Notepad?
	var userLanguage: SettingKey.Language?
	
	private(set) var cursor: NSRange?
	
	init(text: String?) {
		self.text = text ?? ""
	}
	
	@objc func tapInlineStyleButton(_ sender: UIButton) {
		let style = InlineStyle(index: sender.tag)
		addInlineStyle(style)
	}
	
	func addInlineStyle(_ style: InlineStyle) {
		let cursor = self.cursor ?? NSRange(location: 0, length: 0)
		let firstIndex = text.index(
			text.startIndex,
			offsetBy: cursor.lowerBound)
		text.insert(contentsOf: style.rawValue, at: firstIndex)
		let secondIndex = text.index(
			text.startIndex,
			offsetBy: cursor.upperBound + style.offset
		)
		self.cursor = NSRange(location: cursor.location + style.offset, length: cursor.length)
		text.insert(contentsOf: style.rawValue, at: secondIndex)
	}
	
	@objc func tapOnelineStyleButton(_ sender: UIButton) {
		let style = OneLineStyle(index: sender.tag)
		addOnelineStyle(style)
	}
	
	func addOnelineStyle(_ style: OneLineStyle) {
		let cursor = self.cursor ?? NSRange(location: 0, length: 0)
		
		let endIndex = text.index(text.startIndex, offsetBy: max(0, cursor.lowerBound - 1))
		let foundNewLineIndex: String.Index? = endIndex == text.startIndex ? nil: text[...endIndex].lastIndex(of: "\n")
		
		let styleCharacters: String
		switch style {
		case .orderedList:
			guard let foundNewLineIndex = foundNewLineIndex else {
				styleCharacters = "1. "
				break
			}
			let foundNewLineUpper = text[...text.index(before: foundNewLineIndex)].lastIndex(of: "\n")
			let startOfUpperline = foundNewLineUpper != nil ? text.index(before: foundNewLineUpper!): text.startIndex
			
			let upperLine = text[startOfUpperline...foundNewLineIndex]
			let pattern: String = "[0-9]."
			if let range = upperLine.range(of: pattern, options: .regularExpression),
				 let lastNumber = Int(String(text[range.lowerBound])){
				styleCharacters = "\(lastNumber + 1). "
			}
			else {
				styleCharacters = "1. "
			}
		case .unOderedList:
			styleCharacters = "- "
		case .bigTitle:
			styleCharacters = "# "
		case .smallTitle:
			styleCharacters = "### "
		}
		let index: String.Index = foundNewLineIndex != nil ?
		text.index(after: foundNewLineIndex!): text.startIndex
		
		text.insert(contentsOf: styleCharacters, at: index)
		if let cursor = self.cursor {
			self.cursor = NSRange(location: cursor.location + styleCharacters.count, length: cursor.length)
		}
	}
	
	@objc func tapAttachmentButton(_ sender: UIButton) {
		let style = Attachment(index: sender.tag)
		let title: String
		let confirm = userLanguage == .korean ? "확인": "Add"
		let cancel = userLanguage == .korean ? "취소": "Cancel"
		var placeholders = [String]()
		switch style {
		case .link:
			title = userLanguage == .korean ? "링크 추가": "Attach link"
			placeholders.append(userLanguage == .korean ? "링크 이름": "Link name")
			placeholders.append(userLanguage == .korean ? "링크 주소": "Link url")
		}
		let alertVC = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
		let contentVC = CustomAlertViewController(
			message: "",
			segmentSelection: [
			
				UIImage(systemName: "link")!,
				UIImage(systemName: "photo")!
			],
			inputPlaceHolders: placeholders)
	
		contentVC.drawCustomView(in: alertVC)
		
		let scenes = UIApplication.shared.connectedScenes
		guard let windowScene = scenes.first as? UIWindowScene,
					let window = windowScene.windows.first,
		let vc = window.rootViewController else {
			assertionFailure("Fail to get current view controller")
						return
					}
		let confirmAction = UIAlertAction(
			title: confirm,
			style: .default) { [weak weakSelf = self] action in
				let name = contentVC.textInputs[0].text ?? ""
				let url = contentVC.textInputs[1].text ?? ""
				weakSelf?.addLink(isImage: contentVC.segmentedSwitch?.selectedSegmentIndex == 1,
											name: name,
											url: url)
			}
		let cancelAction = UIAlertAction(
			title: cancel,
			style: .cancel,
			handler: nil)
		alertVC.addAction(confirmAction)
		alertVC.addAction(cancelAction)
		vc.present(alertVC, animated: true)
	}
	
	func addLink(isImage: Bool, name: String, url urlString: String) {
		var urlString = urlString
		if urlString.hasPrefix("www") {
			urlString = "http://" + urlString
		}
		guard let url = URL(string: urlString),
					UIApplication.shared.canOpenURL(url) else {
			text.append((userLanguage == .korean ? "[주소가 유효하지 않습니다]": "[Url is not vaild]") + "(\(urlString))")
			return
		}
		let markDownText = (isImage ? "!": "") + "[\(name)](\(url.absoluteString))"
		text.insert(contentsOf: markDownText, at: text.index(text.startIndex, offsetBy: cursor?.upperBound ?? 0))
		if let cursor = cursor {
			self.cursor = NSRange(location: cursor.location + markDownText.count, length: cursor.length)
		}
	}
}

// Mark down editor delegate
extension MarkDownStyler: UITextViewDelegate {
	func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
		cursor = textView.selectedRange
		return true
	}
	
	func textViewDidChange(_ textView: UITextView) {
		text = textView.text
		cursor = textView.selectedRange
	}
	
	func textViewDidChangeSelection(_ textView: UITextView) {
		cursor = textView.selectedRange
	}
}

fileprivate struct MarkdownEditorView: UIViewRepresentable {
	@Environment(\.colorScheme) var colorScheme
	@ObservedObject var coordinator: MarkDownStyler
	@EnvironmentObject var settingController: SettingController
	let needKeyboardToolbar: Bool
	
	func makeCoordinator() -> MarkDownStyler {
		coordinator
	}
	
	func makeUIView(context: Context) -> Notepad {
		let notepad = Notepad(frame: .zero, theme: theme)
		notepad.delegate = coordinator
		notepad.text = coordinator.text
		notepad.backgroundColor = theme.backgroundColor.withAlphaComponent(0.5)
		coordinator.notepad = notepad
		if needKeyboardToolbar {
			notepad.inputAccessoryView = createToolbar()
		}
		notepad.becomeFirstResponder()
		return notepad
	}
	
	private func createToolbar() -> UIToolbar{
		let toolBar = UIToolbar()
		
		var buttons = [UIBarButtonItem]()
		InlineStyle.allCases.forEach {
			buttons.append(createButton(for: $0))
		}
		
		OneLineStyle.allCases.forEach {
			buttons.append(createButton(for: $0))
		}
		
		Attachment.allCases.forEach {
			buttons.append(createButton(for: $0))
		}
		
		toolBar.items = buttons
		
		toolBar.sizeToFit()
		return toolBar
	}
	
	private func createButton<T>(for style: T) -> UIBarButtonItem where T: Style{
		let button = UIButton(
			frame: CGRect(origin: .zero,
										size: CGSize(width: 50, height: 50)))
		button.setImage(UIImage(systemName: style.iconName), for: .normal)
		button.setTitleColor(colorScheme == .light ? .black: .white, for: .normal)

		button.tag = style.index
		button.addTarget(coordinator, action: style.action, for: .touchUpInside)
		return UIBarButtonItem(customView: button)
	}
	
	func updateUIView(_ uiView: Notepad, context: Context) {
		if coordinator.text != uiView.text {
			let cursor = coordinator.cursor
			uiView.text = coordinator.text
			uiView.selectedRange = cursor ?? uiView.selectedRange
		}
		uiView.changeTheme(to: theme)
		uiView.backgroundColor = uiView.backgroundColor?.withAlphaComponent(0.5)
	}
	
	private var theme: Theme {
		switch settingController.visualMode {
		case .system:
			return colorScheme == .light ? Theme("one-light"): Theme("one-dark")
		case .light:
			return Theme("one-light")
		case .dark:
			return Theme("one-dark")
		}
	}
}

fileprivate struct MarkdownViewer: UIViewRepresentable {
	let markdownText: String
	@EnvironmentObject var settingController: SettingController
	
	func makeUIView(context: Context) -> UIView {
		let view = UIView(frame: .zero)
		if let downView = try? DownView(frame: view.frame, markdownString: markdownText) {
			downView.backgroundColor = settingController.palette.quaternary.withAlphaComponent(0.5)
			downView.isOpaque = false
			view.addSubview(downView)
		}
		else {
			let textView = UITextView()
			textView.text = "Fail to render \n" + markdownText
			view.addSubview(textView)
		}
		view.subviews.first!.translatesAutoresizingMaskIntoConstraints = false
		let top = view.subviews.first!.topAnchor.constraint(equalTo: view.topAnchor)
		let bottom = view.subviews.first!.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		let left = view.subviews.first!.leftAnchor.constraint(equalTo: view.leftAnchor)
		let right = view.subviews.first!.rightAnchor.constraint(equalTo: view.rightAnchor)
		view.addConstraints([top, bottom, left, right])
		return view
	}
	
	func updateUIView(_ uiView: UIView, context: Context) {
		uiView.subviews.first?.backgroundColor = settingController.palette.quaternary.withAlphaComponent(0.5)
	}
}

struct MarkdownView_Previews: PreviewProvider {
	static var previews: some View {
		MarkdownView(markdownText: "**Hello markdown** \n - here is detail \n ---------") { text in
				print("Save markdown \n \(text)")
		}
	}
}
