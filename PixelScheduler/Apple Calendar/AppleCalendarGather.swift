//
//  AppleCalendarGather.swift
//  FancyScheduler
//
//  Created by Shin on 4/7/21.
//

import Foundation
import EventKit

class AppleCalendarGather {
    private var store: EKEventStore
    @Published private(set) var events: [EKEvent]
    @Published private(set) var allCalendars: [EKCalendar]
    
    init() {
        self.store = EKEventStore()
        self.events = []
        self.allCalendars = []
    }
    
    func requestPermission(permittedHandler: @escaping () -> Void, deniedHandler: @escaping () -> Void) {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            permittedHandler()
        case .notDetermined:
            store.requestAccess(to: .event) {  granted, error in
                if granted {
                    permittedHandler()
                }
            }
        default:
            deniedHandler()
        }
    }
    
    func getCalendars(){
        allCalendars = store.calendars(for: .event)
    }
    
    func getEvents(baseOn midDate: Date, for calendar: EKCalendar? = nil) {
        guard let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: midDate),
              let twoYearsAfter = Calendar.current.date(byAdding: .year, value: 2, to: midDate) else { return }
        
        let predicate = store.predicateForEvents(withStart: twoYearsAgo, end: twoYearsAfter, calendars: calendar == nil ? nil: [calendar!])
        
        events = store.events(matching: predicate)
    }
}
