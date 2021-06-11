//
//  ScrollviewData.swift
//  ScheduleManager
//
//  Created by Shin on 3/24/21.
//

import Foundation
import UIKit

class ScrollViewDataSource: ObservableObject {
	
	// MARK: Properties
	var scheduleShowing = [Schedule]() {
		didSet {
			schedulesUnique = idsUnique.compactMap { id in
				scheduleShowing.first{ $0.id == id }
			}
			schedulesAllDay = idsAllday.compactMap { id in
				scheduleShowing.first{ $0.id == id }
			}
			schedulesOverlapped =
				idsOverlapped.compactMap { ids in
					ids.compactMap { id in
						scheduleShowing.first { $0.id == id }
					}
				}
			objectWillChange.send()
		}
	}
	var profileImages = [UUID: UIImage]() {
		didSet {
			if !profileImages.isEmpty {
				objectWillChange.send()
			}
		}
	}
	
	var idsUnique = [UUID]()
	var idsAllday = [UUID]()
	var idsOverlapped = [[UUID]]()
	
	var schedulesUnique = [Schedule]()
	var schedulesAllDay = [Schedule]()
	var schedulesOverlapped = [[Schedule]]()
	
	// MARK:- Schedule distribute logic
	
	func setNewSchedule(_ newValue: [Schedule], of date: Date) {
		func findOverlappingIndex(of schedule: Schedule, in scheduleArr: [Schedule]) -> [Int] {
			var indices = [Int]()
			let rangeOfSchedule = calcTimeRange(of: schedule, in: date)
			for (index, scheduleToCheck) in scheduleArr.enumerated() {
				if schedulesAllDay.contains(scheduleToCheck.id) {
					continue
				}
				if rangeOfSchedule.overlaps(calcTimeRange(of: scheduleToCheck, in: date)) {
					indices.append(index)
				}
			}
			return indices
		}
		var schedulesUnique = [UUID]()
		var schedulesAllDay = [UUID]()
		var schedulesOverlapped = [[UUID]]()
		var overlappedIndices = Set<Int>()
		for (index, schedule) in newValue.enumerated() {
			if case .period(let startDate, let endDate) = schedule.time,
				 (startDate < date.startOfDay) || startDate.isSameDay(with: date),
				 (endDate - max(date.startOfDay, startDate)) > (TimeInterval.forOneDay - 60 * 60) {
				// More than 23 hour for day
				schedulesAllDay.append(schedule.id)
				continue
			}
			if overlappedIndices.contains(index) {
				continue
			}
			let overlappingToSchedule = findOverlappingIndex(of: schedule,
																											 in: newValue)
			if overlappingToSchedule.count == 1 {
				schedulesUnique.append(schedule.id)
			}else {
				overlappingToSchedule.forEach {
					overlappedIndices.insert($0)
				}
				let overlappedSchedules = overlappingToSchedule
					.compactMap{ newValue[$0].id }
				schedulesOverlapped.append(overlappedSchedules)
			}
		}
		idsUnique = schedulesUnique
		idsAllday = schedulesAllDay
		idsOverlapped = schedulesOverlapped
		scheduleShowing = newValue
	}
	
	private func calcTimeRange(of schedule: Schedule, in date: Date) -> ClosedRange<TimeInterval> {
		switch schedule.time {
		case .spot(let date):
			let time = date.timeIntervalSinceReferenceDate
			return (time - TimeInterval(60 * 30)) ...
				time + TimeInterval(60 * 30)
		case .period(start: let startDate, end: let endDate):
			let startTime = max(startDate.timeIntervalSinceReferenceDate, date.startOfDay.timeIntervalSinceReferenceDate)
			let nextDate = date.addingTimeInterval(TimeInterval.forOneDay)
			let endTime = min(endDate.timeIntervalSinceReferenceDate,
												nextDate.timeIntervalSinceReferenceDate)
			return startTime ... endTime
		case .cycle(since: let date, _, _):
			let time = date.timeIntervalSinceReferenceDate
			return (time - TimeInterval(60 * 30)) ...
				time + TimeInterval(60 * 30)
		}
	}
}
