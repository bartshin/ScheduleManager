//
//  ScheduleProvider.swift
//  PixelScheduler
//
//  Created by Shin on 4/15/21.
//

import WidgetKit

struct ScheduleProvider: TimelineProvider {
    
    let dataGather = DataGather()
    
    func placeholder(in context: Context) -> ScheduleEntry {
        ScheduleEntry(
            date: Date(),
            holidayTable: [Int : HolidayGather.Holiday](),
            stickerTable: [Date().toInt: ScheduleEntry.Dummy.sticker],
            scheduleTable: [Date().toInt: [ScheduleEntry.Dummy.reload]])
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ScheduleEntry>) -> Void) {
        
        if var schedules = dataGather.restore(
            filename: dataGather.scheduleFileName,
            as: [Int: [Schedule]].self),
           var holidayTable = dataGather.restore(
						filename: dataGather.holidayFileName,
               as: [Int: HolidayGather.Holiday].self),
           var stickerTable = dataGather.restore(filename: dataGather.stickerFileName, as: [Int: Sticker].self){
            
            var entries = [ScheduleEntry]()
            let startOfToday = Date().startOfDay
            
            let aWeekLater = Calendar.current.date(byAdding: .day, value: 7, to: startOfToday)!
            
            for day in stride(from: startOfToday, to: aWeekLater, by: TimeInterval.forOneDay) {
                let entryForDay = ScheduleEntry(
                    date: day,
                    holidayTable:  contractTable(start: day, tablePtr: &holidayTable),
                    stickerTable: contractTable(start: day, tablePtr: &stickerTable),
                    scheduleTable: contractTable(start: day, tablePtr: &schedules))
            
                entries.append(entryForDay)
                if schedules.keys.contains(day.toInt) {
                    schedules[day.toInt]!.forEach { schedule in
                        let oneHourEarly: Date
                        let dateExpired: Date
                        switch schedule.time {
                        case .spot(let date):
                            oneHourEarly = Calendar.current.date(byAdding: .hour, value: -1, to: date)!
                            dateExpired = Calendar.current.date(byAdding: .minute, value: 1, to: date)!
                        case .period(start: let startDate, let endDate):
                            oneHourEarly = Calendar.current.date(byAdding: .hour, value: -1, to: startDate)!
                            dateExpired = endDate
                        case .cycle(since: let baseDate, _, _):
                            let now = Date()
                            var baseComponents =  Calendar.current.dateComponents([.calendar, .hour, .minute], from: baseDate)
                            baseComponents.year = now.year
                            baseComponents.month = now.month
                            baseComponents.day = now.day
                            dateExpired = Calendar.current.date(byAdding: .minute, value: 1, to: baseComponents.date!)!
                            baseComponents.hour! -= 1
                            oneHourEarly = baseComponents.date!
                            
                        }
                        let entryBeforehand = ScheduleEntry(
                            date: oneHourEarly,
                            holidayTable: entryForDay.holidayTable, stickerTable: entryForDay.stickerTable,
                            scheduleTable: entryForDay.scheduleTable)
                        entries.append(entryBeforehand)
                        let entryExpired =  ScheduleEntry(
                            date: dateExpired,
                            holidayTable: entryForDay.holidayTable, stickerTable: entryForDay.stickerTable,
                            scheduleTable: entryForDay.scheduleTable)
                        entries.append(entryExpired)
                    }
                }
            }
            let timeline = Timeline(
                entries: entries,
                policy: .atEnd)
            completion(timeline)
        }else {
            let entries = [ ScheduleEntry(
                date: Date(),
                holidayTable: [Int : HolidayGather.Holiday](),
                stickerTable: [Date().toInt: ScheduleEntry.Dummy.sticker],
                scheduleTable: [
                    Date().toInt : [ScheduleEntry.Dummy.reload]
                ]
            )]
            let reloadTimeline = Timeline(entries: entries, policy: .never)
            completion(reloadTimeline)
        }
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ScheduleEntry) -> Void) {
        let baseDate = Date()
        let nextDate = Calendar.current.date(byAdding: .day, value: 1, to: baseDate)!
        completion(ScheduleEntry(date: Date(),
                                 holidayTable: [Int : HolidayGather.Holiday](),
                                 stickerTable: [Date().toInt: ScheduleEntry.Dummy.sticker],
                                 scheduleTable: [
                                    baseDate.toInt: ScheduleEntry.Dummy.firstSchedules,
                                    nextDate.toInt: ScheduleEntry.Dummy.secondSchedules
                                 ]
        ))
    }
    
    private func contractTable<ValueT>(start startDate: Date, tablePtr: inout [Int: ValueT]) -> [Int: ValueT] {
        var oneWeekTable = [Int: ValueT]()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        for day in stride(from: startDate, to: endDate, by: TimeInterval.forOneDay) {
            oneWeekTable[day.toInt] = tablePtr[day.toInt]
        }
        return oneWeekTable
    }
}

struct ScheduleEntry: TimelineEntry {
    var date: Date
    
    /// Holidays for a week
    var holidayTable: [Int: HolidayGather.Holiday]
    /// Schedule for displaying date
    var schedules: [Schedule] {
        scheduleTable[date.toInt] ?? []
    }
    /// Stickers for a week
    var stickerTable: [Int: Sticker]
    /// Schedule for a week
    var scheduleTable: [Int: [Schedule]]
    
    
    /// Dummy data for previews on widget picker
    struct Dummy {
        
        static var sticker: Sticker {
            Sticker(collection: Sticker.Collection.allCases.randomElement()!, number: Int.random(in: 1...10))
        }
        
        static let dateComponents = Calendar.current.dateComponents([.calendar, .year, .month, .day], from: Date())
        
        static var firstSchedules: [Schedule] {
            
            var morningComponents = dateComponents
            morningComponents.hour = 7
            morningComponents.minute = 30
            let morningDate = morningComponents.date!
            var noonComponents = dateComponents
            noonComponents.hour = 14
            noonComponents.minute = 45
            let noonDate = noonComponents.date!
            var nightComponents = dateComponents
            nightComponents.hour = 21
            nightComponents.minute = 0
            let nightDate = nightComponents.date!
            return [
                Schedule(
                    title: "알람",
                    description: "스케줄 설명란 입니다 ",
                    priority: 1,
                    time: .spot(morningDate)
                    , alarm: .once(Calendar.current.date(byAdding: .minute, value: -10, to: morningDate)!)),
                Schedule(
                    title: "회의",
                    description: "스케줄 설명란 입니다 \n 스케줄 설명란 입니다",
                    priority: 3,
                    time: .period(
                        start: noonDate,
                        end: Calendar.current.date(byAdding: .hour, value: 2, to: noonDate)!)
                    , alarm: nil,
                    contact: Schedule.Contact(
                        name: "이름",
                        phoneNumber: "000 - 0000 - 0000",
                        contactID: "contact ID")),
                Schedule(
                    title: "저녁 약속",
                    description: "",
                    priority: 5,
                    time: .spot(nightDate),
                    alarm: nil,
                    location:
                        Schedule.Location(
                        title: "장소 이름",
                            address: "주소",
                            coordinates: Schedule.Location.dummyCoordinates),
                    contact: Schedule.Contact(
                    name: "이름",
                    phoneNumber: "000 - 0000 - 0000",
                    contactID: "contact ID"))
            ]
        }
        
        static var secondSchedules: [Schedule] {
            
            var morningComponents = dateComponents
            morningComponents.hour = 10
            morningComponents.minute = 0
            let morningDate = morningComponents.date!
            var noonComponents = dateComponents
            noonComponents.hour = 13
            noonComponents.minute = 00
            let noonDate = noonComponents.date!
            
            return [
                Schedule(
                    title: "운동",
                    description: "스케줄 설명란 입니다 ",
                    priority: 1,
                    time: .spot(morningDate)
                    , alarm: .once(Calendar.current.date(byAdding: .minute, value: -10, to: morningDate)!)),
                Schedule(
                    title: "점심 약속",
                    description: "스케줄 설명란 입니다",
                    priority: 3,
                    time: .period(
                        start: noonDate,
                        end: Calendar.current.date(byAdding: .hour, value: 2, to: noonDate)!)
                    , alarm: nil,
                    location:
                        Schedule.Location(
                        title: "장소 이름",
                            address: "주소",
                            coordinates: Schedule.Location.dummyCoordinates),
                    contact: Schedule.Contact(
                        name: "이름",
                        phoneNumber: "000 - 0000 - 0000",
                        contactID: "contact ID"))
            ]
        }
        static let reload = Schedule(
            title: "일정 정보 없음",
            description: "Pixel Scheduler를 실행해 주세요",
            priority: 1,
            time: .spot(Date()),
            alarm: nil)
    }



}

