//
//  ScheduleView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/20.
//

import SwiftUI

struct ScheduleView: View {
	@EnvironmentObject var states: ViewStates
	@EnvironmentObject var scheduleController: ScheduleModelController
	@EnvironmentObject var settingController: SettingController
	@State private var scheduleToEdit: Schedule? = nil
	@State private var alert: CharacterAlert<Text, Text>? = nil
	@State private var selectStickerSheetState = SheetView<SelectStickerView>.CardState.hide
	@State private var stickerSheetOpacity: CGFloat = 1.0
	
	var body: some View {
		NavigationView {
			GeometryReader { geometry in
				ZStack {
					CalendarView(states: _states)
						.navigationBarTitle("")
						.navigationBarHidden(true)
					floatingButtons
						.position(x: geometry.size.width - 60,
											y: geometry.size.height - 60)
						.sheet(isPresented: $states.isShowingNewScheduleSheet) {
							EditScheduleView(selectedDate: Date())
						}
						.sheet(item: $scheduleToEdit) { schedule in
							EditScheduleView(scheduleToEdit: schedule)
						}
					drawCharacterHelper(in: geometry.size)
					stickerPickerSheet
						.opacity(stickerSheetOpacity)
				}
			}
		}
		.environmentObject(scheduleController)
		.environmentObject(settingController)
	}
	
	private func drawCharacterHelper(in size: CGSize) -> some View {
		CharacterHelperView<Text, Text>(
			character: settingController.character,
			guide: .monthlyCalendar,
			alertToPresent: $alert,
			helpWindowSize: CGSize(width: size.width * 0.9,
														 height: size.height * 0.7),
			balloonStartPosition: CGPoint(x: 70, y: 50))
			.frame(width: 80, height: 80)
			.position(x: 50, y: 30)
	}
	
	private var floatingButtons: some View {
		HStack {
			Button {
				withAnimation {
					stickerSheetOpacity = 1
					selectStickerSheetState = .middle
				}
			} label: {
				Image("sticker_icon")
					.resizable()
					.frame(width: 50, height: 50)
			}
			Button {
				states.isShowingNewScheduleSheet = true
			} label: {
				Image("add_schedule_orange")
					.resizable()
					.frame(width: 50, height: 50)
			}
		}
	}
	
	private var stickerPickerSheet: some View {
		SheetView(cardState: $selectStickerSheetState, handleColor: nil, backgroundColor: nil, cardStatesAvailable: [.hide, .middle])  {
			SelectStickerView{ 
				withAnimation {
					stickerSheetOpacity = 0
					selectStickerSheetState = .suspened
				}
			} dismiss: {
				selectStickerSheetState = .hide
			}
		}
	}
}
