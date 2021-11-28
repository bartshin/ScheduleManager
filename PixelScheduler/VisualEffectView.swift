//
//  VisualEffectView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/12.
//

import SwiftUI

extension View {
	func showBackgroundBlur(cancelHandler: @escaping () -> Void) -> some View {
		VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
			.onTapGesture {
				withAnimation{
					cancelHandler()
				}
			}
	}
}

struct VisualEffectView: UIViewRepresentable {
	var effect: UIVisualEffect?
	func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
	func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}
