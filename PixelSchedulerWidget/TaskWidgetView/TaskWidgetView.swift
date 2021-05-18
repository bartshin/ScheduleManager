//
//  TaskWidgetView.swift
//  PixelSchedulerWidgetExtension
//
//  Created by Shin on 4/20/21.
//

import SwiftUI
import WidgetKit

struct TaskWidgetView: View {
    
    private let collection: TaskCollection
    private let tasksNotCompleted: [Task]
    /// (Completed, Total) max coin = 5
    private let progress: (Int, Int)
    private let config: UserConfig
    
    var body: some View {
        GeometryReader { geometryProxy in
            HStack {
                let leftPartSize = CGSize(width: geometryProxy.size.width * 0.3,
                                          height: geometryProxy.size.height)
                ZStack {
                    Image(uiImage: config.character.image)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .position(x: 20,
                                  y: 10)
                    VStack {
                        Text(collection.title)
                            .font(.body)
                            .bold()
                            .lineLimit(1)
                            .foregroundColor(Color(config.palette.primary))
                        switch collection.style {
                        case .list:
                            let progressViewWidth: CGFloat = leftPartSize.width * min(CGFloat(progress.1 + 10), 15) / 15
                            ListProgress(in: CGSize(width: progressViewWidth,
                                                    height: leftPartSize.height * 0.3),
                                         for: progress,
                                         palette: config.palette)
                                .frame(width: progressViewWidth,
                                       height: leftPartSize.height * 0.3)
                            
                        case .puzzle:
                            if progress.1 > 0 {
                                PuzzleProgress(progress: progress, palette: config.palette)
                                    .frame(width: leftPartSize.width,
                                           height: leftPartSize.height * 0.5)
                                    .cornerRadius(20)
                            }else {
                                Image(systemName: "puzzlepiece.fill")
                                    .resizable()
                                    .foregroundColor(Color(config.palette.secondary))
                                    .frame(width: leftPartSize.width * 0.4,
                                           height: leftPartSize.height * 0.2)
                            }
                        }
                    }
                }
                .frame(width: leftPartSize.width * 1.1)
                Divider()
                ZStack {
                    VStack  {
                        if progress.1 - progress.0 > 0 {
                            ForEach(tasksNotCompleted, id: \.self.id) { task in
                                HStack {
                                    Circle()
                                        .size(width: 10, height: 10)
                                        .foregroundColor(Color.byPriority(task.priority))
                                        .frame(width: 10, height: 10)
                                    Text(task.text)
                                        .font(.footnote)
                                        .foregroundColor(Color(config.palette.primary))
                                }
                                .frame(maxWidth: geometryProxy.size.width * 0.7, maxHeight: 20, alignment: .leading)
                                .padding(.leading, 10)
                            }
                        }else if progress.1 > 0 {
                            Image("finish_icon")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Color(config.palette.primary))
                                .frame(width: geometryProxy.size.width * 0.6,
                                       height: geometryProxy.size.height * 0.7)
                                .offset(y: 20)
                        }else {
                            Image("empty_icon")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Color(config.palette.primary))
                                .frame(width: geometryProxy.size.width * 0.7,
                                       height: geometryProxy.size.height * 0.8)
                                .offset(x: -20)
                        }
                        if progress.0 > 0 {
                            Text("\(progress.0)개 완료됨")
                                .font(.caption2)
                                .foregroundColor(Color(config.palette.secondary))
                                .padding(.trailing, 40)
                        }
                    }
                }
                .frame(width: geometryProxy.size.width * 0.7)
            }
            
        }
        .padding([.top, .bottom], 20)
        .padding([.leading, .trailing], 10)
        .background(Color(config.palette.quaternary.withAlphaComponent(0.3)))
        .widgetURL(CustomWidgetURL.create(for: .taskCollection,
                                          at: nil, objectID: collection.id))
    }
    
    init(entry: TaskEntry) {
        self.collection = entry.collection
        self.tasksNotCompleted = entry.tasks.filter({ !$0.completed })
        progress = ((entry.tasks.count - tasksNotCompleted.count) , entry.tasks.count)
        config = UserConfig()
    }
}

struct TaskWidgetView_Previews: PreviewProvider {
    
    static var previews: some View {
        TaskWidgetView(entry: TaskEntry(
                        date: Date(),
                        collection: .listCollection,
                        tasks: Task.shopingList))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
