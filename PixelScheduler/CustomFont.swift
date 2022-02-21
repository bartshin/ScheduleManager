//
//  CustomFont.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/01/10.
//

import SwiftUI

struct CustomFont: ViewModifier {
	@Environment(\.sizeCategory) var sizeCategory
	var textStyle: Font.TextStyle
	let fontName: String
	
	init(size textStyle: Font.TextStyle = .body, for language: SettingKey.Language) {
		self.textStyle = textStyle
		self.fontName = language.font
	}
	
	func body(content: Content) -> some View {
		content.font(getFont())
	}
	
	func getFont() -> Font {
		switch(sizeCategory) {
		case .extraSmall:
			return Font.custom(fontName, size: 16 * getStyleFactor(), relativeTo: textStyle)
		case .small:
			return Font.custom(fontName, size: 21 * getStyleFactor(), relativeTo: textStyle)
		case .medium:
			return Font.custom(fontName, size: 24 * getStyleFactor(), relativeTo: textStyle)
		case .large:
			return Font.custom(fontName, size: 28 * getStyleFactor(), relativeTo: textStyle)
		case .extraLarge:
			return Font.custom(fontName, size: 32 * getStyleFactor(), relativeTo: textStyle)
		case .extraExtraLarge:
			return Font.custom(fontName, size: 36 * getStyleFactor(), relativeTo: textStyle)
		case .extraExtraExtraLarge:
			return Font.custom(fontName, size: 40 * getStyleFactor(), relativeTo: textStyle)
		case .accessibilityMedium:
			return Font.custom(fontName, size: 48 * getStyleFactor(), relativeTo: textStyle)
		case .accessibilityLarge:
			return Font.custom(fontName, size: 52 * getStyleFactor(), relativeTo: textStyle)
		case .accessibilityExtraLarge:
			return Font.custom(fontName, size: 60 * getStyleFactor(), relativeTo: textStyle)
		case .accessibilityExtraExtraLarge:
			return Font.custom(fontName, size: 66 * getStyleFactor(), relativeTo: textStyle)
		case .accessibilityExtraExtraExtraLarge:
			return Font.custom(fontName, size: 72 * getStyleFactor(), relativeTo: textStyle)
		@unknown default:
			return Font.custom(fontName, size: 36 * getStyleFactor(), relativeTo: textStyle)
		}
	}
	
	func getStyleFactor() -> CGFloat {
		switch textStyle {
		case .caption:
			return 0.4
		case .footnote:
			return 0.3
		case .subheadline:
			return 0.6
		case .callout:
			return 0.3
		case .body:
			return 0.5
		case .headline:
			return 0.7
		case .title:
			return 1.0
		case .largeTitle:
			return 1.2
		case .title2:
			return 0.9
		case .title3:
			return 0.8
		case .caption2:
			return 0.35
		@unknown default:
			return 1.0
		}
	}
}

extension Text {
	func withCustomFont(size: Font.TextStyle, for language: SettingKey.Language) -> some View {
		self.baselineOffset(language == .korean ? 5: 0)
			.modifier(CustomFont(size: size, for: language))
	}
}
