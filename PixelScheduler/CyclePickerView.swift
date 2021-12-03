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
	@ObservedObject var selected: Selected
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
	private let segmentType: CycleType
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
		Group {
			switch segmentType {
				case .weekly:
					weeklyCyclePicker
						.onAppear(perform: clearSelections)
				case .monthly:
					monthlyCyclePicker
						.onAppear(perform: clearSelections)
						.padding(.horizontal, 10)
			}
		}
	}
	
	private func clearSelections() {
		selected.selectedIndices.removeAll()
	}
	
	private func isSelected(_ index: Int) -> Bool{
		selected.selectedIndices.contains(index)
	}
	
	private var weeklyCyclePicker: some View {
		HStack(spacing: 10) {
			ForEach(Array(weekdays.enumerated()), id: \.element) { index, weekday in
				drawWeekdayButton(index: index, weekday: weekday)
					.onTapGesture {
						toggleSelection(index: index)
					}
			}
		}
	}
	
	private func toggleSelection(index: Int) {
		withAnimation{
			if selected.selectedIndices.contains(index) {
				selected.selectedIndices.remove(index)
			}else {
				selected.selectedIndices.insert(index)
			}
		}
	}
	
	private func drawWeekdayButton(index: Int, weekday: String) -> some View {
		ZStack {
			RoundedRectangle(cornerRadius: 15)
				.foregroundColor(Color.black)
				.frame(width: 35,
					   height: 35)
			RoundedRectangle(cornerRadius: 15)
				.foregroundColor(isSelected(index) ? selectedColor : unSelectedColor)
				.frame(width: 33,
					   height: 33)
			Text(weekday)
				.foregroundColor(isSelected(index) ? .white : colorOfDay(weekday))
				.font(language == .korean ? .title3: .body)
				.bold()
		}
		.scaleEffect(isSelected(index) ? 1.2: 1)
	}
	
	private var monthlyCyclePicker: some View {
		LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))]) {
			ForEach(1...31, id: \.self) { day in
				drawMonthDayButton(day)
				.onTapGesture {
					toggleSelection(index: day)
				}
				.padding(.vertical, 5)
			}
		}
	}
	
	private func drawMonthDayButton(_ day: Int) -> some View {
		ZStack {
			RoundedRectangle(cornerRadius: 15)
				.foregroundColor(isSelected(day) ? selectedColor : unSelectedColor)
				.frame(width: 33,
					   height: 33)
			Text(String(day))
				.foregroundColor(isSelected(day) ? .white : .black)
		}
		.scaleEffect(isSelected(day) ? 1.2: 1)
	}
	
	init(selected: Self.Selected, language: SettingKey.Language, segmentType: CycleType) {
		self.selected =  selected
		self.language = language
		self.segmentType = segmentType
	}
}

struct MultiSegmentView_Previews: PreviewProvider {
	static var previews: some View {
		CyclePickerView(selected: CyclePickerView.Selected(),
						language: .korean,
						segmentType: .monthly)
			.frame(width: 350, height: 50)
	}
}

