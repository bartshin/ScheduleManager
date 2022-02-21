//
//  Dayoff.swift
//  PixelSchedulerWidgetExtension
//
//  Created by Shin on 4/17/21.
//

import SwiftUI
import WidgetKit

struct Dayoff: View {
	
	private let config: UserConfig
	private let size: CGSize
	
	var body: some View {
		VStack (spacing: 10) {
			Image("dayoff_icon")
				.resizable()
				.renderingMode(.template)
				.foregroundColor(Color(config.palette.tertiary))
				.frame(width: size.width * 0.3,
							 height: size.height * 0.3)
			emptyScheduleLabel
			.foregroundColor(Color(config.palette.secondary))
			Link(destination: CustomWidgetURL.create(for: .schedule, at: nil, objectID: nil), label: {
				Text("스케줄 추가하기")
					.font(.body)
					.bold()
					.foregroundColor(Color(config.palette.primary))
					.padding(5)
					.background(Color(config.palette.tertiary.withAlphaComponent(0.5)))
					.cornerRadius(10)
			})
		}
	}
	
	private var emptyScheduleLabel: some View {
		let text: String
		switch config.dateLanguage {
		case .korean:
			text = "일정이 없습니다"
		case .english:
			text = "No Schedule"
		}
		return Text(text)
			.withCustomFont(size: .title3, for: config.dateLanguage)
	}
	
	init(config: UserConfig, in size: CGSize) {
		self.config = config
		self.size = size
	}
}


