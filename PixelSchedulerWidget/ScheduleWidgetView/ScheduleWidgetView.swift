//
//  SmallWidgetView.swift
//  PixelScheduler
//
//  Created by Shin on 4/15/21.
//

import SwiftUI
import WidgetKit

struct ScheduleWidgetView: View {
    
    @Environment(\.widgetFamily) var family: WidgetFamily
    @State private var firstIndexShowing = 0
    
    private let date: Date
    private let config: UserConfig
    private let holidayTable: [Int: DataGather.Holiday]
    private var holiday: DataGather.Holiday? {
        holidayTable[date.toInt]
    }
    private let stickerTable: [Int: Sticker]
    private var sticker: Sticker? {
        stickerTable[date.toInt]
    }
    private var numCompleted: Int
    private var scheduleTable: [Int: [Schedule]]
    private var scheduleUpComming: Schedule?
    private var schedulesForDay: [Schedule]
    private var dateIntInWeek: [Int]
    
    var body: some View {
        Group{
            if family == .systemMedium {
                GeometryReader {geometryProxy in
                    HStack{
                        ZStack {
                            if sticker != nil {
                                Image(uiImage: sticker!.image)
                                    .resizable()
                                    .opacity(0.6)
                            }
                            Link(destination: CustomWidgetURL.create(for: .date, at: date, objectID: nil), label: {
                                DateSquare(date: date,
                                           holiday: holiday,
                                           config: config,
                                           scheduleCount: schedulesForDay.count)
                            })
                        }
                        .frame(width: geometryProxy.size.width * 0.2,
                               height: geometryProxy.size.height * 0.3,
                               alignment: .leading)
                        Divider()
                        if schedulesForDay.isEmpty, scheduleUpComming == nil {
                            Dayoff(config: config, in: geometryProxy.size)
                                .padding(.leading, 30)
                                .frame(width: geometryProxy.size.width * 0.5)
                        }else {
                            VStack {
                                if let nextSchedule = scheduleUpComming {
                                    Link(destination: CustomWidgetURL.create(
                                            for: .schedule,
                                            at: date,
                                            objectID: nextSchedule.id)) {
                                        UpCommingSchedule(
                                            schedule: nextSchedule,
                                            palette: config.palette,
                                            at: date)
                                        .padding(.bottom, 40)
                                    }
                                }
                                ForEach(schedulesForDay) { schedule in
                                    Link(destination: CustomWidgetURL.create(for: .schedule, at: date, objectID: schedule.id), label: {
                                        ScheduleRow(
                                            for: schedule,
                                            at: date,
                                            palette: config.palette)
                                    })
                                }
                            }
                        }
                        
                    }
                    .padding(20)
                    .frame(width: geometryProxy.size.width,
                           height: geometryProxy.size.height)
                }
            }else if family == .systemLarge {
                GeometryReader { geometryProxy in
                    Image(uiImage: config.character.image)
                        .resizable()
                        .frame(width: 100,
                               height: 100)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        .position(x: geometryProxy.size.width * 0.9,
                                  y: geometryProxy.size.height * 0.1)
                    if dateIntInWeek.filter({
                        scheduleTable.keys.contains($0) && !scheduleTable[$0]!.isEmpty
                    }).isEmpty {
                        Dayoff(config: config,
                               in: geometryProxy.size)
                        .frame(width: geometryProxy.size.width,
                               height: geometryProxy.size.height)
                        .position(x: geometryProxy.size.width * 0.5, y: geometryProxy.size.height * 0.5)
                    }else {
                        VStack {
                            ForEach(dateIntInWeek, id: \.self) { dateInt in
                                if let schedules = scheduleTable[dateInt], !schedules.isEmpty {
                                    
                                    ScheduleOfDayInWeek(
                                        for: schedules,
                                        at: dateInt.toDate!,
                                        holiday: holidayTable[dateInt],
                                        palette: config.palette)
                                        .frame(width: geometryProxy.size.width,
                                               alignment: .leading)
                                    Divider()
                                }
                            }
                        }
                        .padding(10)
                    }
                }
            }
        }
        .background(Color(config.palette.quaternary.withAlphaComponent(0.3)))
    }
    
    init(for entry: ScheduleEntry) {
        date = entry.date
        stickerTable = entry.stickerTable
        holidayTable = entry.holidayTable
        config = UserConfig()
        var scheduleNotcompleted = [Schedule]()
        var scheduleCompleted = [Schedule]()
        entry.schedules.forEach {
            if $0.isDone(for: entry.date.toInt) {
                scheduleCompleted.append($0)
            }else {
                scheduleNotcompleted.append($0)
            }
        }
       
        numCompleted = scheduleCompleted.count
        var nextSchedule: Schedule? = nil
        scheduleNotcompleted.forEach { schedule in
            let startOfSchedule: Date
            let now = Date()
            switch schedule.time {
            case .spot(let date):
                startOfSchedule = date
            case .period(start: let startDate, _):
                startOfSchedule = startDate
            case .cycle(since: let baseDate, _, _):
                var baseComponents =  Calendar.current.dateComponents([.calendar, .hour, .minute], from: baseDate)
                baseComponents.year = now.year
                baseComponents.month = now.month
                baseComponents.day = now.day
                startOfSchedule = baseComponents.date!
            }
            
            if startOfSchedule > now ,
               startOfSchedule - now < TimeInterval(60 * 60) {
                if nextSchedule == nil {
                    nextSchedule = schedule
                }else if nextSchedule! < schedule {
                    nextSchedule = schedule
                }
            }
        }
        if nextSchedule != nil,
           let duplicatedIndex = scheduleNotcompleted.firstIndex(of: nextSchedule!){
            scheduleNotcompleted.remove(at: duplicatedIndex)
        }
        scheduleUpComming = nextSchedule
        // sort schedule
        schedulesForDay = scheduleNotcompleted.sorted(by: { lhs, rhs in
            lhs < rhs
        }) + scheduleCompleted.sorted(by: { lhs, rhs in
            lhs > rhs
        })
        scheduleTable = entry.scheduleTable
        dateIntInWeek = [Int]()
        for day in stride(from: date, to: Calendar.current.date(byAdding: .day, value: 7, to: date)!, by: TimeInterval.forOneDay) {
            dateIntInWeek.append(day.toInt)
        }
    }
}

struct ScheduleWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        ScheduleWidgetView(for:
                            ScheduleEntry(
                                date: Date(),
                                holidayTable: [Int : DataGather.Holiday](), stickerTable: [Date().toInt: ScheduleEntry.Dummy.sticker],
                                scheduleTable:
                                    [
                                        Date().toInt: ScheduleEntry.Dummy.firstSchedules,
                                        Calendar.current.date(byAdding: .day, value: 2, to: Date())!.toInt: ScheduleEntry.Dummy.firstSchedules
                                    ])
        ).previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

