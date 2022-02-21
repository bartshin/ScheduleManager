//
//  Task.swift
//  PixelScheduler
//
//  Created by Shin on 3/25/21.
//

import Foundation

struct Task: Codable, Equatable, Hashable {
	typealias ID = UUID
	
	enum Sort: Int, CaseIterable, Identifiable {
		case priorityAscend
		case priorityDescend
		
		var function: ((Task), (Task)) -> Bool {
			switch self {
			case .priorityAscend:
				return {$0.priority < $1.priority}
			case .priorityDescend:
				return {$0.priority > $1.priority}
			}
		}
		
		var id: Int {
			self.rawValue
		}
	}
	
	struct CompletionLog: Codable, Equatable, Hashable {
		struct History: Codable, Equatable, Hashable, Identifiable {
			let addedAmount: Double
			let date: Date
			var id: String {
				"\(date.timeIntervalSinceReferenceDate)" + String(addedAmount)
			}
		}
		var unit: String
		var total: Double
		private(set) var histories: [History]
		var current: Double {
			histories.reduce(into: 0.0) { acc, history in
				acc += history.addedAmount
			}
		}
		
		mutating func addHistory(_ newHistory: History) {
			self.histories = (self.histories + [newHistory]).sorted(by: {
				$0.date < $1.date
			})
		}
		
		mutating func removeHistoryUntilNotComplete() {
			while current >= total {
				histories.removeLast()
			}
		}
		
		func calcAccumulation(to date: Date) -> Double{
			guard !histories.isEmpty else {
				return 0
			}
			return histories.reduce(into: 0.0) { acc, history in
				if history.date <= date {
					acc += history.addedAmount
				}
			}
		}
		
		func createCompletedLog() -> CompletionLog {
			var log = self
			let rest = log.total - log.current
			let newHistory = CompletionLog.History(addedAmount: rest, date: Date())
			log.addHistory(newHistory)
			return log
		}
	}
	
	var text: String
	var isCompleted: Bool {
		set {
			if completionLog == nil {
				complete = newValue
			}
			else {
				if newValue {
					self.completionLog = self.completionLog!.createCompletedLog()
				} else {
					completionLog!.removeHistoryUntilNotComplete()
				}
			}
			
 		}
		get {
			if let log = completionLog {
				return log.current >= log.total
			} else {
				return complete
			}
		}
	}
	var complete = false
	var priority: Int
	let id: UUID
	var mdText: String?
	var completionLog: CompletionLog?
	
	init(text: String, priority: Int, id: UUID? = nil, mdText: String? = nil) {
		self.text = text
		self.priority = priority
		if id != nil {
			self.id = id!
		}else {
			self.id = UUID()
		}
		self.mdText = mdText
	}
	
	// Dummy data
	
	static var shopingList: [Task] {
		
		var shopingList = [
			Task(text: "사과", priority: 1),
			Task(text: "허니 버터", priority: 2),
			Task(text: "커피", priority: 3),
			Task(text: "양말", priority: 4),
			Task(text: "생수", priority: 5)
		]
		
		
		shopingList[1].complete = true
		shopingList[3].complete = true
		return shopingList
	}
	
	static var moviePuzzle: [Task] {
		
		var moviePuzzle = [
			Task(text: "남산의 부장들", priority: 5),
			Task(text: "다만 악에서 구하소서", priority: 3),
			Task(text: "반도", priority: 2),
			Task(text: "테넷", priority: 4),
			Task(text: "살아있다", priority: 2),
			Task(text: "백두산", priority: 1),
			Task(text: "히트맨", priority: 3),
			Task(text: "강철비2", priority: 4),
			Task(text: "미나리", priority: 1)
		]
		for index in 0...5 {
			moviePuzzle[index].complete = true
		}
		return moviePuzzle
	}
	
}
