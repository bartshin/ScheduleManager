//
//  ScheduleDataGather.swift
//  PixelScheduler
//
//  Created by Shin on 4/16/21.
//

import Foundation

class DataGather {
    
    let scheduleFileName = "widget_schedule_data"
    let holidayFileName = "widget_holiday_data"
    let taskFileName = "widget_task_data"
    let stickerFileName = "widget_sticker_data"
    
    private func getSharedPath(for fileName: String) -> URL? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.bartshin.com.github.pxscheduler") else {
            return nil
        }
        return containerURL.appendingPathComponent(fileName).appendingPathExtension("json")
    }
    
    
    func restore<T: Codable>(filename: String, as returnType: T.Type) -> T? {
        let data: Data
        guard let fileURL = getSharedPath(for: filename) else {
            assertionFailure("Couln't find \(filename) for widget ")
            return nil
        }
        do {
            data = try Data(contentsOf: fileURL)
        }catch {
            assertionFailure("Couln't load \(filename) from \(fileURL.path): \n \(error.localizedDescription)")
            return nil
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            assertionFailure("Couln't parse \(filename): \n\(error)")
            return nil
        }
    }
    
    struct Holiday: Codable {
        let dateInt: Int
        let title: String
        let description: String
        let type: HolidayType
        
        enum HolidayType: String, Codable {
            case national = "National holiday"
            case observance = "Observance"
            case season = "Season"
            case commonLocal = "Common local holiday"
        }
    }
}
