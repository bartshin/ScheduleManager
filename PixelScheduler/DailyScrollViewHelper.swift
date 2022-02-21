//
//  DailyScrollViewHelper.swift
//  PixelScheduler
//
//  Created by bart Shin on 2/28/21.
//

import SwiftUI

protocol DailyScrollViewProtocol: View {
    var date: Date? { get set }
}

/// Protocol for calculate position, size
extension DailyScrollViewProtocol {
    /// Calculate schedule's Y position
    ///- Returns: Calculated double value represent minute
    func calcOriginY(for scheduleTime: Schedule.DateType)
    -> Double {
        switch scheduleTime {
        case .spot(let date):
            return date.timeToDouble
        case .period(start: let startDate, let endDate):
            if startDate.isSameDay(with: date!) {
                return startDate.timeToDouble
            }else if endDate.isSameDay(with: date!){
                return 0
            }else {
                // Not draw background
                return 0
            }
        case .cycle(let firstStartDate, _, _):
            return firstStartDate.timeToDouble
        }
    }
    func calcHeight(for scheduleTime: Schedule.DateType) -> CGFloat
    {
        // Height for one hour
        let minHeight: CGFloat = 1
        
        switch scheduleTime {
        case .period(start: let startDate, end: let endDate):
            let interval: TimeInterval
            if startDate.isSameDay(with: date!) {
                if endDate.isSameDay(with: date!) {
                    interval = endDate - startDate
                }else {
                    interval = TimeInterval.forOneDay - (startDate - startDate.startOfDay)
                }
            }else if endDate.isSameDay(with: date!){
                interval = endDate - date!.startOfDay
            }else {
                // Not draw all day schedule indivisually draw on top
                return 0
            }
            return max( CGFloat(interval / (60 * 60)), minHeight)
        default:
            return minHeight
        }
    }
}
