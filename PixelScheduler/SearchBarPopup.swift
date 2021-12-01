//
//  SearchBarPopup.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/12.
//

import SwiftUI

struct SearchBarPopup: View {
	
	@Binding var isPresented: Bool
	@Binding var searchRequest: (text: String, priority: Int)
	@Binding var showingResult: Bool
	let language: SettingKey.Language
	
    var body: some View {
		VStack {
			HStack {
				Image(systemName: "magnifyingglass")
				TextField("Search", text: $searchRequest.text, onCommit: {
					if !searchRequest.text.isEmpty {
						withAnimation {
							showingResult = true
						}
					}
				})
					.disableAutocorrection(true)
				Button {
					withAnimation {
						isPresented = false
						searchRequest = (text: "", priority: 0)
						showingResult = false
					}
				} label: {
					Image(systemName: "xmark.circle")
				}
			}
			.padding(.vertical, 5)
			.padding(.horizontal, 20)
			.overlay(
				RoundedRectangle(cornerRadius: 20)
					.stroke(Color.black)
			)
			priorityPicker
		}
		.padding(.horizontal, 30)
		.padding(.vertical, 15)
		.transition(.move(edge: .top))
		
	}
	private var priorityPicker: some View {
		Picker("Priority", selection: $searchRequest.priority) {
			Text("All").tag(0)
			ForEach(0..<5, id: \.self) { index in
				Text(Color.PriorityButton.allCases[index].rawValue)
					.tag(index + 1)
			}
		}
		.pickerStyle(.segmented)
	}
}

struct SearchBarPopup_Previews: PreviewProvider {
    static var previews: some View {
		SearchBarPopup(isPresented: .constant(true),
					   searchRequest: .constant(("Search", 0)),
					   showingResult: .constant(true),
					   language: .korean)
    }
}
