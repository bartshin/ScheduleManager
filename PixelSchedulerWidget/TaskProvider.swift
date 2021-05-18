//
//  TaskProvider.swift
//  PixelScheduler
//
//  Created by Shin on 4/20/21.
//

import WidgetKit

struct TaskProvider: TimelineProvider {
    
    let dataGather = DataGather()
    
    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry.reload
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        
        if let table = dataGather.restore(filename: dataGather.taskFileName, as: [TaskCollection: [Task]].self) ,
           let collection = table.keys.first,
           let tasks = table[collection] {
            let entries = [TaskEntry(
                            date: Date(),
                            collection: collection, tasks: tasks)]
            completion(Timeline(entries: entries, policy: .never))
        }
        else {
            completion(Timeline(entries: [TaskEntry.reload], policy: .never))
        }
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        
        let entry = [
            TaskEntry(date: Date(), collection: TaskCollection.listCollection,  tasks: Task.shopingList),
            TaskEntry(date: Date(), collection: TaskCollection.puzzleCollection,  tasks: Task.moviePuzzle)
        ].randomElement()!
        completion(entry)
    }
}


struct TaskEntry: TimelineEntry {
    var date: Date
    var collection: TaskCollection
    var tasks: [Task]
    
    static var reload: TaskEntry {
        let collection = TaskCollection(style: .list, title: "데이터를 불러올수 없습니다")
        let task = Task(text: "Pixel Scheduler를 실행해 주세요", priority: 1)
        return TaskEntry(date: Date(), collection: collection, tasks: [task])
    }
    
}

