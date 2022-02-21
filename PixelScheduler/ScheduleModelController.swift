
import Foundation
import Combine
import WidgetKit

class ScheduleModelController: ObservableObject {
	
	/**
	Data intergrity
	- Warning: Do not modify directly
	*/
	@Published private(set) var schedules: Set<Schedule>
	/**
	Data intergrity
	- Warning: Do not modify directly
	*/
	@Published private(set) var stickerTable: [Int: Sticker]
	
	#if DEBUG
	static var dummyController: ScheduleModelController {
		let controller = ScheduleModelController()
		_ = controller.addNewSchedule(.dummy, alarmCharacter: .soldier)
		return controller
	}
	#endif
	
	typealias Table = [Int: [Schedule]]
	typealias HolidayTable = [Int: HolidayGather.Holiday]
	private(set) var scheduleTable: Table
	private(set) var cycleTable: CycleTable
	private(set) var holidayTable: HolidayTable
	
	lazy var notificationContoller = NotificationController()
	
	// MARK:- Save & Load
	
	private let scheduleDataFileName = "user_schedule_data"
	private let stickerDataFileName = "user_sticker_data"
	private let widgetScheduleFileName = "widget_schedule_data"
	private let widgetStickerFileName = "widget_sticker_data"
	private let widgetHolidayFileName = "widget_holiday_data"
	private let scheduleWidgetKind = "ScheduleWidget"
	private var autoScheduleSaveCancellable: AnyCancellable?
	private var autoStickerSaveCancellable: AnyCancellable?
	
	func getSchedules(for dateInt: Int) -> [Schedule] {
		var schedulesForDay = [Schedule]()
		if let atDate = scheduleTable[dateInt]{
			schedulesForDay += atDate
		}
		let date = dateInt.toDate!
		if let weekdayCycle = cycleTable.weekday[date.weekDay] {
			schedulesForDay += weekdayCycle.filter() {
				switch $0.time {
				case .cycle(since: let startDate, _, _):
					return date > startDate
				default :
					return false
				}
			}
		}
		if let dayCycle = cycleTable.day[date.day] {
			schedulesForDay += dayCycle.filter(){
				switch $0.time {
				case .cycle(since: let startDate, _, _):
					return date > startDate
				default :
					return false
				}
			}
		}
		return schedulesForDay
	}
	
	func getSchedule(by id: UUID) -> Schedule? {
		return schedules.first{ $0.id == id}
	}
	
	func querySchedulesTitle(by queryString: String) -> [Schedule] {
		let trimmedString = queryString.lowercased().replacingOccurrences(of: " ", with: "")
		return schedules.filter {
			let trimmedTitle = $0.title.lowercased().replacingOccurrences(of: " ", with: "")
			return trimmedTitle.contains(trimmedString) || trimmedString.contains(trimmedTitle)
		}
	}
	
	func queryHoliday(by queryString: String, for language: SettingKey.Language) -> [HolidayGather.Holiday] {
		let trimmedString = queryString.lowercased().replacingOccurrences(of: " ", with: "")
		switch language {
		case .english:
			let holidayTitles = HolidayDictionay.englishHolidaysWithOutSpace.filter {
				$0.contains(trimmedString) || trimmedString.contains($0)
			}
			return holidayTable.filter {
				holidayTitles.contains($0.value.title.replacingOccurrences(of: " ", with: "").lowercased())
			}.map {
				$0.value
			}
		case .korean:
			let holidayTitles = HolidayDictionay.koreanHolidaysWithOutSpace.filter {
				$0.contains(trimmedString) || trimmedString.contains($0)
			}
			return holidayTable.filter {
				if let korean = HolidayDictionay.engToKor(from: $0.value.title) {
					return holidayTitles.contains(korean.replacingOccurrences(of: " ", with: ""))
				}else {
					return false
				}
			}.map {
				$0.value
			}
		}
	}
	
	/// Add new schedule
	/// - Note: Check permission in notification controller before add alarm
	/// - Returns: Return false when try to add  alarm without permission
	func addNewSchedule(_ newSchedule: Schedule, alarmCharacter: SettingKey.Character) -> Bool{
		#if !DEBUG
		if newSchedule.alarm != nil {
			if notificationContoller.authorizationStatus == .authorized {
				notificationContoller.setAlarm(of: newSchedule, character: alarmCharacter)
			}else {
				return false
			}
		}
		#endif
		schedules.insert(newSchedule)
		enrollToTable(newSchedule)
		objectWillChange.send()
		return true
	}
	func deleteSchedule(_ scheduleToDelete: Schedule) {
		guard schedules.contains(scheduleToDelete) else {
			assertionFailure("Delete fail schedule not exist:\n \(scheduleToDelete)")
			return
		}
		delistInTable(scheduleToDelete)
		schedules.remove(scheduleToDelete)
		if scheduleToDelete.alarm != nil {
			notificationContoller.removeAlarm(of: scheduleToDelete)
		}
		objectWillChange.send()
	}
	func replaceSchedule(_ oldSchedule: Schedule, to newSchedule: Schedule,
											 alarmCharacter: SettingKey.Character) -> Bool {
		guard oldSchedule.id == newSchedule.id ,
					schedules.contains(oldSchedule) else {
			assertionFailure("schedule replace failed by data missing")
			return false
		}
		if oldSchedule.alarm != nil, oldSchedule.isAlarmOn {
			notificationContoller.removeAlarm(of: oldSchedule)
		}
		if newSchedule.alarm != nil, newSchedule.isAlarmOn {
			if notificationContoller.authorizationStatus == .authorized {
				notificationContoller.setAlarm(of: newSchedule, character: alarmCharacter)
			}else {
				return false
			}
		}
		delistInTable(oldSchedule)
		enrollToTable(newSchedule)
		
		schedules.remove(oldSchedule)
		schedules.insert(newSchedule)
		objectWillChange.send()
		return true
	}
	
	private func enrollToTable(_ schedule: Schedule) {
		switch schedule.time {
		case .spot(let date):
			let key = date.toInt
			scheduleTable.append(schedule, to: key)
		case .period(start: let startDate, end: let endDate):
			let startKey = startDate.toInt
			let endKey = endDate.toInt
			let range = startKey...endKey
			for key in range {
				scheduleTable.append(schedule, to: key)
			}
		case .cycle(_, for: let factor, every: let values):
			switch factor {
			case .day:
				for day in values {
					cycleTable.day.append(schedule, to: day)
				}
			case .weekday:
				for weekday in values {
					cycleTable.weekday.append(schedule, to: weekday)
				}
			}
		}
	}
	private func delistInTable(_ scheduleToDelete: Schedule) {
		switch scheduleToDelete.time {
		case .cycle(_, for: let factor, _):
			switch factor {
			case .day:
				cycleTable.day.delete(scheduleToDelete)
			case .weekday:
				cycleTable.weekday.delete(scheduleToDelete)
			}
		default:
			scheduleTable.delete(scheduleToDelete)
		}
	}
	
	func importSchedules(_ schedulesToImport:[Schedule],
											 alarmCharacter: SettingKey.Character) -> Bool {
		var isEveryScheduleAdded = true
		schedulesToImport.forEach { scheduleToImport in
			if let duplicatedSchedule = schedules.first(
					where: { $0.origin == scheduleToImport.origin })
			{
				deleteSchedule(duplicatedSchedule)
			}
		}
		
		schedulesToImport.forEach { scheduleToImport in
			if !addNewSchedule(scheduleToImport, alarmCharacter: alarmCharacter) {
				isEveryScheduleAdded = false
				print("Attemp to import schedule without notification authoriazation \n \(scheduleToImport)")
			}
		}
		return isEveryScheduleAdded
	}
	
	/// Remove all schedule, saved date will be deleted
	func removeAllSchedule() -> Bool{
		schedules.removeAll()
		scheduleTable.removeAll()
		cycleTable.day.removeAll()
		cycleTable.weekday.removeAll()
		let encoder = JSONEncoder()
		do {
			let data = try encoder.encode(schedules)
			try store(data: data, filename: scheduleDataFileName)
			return true
		}catch {
			return false
		}
	}
	
	func moveSticker(_ sticker: Sticker, from sourceDateInt: Int, to destinationDateInt: Int) {
		stickerTable[sourceDateInt] = nil
		stickerTable[destinationDateInt] = sticker
		objectWillChange.send()
	}
	
	func setSticker(_ sticker: Sticker?, to dateInt: Int) {
		stickerTable[dateInt] = sticker
		objectWillChange.send()
	}
	
	struct CycleTable {
		fileprivate(set) var weekday: Table
		fileprivate(set) var day: Table
	}
	
	init() {
		schedules = []
		scheduleTable = Table()
		cycleTable = CycleTable(weekday: Table(), day: Table())
		holidayTable = [Int: HolidayGather.Holiday]()
		stickerTable = [Int: Sticker]()
	}
}

extension ScheduleModelController: UserDataContainer {
	
	func retrieveUserData() throws {
		
		defer {
			autoScheduleSaveCancellable = $schedules.sink(receiveValue: { [self] changedSchedules in
				
				if let data = try? JSONEncoder().encode(changedSchedules){
					try? store(data: data, filename:  scheduleDataFileName)
				}else {
					print("save failed")
				}
			})
			autoStickerSaveCancellable = $stickerTable.sink(receiveValue: { [self] changedStickers in
				
				if let data = try? JSONEncoder().encode(changedStickers){
					try? store(data: data, filename:  stickerDataFileName)
				}else {
					print("save failed")
				}
			})
			startDownloadBackup(filename: scheduleDataFileName)
			startDownloadBackup(filename: stickerDataFileName)
		}
		
		
		if checkFileExist(for: scheduleDataFileName, usingICloud: false) {
			do {
				let fileData = try restore(filename: scheduleDataFileName, as:  Set<Schedule>.self)
				schedules = fileData
				schedules.forEach() { enrollToTable($0) }
				
			}catch {
				throw error
			}
		}
		
		if checkFileExist(for: stickerDataFileName, usingICloud: false) {
			do {
				let fileData = try restore(filename: stickerDataFileName, as: [Int: Sticker].self)
				stickerTable = fileData
			}catch {
				throw error
			}
		}
	}
	
	func storeWidgetData() {
		WidgetCenter.shared.getCurrentConfigurations { [self] result in
			switch result {
			case .failure(let error):
				assertionFailure("Fail to get current widget configurations f\n" + error.localizedDescription)
			case .success(let widgetInfoArr):
				if widgetInfoArr.contains(where: { $0.kind == scheduleWidgetKind }) {
					var schedulesToStore = [Int:[Schedule]]()
					var holidaysToStore = [Int: HolidayGather.Holiday]()
					var stickersToStore = [Int: Sticker]()
					let today = Date().startOfDay
					let twoWeekLater = Calendar.current.date(byAdding: .day, value: 14, to: today)!
					for day in stride(from: today, to: twoWeekLater, by: TimeInterval.forOneDay) {
						let dateInt = day.toInt
						schedulesToStore[dateInt] = getSchedules(for: dateInt)
						holidaysToStore[dateInt] = holidayTable[dateInt]
						stickersToStore[dateInt] = stickerTable[dateInt]
					}
					let encoder = JSONEncoder()
					do {
						let scheduleData = try encoder.encode(schedulesToStore)
						try storeForWidget(data: scheduleData, fileName: widgetScheduleFileName)
						let holidayData = try encoder.encode(holidaysToStore)
						try storeForWidget(data: holidayData, fileName: widgetHolidayFileName)
						let stickerData = try encoder.encode(stickersToStore)
						try storeForWidget(data: stickerData, fileName: widgetStickerFileName)
						WidgetCenter.shared.reloadTimelines(ofKind: scheduleWidgetKind)
					}catch  {
						assertionFailure("Fail to store widget data \n" +  error.localizedDescription)
					}
					
				}
			}
		}
	}
	
	func checkHolidayData(for year: Int, about country: HolidayGather.CountryCode) throws {
		let fileName = "holiday_data" + "_\(country.rawValue)" + "(\(year))"
		
		if checkFileExist(for: fileName, usingICloud: false)  {
			let savedData: HolidayGather.Response
			do {
				savedData = try restore(filename: fileName,
																as: HolidayGather.Response.self)
			}
			catch {
				throw error
			}
			if  savedData.meta["code"] != 200 {
				print("Holiday data from server is not valid")
				return
			}
			let holidayData = savedData.response.holidays
			holidayData.forEach() {
				let holiday = HolidayGather.Holiday(from: $0)
				holidayTable[holiday.dateInt] = holiday
			}
		}else {
			let holidayGather = HolidayGather()
			holidayGather.retrieveHolidays(
				about: year, of: country){ [weak weakSelf = self] data in
				try? weakSelf?.store(data: data, filename: fileName)
				try? weakSelf?.checkHolidayData(for: year,
																				about: country)
			}
		}
	}
	func backup() throws {
		do {
			try backup(filename: scheduleDataFileName)
			try backup(filename: stickerDataFileName)
		}catch {
			throw error
		}
	}
	
	func restoreBackup() throws {
		if checkFileExist(for: scheduleDataFileName, usingICloud: true) || checkFileExist(for: stickerDataFileName, usingICloud: true) {
			do {
				schedules = try restoreBackup(filename: scheduleDataFileName, as: Set<Schedule>.self)
				schedules.forEach { enrollToTable($0) }
				stickerTable = try restoreBackup(filename: stickerDataFileName, as: [Int: Sticker].self)
			}catch {
				throw error
			}
		}else {
			throw "아이클라우드 데이터가 존재하지 않습니다"
		}
	}
}

// MARK: - Schedule table
extension Dictionary where Key == Int, Value == [Schedule] {
	mutating func append(_ value: Schedule, to key: Int) {
		if self[key] == nil{
			self[key] = [Schedule]()
			self[key]?.append(value)
		}else {
			self[key]?.append(value)
		}
	}
	mutating func delete(_ scheduleToDelete: Schedule) {
		switch scheduleToDelete.time {
		case .spot(let date):
			let key = date.toInt
			guard let indexInTable = self[key]?.firstIndex(of: scheduleToDelete) else {
				assertionFailure("Delete fail schedule is not in table \n \(scheduleToDelete)")
				return
			}
			self[key]?.remove(at: indexInTable)
		case .period(start: let startDate, end: let endDate):
			let startKey = startDate.toInt
			let endKey = endDate.toInt
			let range = startKey...endKey
			for key in range {
				guard let indexInTable = self[key]?.firstIndex(of: scheduleToDelete) else {
					assertionFailure("Delete fail schedule is not in table \n \(scheduleToDelete)")
					return
				}
				self[key]?.remove(at: indexInTable)
			}
		case .cycle(_, _, every: let values):
			for key in values {
				guard let indexInTable = self[key]?.firstIndex(of: scheduleToDelete) else {
					assertionFailure("Delete fail schedule is not in table \n \(scheduleToDelete)")
					return
				}
				self[key]?.remove(at: indexInTable)
			}
		}
	}
}
