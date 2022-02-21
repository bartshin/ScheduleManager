//
//  TaskModelController.swift
//  PixelScheduler
//
//  Created by Shin on 3/24/21.
//

import Foundation
import Combine
import WidgetKit

class TaskModelController: ObservableObject {
	
	typealias Table = [TaskCollection: [Task]]
	private let taskDataFileName = "user_task_data"
	private let taskWidgetKind = "TaskWidget"
	private let widgetTaskFileName = "widget_task_data"
	
	private var isDataLoaded = false
	@Published private(set) var table: Table
	var autoTaskSaveCancellable: AnyCancellable?
	
	var collections: [TaskCollection] {
		Array(table.keys).sorted(by: { $0.title < $1.title})
	}
	
	func getTask(by id: Task.ID, from collection: TaskCollection?) -> Task? {
		if let collection = collection,
			 let found = table[collection]?.first(where: {
				 $0.id == id
			 }){
				return found
		}else {
			for tasks in table.values {
				if let found = tasks.first(where: {
					$0.id == id
				}) {
					return found
				}
			}
		}
		return nil
	}
	
	func addNewCollection(_ newCollection: TaskCollection){
		guard !table.keys.contains(where: { $0.title == newCollection.title
		}) else {
			print("Fail to add new collection: \(newCollection.title) is already exist")
			return }
		table[newCollection] = [Task]()
		objectWillChange.send()
	}
	
	func deleteCollection(_ collectionToRemove: TaskCollection) {
		table[collectionToRemove] = nil
		objectWillChange.send()
	}
	
	func changeCollection(from oldCollection: TaskCollection, to newCollection: TaskCollection) {
		guard let tasksToMove = table.removeValue(forKey: oldCollection) else { return }
		table[newCollection] = tasksToMove
		objectWillChange.send()
	}
	
	func createDefaultCollection() {
		guard table.isEmpty else { return }
		table[TaskCollection.listCollectionDummy] = Task.shopingList
		table[TaskCollection.puzzleCollectionDummy] = Task.moviePuzzle
	}
	
	func addNewTask(_ task: Task, in collection: TaskCollection) {
		guard table.keys.contains(collection) else {
			return
		}
		table[collection]?.append(task)
		objectWillChange.send()
	}
	
	func deleteTask(_ task: Task, in collection: TaskCollection) {
		guard table.keys.contains(collection),
					let index = table[collection]!.firstIndex(where: { $0.id == task.id
					}) else { return }
		table[collection]!.remove(at: index)
		objectWillChange.send()
	}
	
	func changeTask(from oldTask: Task, to newTask: Task, in colletion: TaskCollection) {
		guard table.keys.contains(colletion),
					let index = table[colletion]!.firstIndex(where: { $0.id == oldTask.id })
		else {
			print("Fail to find task: \(oldTask), in :\(colletion)")
			return
		}
		table[colletion]![index] = newTask
		objectWillChange.send()
	}
	func removeAllTaskData() -> Bool {
		do {
			table = [:]
			let data = try JSONEncoder().encode(table)
			try store(data: data, filename: taskDataFileName)
			objectWillChange.send()
			return true
		}catch {
			return false
		}
	}
	
	init() {
		self.table = Table()
	}
	
	func isAllComplete(collection: TaskCollection) -> Bool {
		guard table[collection] != nil else {
			return false
		}
		for task in table[collection]! {
			if !task.isCompleted {
				return false
			}
		}
		return true
	}
}

extension TaskModelController: UserDataContainer {
	
	func retrieveUserDataIfNeeded() throws {
		guard !isDataLoaded else {
			return
		}
		isDataLoaded = true
		defer {
			autoTaskSaveCancellable = $table.sink{ [self] changedTable in
				if let data = try? JSONEncoder().encode(changedTable){
					try? store(data: data, filename:  taskDataFileName)
				}
			}
			startDownloadBackup(filename: taskDataFileName)
		}
		
		if checkFileExist(for: taskDataFileName, usingICloud: false) {
			do{
				let fileData = try restore(filename: taskDataFileName, as:  Table.self)
				table = fileData
			}catch {
				isDataLoaded = false
				throw error
			}
		}
		
	}
	
	func storeWidgetData(bookmark: String) {
		WidgetCenter.shared.getCurrentConfigurations { [self] result in
			switch result {
			case .failure(let error):
				assertionFailure("Fail to get current widget configurations f\n" + error.localizedDescription)
			case .success(let widgetInfoArr):
				if widgetInfoArr.contains(where: { $0.kind == taskWidgetKind }),
					 let collection = table.keys.first(where: { $0.title == bookmark
					 }){
					let taskToStore: Table = [collection: table[collection] ?? []]
					let encoder = JSONEncoder()
					do {
						let taskData = try encoder.encode(taskToStore)
						try storeForWidget(data: taskData, fileName: widgetTaskFileName)
						
						WidgetCenter.shared.reloadTimelines(ofKind: taskWidgetKind)
						
					}catch  {
						assertionFailure("Fail to store widget data \n" +  error.localizedDescription)
					}
					
				}
			}
		}
	}
	func backup() throws {
		do {
			try backup(filename: taskDataFileName)
		}catch {
			throw error
		}
	}
	func restoreBackup() throws {
		if checkFileExist(for: taskDataFileName, usingICloud: true) {
			do {
				table = try restoreBackup(filename: taskDataFileName, as: Table.self)
			}catch {
				throw error
			}
		}else {
			throw "아이클라우드 데이터가 존재하지 않습니다"
		}
	}
}


