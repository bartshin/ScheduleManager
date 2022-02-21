//
//  SelectStickerView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/01/19.
//

import SwiftUI

struct SelectStickerView: View {
	
	@State private var selectedSticker: Sticker?
	private let selectSticker: ((Sticker?) -> Void)?
	private let dragStickerHandler: (() -> Void)?
	private let dismiss: () -> Void
	@EnvironmentObject var settingController: SettingController
	@State private var selectedCollection: Sticker.Collection
	
	init(stickerSet: Sticker?, selectSticker: @escaping (Sticker?) -> Void, dismiss: @escaping () -> Void) {
		_selectedCollection = .init(initialValue: stickerSet?.collection ?? .holiday)
		_selectedSticker = .init(initialValue: stickerSet)
		self.selectSticker = selectSticker
		self.dragStickerHandler = nil
		self.dismiss = dismiss
	}
	
	init(dragStickerHandler: @escaping () -> Void, dismiss: @escaping () -> Void) {
		_selectedCollection = .init(initialValue: .holiday)
		_selectedSticker = .init(initialValue: nil)
		self.selectSticker = nil
		self.dragStickerHandler = dragStickerHandler
		self.dismiss = dismiss
	}
	
	var body: some View {
		GeometryReader { geometry in
			VStack {
				HStack {
					cancelButton
					Spacer()
					collectionPicker
					Spacer()
					if selectSticker != nil {
						confirmButton
					}
				}
				.padding(.horizontal)
				drawStickerPicker(in: geometry.size)
			}
		}
	}
	
	private var cancelButton: some View {
		Image(systemName: selectedSticker != nil ? "delete.left": "chevron.down")
			.font(.title)
			.foregroundColor(.pink)
			.onTapGesture {
				selectSticker?(nil)
				dismiss()
			}
	}
	
	private var confirmButton: some View {
		Image(systemName: "checkmark.square")
			.font(.title)
			.foregroundColor(.green)
			.onTapGesture {
				if let selectedSticker = selectedSticker {
					selectSticker?(selectedSticker)
				}
				dismiss()
			}
	}
	
	private var collectionPicker: some View {
		HStack {
			collectionPickerLabel
			Picker(selection: $selectedCollection) {
				ForEach(Sticker.Collection.allCases) { collection in
					switch settingController.language {
					case .korean:
						Text(collection.koreanName).tag(collection)
					case .english:
						Text(collection.rawValue).tag(collection)
					}
				}
			} label: {
				Text("Collection")
			}
			.pickerStyle(.menu)
			.padding(5)
			.fixedSize()
			.background(
				RoundedRectangle(cornerRadius: 10)
					.stroke(Color.accentColor, lineWidth: 2)
			)
		}
	}
	
	private var collectionPickerLabel: some View {
		let text: String
			switch settingController.language {
			case .english:
				text = "Collection"
			case .korean:
				text = "모음집"
					
			}
		return Text(text)
			.withCustomFont(size: .subheadline, for: settingController.language)
	}
	
	private func drawStickerPicker(in size: CGSize) -> some View {
		LazyVGrid(columns: [GridItem(.adaptive(minimum: size.width / 5, maximum: size.width / 6), spacing: 10, alignment: .center)]) {
			ForEach(selectedCollection.allStickers) { sticker in
				if dragStickerHandler != nil {
					if #available(iOS 15.0, *) {
						drawSticker(sticker)
							.onDrag {
								dragStickerHandler!()
								return createItemProvider(for: sticker)
							} preview: {
								drawSticker(sticker)
									.frame(width: 60, height: 60)
							}
					} else {
						drawSticker(sticker)
							.onDrag {
								dragStickerHandler!()
								return createItemProvider(for: sticker)
							}
					}

				}else {
					drawSticker(sticker)
				}
			}
		}
	}
	
	private func createItemProvider(for sticker: Sticker) -> NSItemProvider {
		let dict = [
			"itemType": "sticker",
			"id": sticker.id
		]
		guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
					let json = String(data: data, encoding: .utf8) else {
						return NSItemProvider()
					}
		let provider = NSItemProvider()
		provider.registerObject(json as NSString, visibility: .ownProcess)
		return provider
	}
	
	private func drawSticker(_ sticker: Sticker) -> some View {
		Image(uiImage: sticker.image)
			.resizable()
			.aspectRatio(1, contentMode: .fit)
			.padding()
			.background(
				Group {
					if selectedSticker == sticker {
						RoundedRectangle(cornerRadius: 20)
							.fill(Color.accentColor.opacity(0.5))
					}
				}
			)
			.onTapGesture {
				withAnimation {
					selectedSticker = sticker
				}
			}
	}
}

struct SelectStickerView_Previews: PreviewProvider {
	static var previews: some View {
		SelectStickerView(stickerSet: nil,
											selectSticker: { _ in }, dismiss: {})
			.environmentObject(SettingController())
	}
}
