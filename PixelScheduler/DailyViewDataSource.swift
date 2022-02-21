//
//  ScrollviewData.swift
//  PixelScheduler
//
//  Created by Shin on 3/24/21.
//

import Foundation
import SwiftUI

class DailyViewDataSource: ObservableObject {
	
	// MARK: Properties
	
	var profileImages = [UUID: UIImage]() {
		didSet {
			if !profileImages.isEmpty {
				objectWillChange.send()
			}
		}
	}
	
	private(set) var firstScheduleOfDay: (id: Schedule.ID, date: Date?)?
	private(set) var idsUnique = [UUID]()
	private(set) var idsAllday = [UUID]()
	private(set) var idsOverlapped = [[UUID]]()
	
	// MARK: - Schedule distribute logic
	
	func setNewSchedule(_ newSchedules: [Schedule], of date: Date) {
		firstScheduleOfDay = nil
		var newSchedules = newSchedules
		var schedulesUnique = [UUID]()
		var schedulesAllDay = [UUID]()
		var schedulesOverlapped = [[UUID]]()
		var overlappedIndices = Set<Int>()
		
		// Remove all day schedules
		
		newSchedules.forEach { schedule in
			if case .period(let startDate, let endDate) = schedule.time,
				 (startDate < date.startOfDay) || startDate.isSameDay(with: date),
				 (endDate - max(date.startOfDay, startDate)) > (TimeInterval.forOneDay - 60 * 60) {
				// More than 23 hour for day
				schedulesAllDay.append(schedule.id)
				newSchedules.remove(at: newSchedules.firstIndex(of: schedule)!)
				firstScheduleOfDay = (id: schedule.id, date: nil)
			}
		}
		
		for (index, schedule) in newSchedules.enumerated() {
			let scheduleDate: Date
			switch schedule.time {
			case .spot(let date):
				scheduleDate = date
			case .period(let date, _):
				scheduleDate = date
			case .cycle(let defaultDate, _, _):
				scheduleDate = Calendar.current.date(bySettingHour: defaultDate.hour, minute: defaultDate.minute, second: 0, of: date)!
			}
			if schedulesAllDay.isEmpty {
				if firstScheduleOfDay == nil {
					firstScheduleOfDay = (id: schedule.id, date: scheduleDate)
				}
				else if let firstSchduleDate = firstScheduleOfDay?.date,
								firstSchduleDate > scheduleDate {
					firstScheduleOfDay = (id: schedule.id, date: scheduleDate)
				}
			}
			if overlappedIndices.contains(index) {
				continue
			}
			var overlappingToSchedule = [Int]()
			let rangeOfSchedule = calcTimeRange(of: schedule, in: date)
			for (index, scheduleToCheck) in newSchedules.enumerated() {
				
				if rangeOfSchedule.overlaps(calcTimeRange(of: scheduleToCheck, in: date)) {
					overlappingToSchedule.append(index)
				}
			}
			
			if overlappingToSchedule.count == 1 {
				schedulesUnique.append(schedule.id)
			}else {
				overlappingToSchedule.forEach {
						overlappedIndices.insert($0)
				}
				let overlappedSchedules = overlappingToSchedule
					.compactMap{
						newSchedules[$0].id
					}
				schedulesOverlapped.append(overlappedSchedules)
			}
		}
		idsUnique = schedulesUnique
		idsAllday = schedulesAllDay
		idsOverlapped = schedulesOverlapped
			
		objectWillChange.send()
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
