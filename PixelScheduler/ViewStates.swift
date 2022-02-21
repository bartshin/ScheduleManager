//
//  ViewStates.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/02/18.
//

import Combine
import SwiftUI

class ViewStates: ObservableObject {
	
	@Published var mainTabViewTab: MainTabView.Tab = .scheduleTab
	
	// Schedule tab
	
	@Published var scheduleViewDate = Date()
	@Published var weeklyViewDateInt: Int? = nil
	@Published var presentingScheduleId: Schedule.ID?
	@Published var isShowingNewScheduleSheet = false
	
	// Todo tab
	@Published var isCategoryExpanded = true
	@Published var isEditingCategory = false
	@Published var editingTask: Task?
	@Published var presentingTaskId: Task.ID?
	@Published var taskSort: Task.Sort = .priorityAscend
	
	@Published var floatingViewsAreCollapsed = true {
		didSet {
			if floatingViewsAreCollapsed {
				UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
			}
		}
	}
	@Published var isShowingList = false
	@Published var isShowingQuickHelp = false
	@Published var alert: CharacterAlert<Text, Text>? = nil
	
	@Published var currentShowingCollection: TaskCollection? {
		willSet {
			if currentShowingCollection != newValue {
				DispatchQueue.main.async { [weak weakSelf = self] in
					withAnimation {
						weakSelf?.presentingTaskId = nil
					}
				}
			}
		}
	}
	
	var showTask: ((Task.ID) -> Void)?
	
	var showingFloatingButton: Bool {
		!isCategoryExpanded && currentShowingCollection != nil &&
		!isShowingList &&
		floatingViewsAreCollapsed
	}
}
