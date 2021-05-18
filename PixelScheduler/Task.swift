//
//  Task.swift
//  ScheduleManager
//
//  Created by Shin on 3/25/21.
//

import Foundation

struct Task: Codable {
    var text: String
    var completed = false
    var priority: Int
    let id: UUID
    
    init(text: String, priority: Int, id: UUID? = nil) {
        self.text = text
        self.priority = priority
        if id != nil {
            self.id = id!
        }else {
            self.id = UUID()
        }
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
        
        
        shopingList[1].completed = true
        shopingList[3].completed = true
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
            moviePuzzle[index].completed = true
        }
        return moviePuzzle
    }
    
}
