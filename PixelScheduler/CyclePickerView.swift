//
//  CyclePickerView.swift
//  Schedule_B
//
//  Created by Shin on 2/28/21.
//

import SwiftUI

struct CyclePickerView: View {
	
	/// Read from outside
	class Selected: ObservableObject {
		@Published var selectedIndices = Set<Int>()
	}
	@ObservedObject var selected = Selected()
	@State private var dateToAdd: Int = 1
	let language: SettingKey.Language
	var weekdays: [String] {
		switch language {
		case .korean:
			return Calendar.koreanWeekDays
		case .english:
			return Calendar.englishWeekDays
		}
	}
	
	// MARK: - View properties
	var currentSegmentType: CycleType	
	private let selectedColor = Color.blue
	private let unSelectedColor = Color(white: 0.95)
	private func colorOfDay(_ day: String) -> Color {
		switch day {
		case "일", "Sun":
			return Color.pink
		case "토", "Sat":
			return Color.blue
		default:
			return Color.black
		}
	}
	/// Index of  selected date type
	enum CycleType {
		case weekly
		case monthly
	}
	
	var body: some View {
		GeometryReader{ geometry in
			Group {
				switch currentSegmentType {
				case .weekly:
					HStack(spacing: 10) {
						ForEach(Array(weekdays.enumerated()), id: \.element) { index, weekday in
							ZStack {
								RoundedRectangle(cornerRadius: 15)
									.foregroundColor(Color.black)
									.frame(width: 35,
												 height: 35)
								RoundedRectangle(cornerRadius: 15)
									.foregroundColor(selected.selectedIndices.contains(index) ? selectedColor : unSelectedColor)
									.frame(width: 33,
												 height: 33)
								Text(weekday)
									.foregroundColor(selected.selectedIndices.contains(index) ? .white : colorOfDay(weekday))
									.font(language == .korean ? .title3: .body)
									.bold()
							}
							.onTapGesture {
								if selected.selectedIndices.contains(index) {
									selected.selectedIndices.remove(index)
								}else {
									selected.selectedIndices.insert(index)
								}
							}
						}
					}
					.onAppear {
						selected.selectedIndices.removeAll()
					}
				case .monthly:
					
					VStack{
						HStack {
							Text("매 월 ")
							let sortedIndices = selected.selectedIndices.sorted(by: <)
							ForEach(sortedIndices, id: \.self) {
								Text("\($0)일" + (sortedIndices.last == $0 ? "": ", "))
							}
						}
						Picker(selection: $dateToAdd, label: Text("매달 ")) {
							ForEach(1..<32){
								Text("\($0) 일")
							}
						}
						.frame(maxWidth: geometry.size.width * 0.2)
						Button(action: {
							selected.selectedIndices.insert(dateToAdd + 1)
						}, label: {
							HStack{
								Image(systemName: "plus.circle")
								Text("반복 추가")
							}
						})
					}
					.onAppear {
						selected.selectedIndices.removeAll()
					}
					.offset(x: geometry.size.width * 0.05)
				}
			}
			.frame(width: geometry.size.width,
						 height: geometry.size.height, alignment: .center)
		}
	}
}

struct MultiSegmentView_Previews: PreviewProvider {
	static var previews: some View {
		CyclePickerView(language: .english, currentSegmentType: .monthly)
			.frame(width: 350, height: 50, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
	}
}

