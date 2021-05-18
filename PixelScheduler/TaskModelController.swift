//
//  TaskModelController.swift
//  ScheduleManager
//
//  Created by Shin on 3/24/21.
//

import Foundation
import Combine
import WidgetKit

class TaskModelController: ObservableObject {
    
    typealias Table = [TaskCollection: [Task]]
    private let taskDataFileName = "user_task_data"
    private let taskWidgetKink = "TaskWidget"
    private let widgetTaskFileName = "widget_task_data"
    @Published private(set) var table: Table
    var autoTaskSaveCancellable: AnyCancellable?
    
    func addNewCollection(_ newCollection: TaskCollection){
        guard !table.keys.contains(where: { $0.title == newCollection.title
        }) else {
            print("Fail to add new collection: \(newCollection.title) is already exist")
            return }
        table[newCollection] = [Task]()
    }
    
    func deleteCollection(_ collectionToRemove: TaskCollection) {
        table[collectionToRemove] = nil
    }
    
    func changeCollection(from oldCollection: TaskCollection, to newCollection: TaskCollection) {
        guard let tasksToMove = table.removeValue(forKey: oldCollection) else { return }
        table[newCollection] = tasksToMove
    }
    
    func createDefaultCollection() {
        guard table.isEmpty else { return }
        table[TaskCollection.listCollection] = Task.shopingList
        table[TaskCollection.puzzleCollection] = Task.moviePuzzle
    }
    
    func addNewTask(_ task: Task, in collection: TaskCollection) {
        guard table.keys.contains(collection) else {
            return
        }
        table[collection]?.append(task)
    }
    
    func deleteTask(_ task: Task, in collection: TaskCollection) {
        guard table.keys.contains(collection),
              let index = table[collection]!.firstIndex(where: { $0.id == task.id
              }) else { return }
        table[collection]!.remove(at: index)
    }
    
    func changeTask(from oldTask: Task, to newTask: Task, in colletion: TaskCollection) {
        guard table.keys.contains(colletion),
              let index = table[colletion]!.firstIndex(where: { $0.id == oldTask.id })
        else {
            assertionFailure("Fail to find task: \(oldTask), in :\(colletion)")
            return
        }
        table[colletion]![index] = newTask
    }
    func removeAllTaskData() -> Bool {
        do {
            table = [:]
            let data = try JSONEncoder().encode(table)
            try store(data: data, filename: taskDataFileName)
            return true
        }catch {
            return false
        }
    }
    
    init() {
        self.table = Table()
    }
    
}

extension TaskModelController: UserDataContainer {
    
    func retrieveUserData() throws {
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
                if widgetInfoArr.contains(where: { $0.kind == taskWidgetKink }),
                   let collection = table.keys.first(where: { $0.title == bookmark
                   }){
                    let taskToStore: Table = [collection: table[collection] ?? []]
                    let encoder = JSONEncoder()
                    do {
                        let taskData = try encoder.encode(taskToStore)
                        try storeForWidget(data: taskData, fileName: widgetTaskFileName)
                     
                        WidgetCenter.shared.reloadTimelines(ofKind: taskWidgetKink)
                        
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


