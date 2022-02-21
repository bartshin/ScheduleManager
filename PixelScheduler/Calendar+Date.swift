
import Foundation

extension Calendar {
	static func getDaysInMonth(_ yearAndMonth: Int) -> Int {
		let firstDate = firstDateOfMonth(yearAndMonth)
		let range = Calendar.current.range(
			of: .day,
			in: .month,
			for: firstDate)
		return range!.count 
	}
	static func firstDateOfMonth(_ yearAndMonth: Int) -> Date {
		return DateComponents(
			calendar: Calendar.current,
			timeZone: .current,
			year: yearAndMonth / 100,
			month: yearAndMonth % 100).date!
	}
	
	static var koreanWeekDays: [String] {
		["일", "월", "화", "수", "목", "금", "토"]
	}
	static var englishWeekDays: [String] {
		["Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat"]
	}
}

extension Date: Strideable {
	
	static func - (lhs: Date, rhs: Date) -> TimeInterval {
		return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
	}
	
	var isLeapYear: Bool { Calendar.current.range(of: .day, in: .year, for: self)!.count == 366 }
	
	var year: Int {
		Calendar.current.component(.year, from: self)
	}
	var month: Int {
		Calendar.current.component(.month, from: self)
	}
	var day: Int {
		Calendar.current.component(.day, from: self)
	}
	var weekDay: Int {
		Calendar.current.component(.weekday, from: self)
	}
	var timeToDouble: Double{
		Double(self.hour) + (Double(self.minute) / 60.0)
	}
	var weekDayStringEnglish: String {
		Calendar.englishWeekDays[self.weekDay - 1]
	}
	var weekDayStringKorean: String {
		Calendar.koreanWeekDays[self.weekDay - 1]
	}
	var hour: Int {
		Calendar.current.component(.hour, from: self)
	}
	var minute: Int {
		Calendar.current.component(.minute, from: self)
	}
	/// String literal ( e.g. 21.02.03)
	var dayShortString: String{
		let dateFomatter = DateFormatter()
		dateFomatter.dateStyle = .short
		dateFomatter.locale = Locale(identifier: "ko_kr")
		dateFomatter.timeStyle = .none
		return dateFomatter.string(from: self)
	}
	
	func trimTimeString(is24HourSystem: Bool = true) -> String {
		var hour = is24HourSystem ? self.hour: self.hour % 12
		if hour == 0 {
			hour = 12
		}
		let minute = self.minute
		return (hour < 10 ? "0\(hour)": "\(hour)") + ":" + (minute < 10 ? "0\(minute)": "\(minute)")
	}
	
	func getMonthDayString(with locale: String) -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.locale = Locale(identifier: locale)
		dateFormatter.dateFormat = locale == "en_US" ? "MMM d": "M월 d일"
		return dateFormatter.string(from: self)
	}
	var monthDayTimeKoreanString: String {
		let dateFormatter = DateFormatter()
		dateFormatter.locale = Locale(identifier: "ko")
		dateFormatter.dateFormat = "M월 d일 a h:mm"
		return dateFormatter.string(from: self)
	}
	
	var aMonthAgo: Date {
		return Calendar.current.date(
			byAdding: DateComponents(month: -1), to: self)!
	}
	var aMonthAfter: Date {
		return Calendar.current.date(
			byAdding: DateComponents(month: 1), to: self)!
	}
	func isSameDay(with toCompare: Date) -> Bool {
		return self.year == toCompare.year && self.month == toCompare.month && self.day == toCompare.day
	}
	var toInt: Int {
		return (self.year * 10000) + (self.month * 100) + self.day
	}
	var startOfDay: Date {
		let components = Calendar.current.dateComponents([.year, .month, .day],
																										 from: self)
		return Calendar.current.date(from: components)!
	}
	
	var lastDateOfMonth: Int {
		switch month {
		case 1, 3, 5, 7, 8, 10, 12:
			return 31
		case 4, 6, 9, 11:
			return 30
		case 2:
			return isLeapYear ? 29: 28
		default:
			return 0
		}
	}
	
	func changeDate(to dateInt: Int) -> Date? {
		var components = Calendar.current.dateComponents([ .calendar, .year, .month, .day, .hour, .minute], from: self)
		components.year = dateInt/10000
		components.month = dateInt/100%100
		components.day = dateInt%100
		return components.date
	}
	
	func getNext(by component: ComponentType) -> Date{
		var nextComponent = Calendar.current.dateComponents([.hour, .minute], from: self)
		
		switch component {
		case .day(let day):
			nextComponent.day = day
		case .weekday(let weekday):
			nextComponent.weekday = weekday
		}
		
		return Calendar.current.nextDate(
			after: self,
			matching: nextComponent,
			matchingPolicy: .nextTime)!
	}

	enum ComponentType {
		case day (Int)
		case weekday (Int)
	}
}

extension Int {
	var toDate: Date?{
		DateComponents(
			calendar: Calendar.current,
			timeZone: .current,
			year: self / 10000,
			month: (self / 100) % 100,
			day: self % 100,
			hour: 12).date
	}
	var toKoreanWeekDay: String? {
		Calendar.koreanWeekDays[self]
	}
}

extension TimeInterval {
	static var forOneDay: TimeInterval {
		TimeInterval(60 * 60 * 24)
	}
	
	func getString(for language: SettingKey.Language) -> String {
		let timeIntervalMinute = Int(self/60)
		
		let hour = timeIntervalMinute/60
		let minute = timeIntervalMinute % 60
		switch language {
		case .korean:
			return (hour != 0 ? "\(hour)시간": "") + (minute != 0 ? "\(minute)분": "")
		case .english:
			return  (hour != 0 ? "\(hour)hours": "") +
			(minute != 0 ? "\(minute)minutes": "")
		}
		
	}
}
