

import Foundation
import MapKit

struct Schedule: Codable, Identifiable {
	
	let title: String
	let description: String
	let time: DateType
	let alarm: Alarm?
	var isAlarmOn: Bool
	let priority: Int
	let id: UUID
	let location: Location?
	/// Device or External ( Apple, Google )
	let origin: Origin
	private var isDoneForOneDay = false
	private var daysCompleted = Set<Int>()
	var contact: Contact?
	
	var idForNotification: String {
		"ScheduleNotification:" + id.uuidString
	}
	
	func isDone(for dateInt: Int) -> Bool {
		switch self.time {
		case .spot(_):
			return isDoneForOneDay
		case .cycle(_,_,_), .period(_, _):
			return daysCompleted.contains(dateInt)
		}
	}
	
	mutating func toggleIsDone(for dateInt: Int) {
		switch self.time {
		case .spot(_):
			isDoneForOneDay.toggle()
		case .cycle(_,_,_), .period(_, _):
			if daysCompleted.contains(dateInt) {
				daysCompleted.remove(dateInt)
			}else {
				daysCompleted.insert(dateInt)
			}
		}
	}
	mutating func copyCompleteHistory(from schedule: Schedule) {
		daysCompleted = schedule.daysCompleted
		isDoneForOneDay = schedule.isDoneForOneDay
	}
	
	enum DateType: Codable {
		case spot (Date)
		case cycle (since: Date, for: CycleFactor, every: [Int])
		case period (start: Date, end: Date)
		
		func getDescription(for language: SettingKey.DateLanguage = .korean) -> String {
			let dateFormatter = DateFormatter()
			dateFormatter.locale = .init(identifier: language.locale)
			dateFormatter.dateFormat = "yy. MM. d a h: mm"
			switch self {
			case .spot(let date):
				return dateFormatter.string(from: date)
			case .period(let startDate, let endDate):
				if startDate.isSameDay(with: endDate) {
					let start = dateFormatter.string(from: startDate)
					dateFormatter.dateFormat = "a h: mm"
					let end = dateFormatter.string(from: endDate)
					return start + " ~ " + end
				}else {
					return "\(dateFormatter.string(from: startDate)) ~ \(dateFormatter.string(from: endDate))"
				}
			case .cycle(let date, let factor , let values):
				let intro = language == .korean ? dateFormatter.string(from: date) + " 이후 ": "Since " + dateFormatter.string(from: date)
				let cycle: String
				switch factor {
				case .day:
					cycle = values.reduce(into: language == .korean ? "매 월 ": " Every month")
					{ string, dateInt in
						string += language == .korean ? " \(dateInt)일 ": "\(dateInt)th"
					}
				case .weekday:
					cycle = values.reduce(into: language == .korean ? "매 주 ":
																	" Every week ")
					{ string, weekInt in
						let weekDay = language == .korean ? Calendar.koreanWeekDays[weekInt - 1]: Calendar.englishWeekDays[weekInt - 1]
						string += language == .korean ? weekDay + "요일 ": weekDay + " "
					}
				}
				return intro + cycle
			}
		}
	}
	enum CycleFactor: String, Codable{
		case weekday = "weekday"
		case day = "day"
	}
	
	enum Alarm: Equatable, Codable{
		case once (Date)
		case periodic (Date)
	}
	
	enum Origin: Codable, Equatable {
		case localDevice
		case googleCalendar(calendarID: String, uid: String)
		case appleCalendar(uid: String)
	}
	struct Location: Codable {
		static let dummyCoordinates = CLLocationCoordinate2D(
			latitude: 40.750556, longitude: -73.993611)
		let title: String
		let address: String
		let coordinates: CLLocationCoordinate2D
	}
	struct Contact: Codable {
		let name: String
		let phoneNumber: String
		let contactID: String
	}
	
	init(title: String,
			 description: String,
			 priority: Int,
			 time: DateType,
			 alarm: Alarm?,
			 storeAt storedLocation: Origin = .localDevice,
			 with id: UUID? = nil,
			 location: Location? = nil,
			 contact: Contact? = nil){
		self.title = title
		self.description = description
		self.priority = priority
		self.time = time
		if alarm != nil {
			if case .periodic(_) = alarm! {
				guard case .cycle = time else {
					preconditionFailure("Invalid periodic alarm for non-cycle schedule")
				}
			}
		}
		self.alarm = alarm
		self.origin = storedLocation
		self.isAlarmOn = alarm != nil
		if id != nil {
			self.id = id!
		}else {
			self.id = UUID()
		}
		self.contact = contact
		self.location = location
	}
}

extension Schedule: Comparable {
	
	static func == (lhs: Schedule, rhs: Schedule) -> Bool {
		lhs.id == rhs.id
	}
	
	static func < (lhs: Schedule, rhs: Schedule) -> Bool {
		let criterion: (Date, Date)
		switch (lhs.time, rhs.time) {
		case(let .spot(dateLhs), let .spot(dateRhs)):
			criterion = (dateLhs, dateRhs)
		case (let .spot(dateLhs), let .period(startRhs, _)):
			criterion = (dateLhs, startRhs)
		case (let .spot(dateLhs), let .cycle(sinceRhs, _, _)):
			criterion = (dateLhs, sinceRhs)
		case (let .period(startLhs, _), let .period(startRhs, _)):
			criterion = (startLhs, startRhs)
		case (let .period(startLhs, _), let .spot(dateRhs)):
			criterion = (startLhs, dateRhs)
		case (let .period(startLhs, _), let .cycle(sinceRhs, _, _)):
			criterion = (startLhs, sinceRhs)
		case (let .cycle(sinceLhs, _, _), let .cycle(sinceRhs, _, _)):
			criterion = (sinceLhs, sinceRhs)
		case (let .cycle(sinceLhs, _, _), let .spot(dateRhs)):
			criterion = (sinceLhs, dateRhs)
		case (let .cycle(sinceLhs, _, _), let .period(startRhs, _)):
			criterion = (sinceLhs, startRhs)
		}
		return criterion.0 < criterion.1
	}
}

// MARK:- JSON Encoding

extension Schedule.Location {
	private enum CodingKeys: String, CodingKey {
		case title
		case address
		case latitude
		case longitude
	}
	
	func encode(to encoder: Encoder) throws {
		
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(self.title, forKey: .title)
		try container.encode(self.address, forKey: .address)
		try container.encode(self.coordinates.latitude, forKey: .latitude)
		try container.encode(self.coordinates.longitude, forKey: .longitude)
	}
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let title = try container.decode(String.self, forKey: .title)
		let address = try container.decode(String.self, forKey: .address)
		let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
		let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
		self = .init(
			title: title,
			address: address,
			coordinates: CLLocationCoordinate2D(
				latitude: latitude, longitude: longitude))
	}
}

extension Schedule.DateType {
	
	private enum CodingKeys: String, CodingKey {
		case spot
		case start
		case end
		case type
		case cycleFactor
		case cycleValues
	}
	
	func encode(to encoder: Encoder) throws {
		//access the keyed container
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		//iterate over self and encode (1) the status and (2) the associated value(s)
		switch self {
		case .spot(let date):
			try container.encode("spot", forKey: .type)
			try container.encode(date, forKey: .spot)
		case .period(start: let start, end: let end):
			try container.encode("period", forKey: .type)
			try container.encode(start, forKey: .start)
			try container.encode(end, forKey: .end)
		case .cycle(since: let start, for: let cycleType, every: let values):
			try container.encode("cycle", forKey: .type)
			try container.encode(start, forKey: .start)
			try container.encode(cycleType.rawValue, forKey: .cycleFactor)
			try container.encode(values, forKey: .cycleValues)
		}
	}
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let type = try container.decode(String.self, forKey: .type)
		switch type {
		case "spot":
			let time = try container.decode(Date.self, forKey: .spot)
			self = .spot(time)
		case "period":
			let start = try container.decode(Date.self, forKey: .start)
			let end = try container.decode(Date.self, forKey: .end)
			self = .period(start: start, end: end)
		case "cycle":
			let start = try container.decode(Date.self, forKey: .start)
			let cycleType = try container.decode(Schedule.CycleFactor.self, forKey: .cycleFactor)
			let values = try container.decode([Int].self, forKey: .cycleValues)
			self = .cycle(since: start, for: cycleType, every: values)
		default:
			throw("Invalid Date type of schdule during decoding")
		}
	}
}

extension Schedule.Alarm{
	private enum CodingKeys: String, CodingKey {
		case type
		case date
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		switch self {
		case .once(let dateToAlarm):
			try container.encode("once", forKey: .type)
			try container.encode(dateToAlarm, forKey: .date)
		case .periodic(let dateToAlarm):
			try container.encode("periodic", forKey: .type)
			try container.encode(dateToAlarm, forKey: .date)
		}
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let type = try container.decode(String.self, forKey: .type)
		if type == "periodic" {
			let dateToAlarm = try container.decode(Date.self, forKey: .date)
			self = .periodic(dateToAlarm)
		} else {
			let dateToAlarm = try container.decode(Date.self, forKey: .date)
			self = .once(dateToAlarm)
		}
	}
}

extension Schedule.Origin {
	
	private enum CodingKeys: String, CodingKey, CaseIterable {
		case storedLocation
		case calendarID
		case uid
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		switch self {
		case .localDevice:
			try container.encode("localDevice", forKey: .storedLocation)
		case .googleCalendar(let calendarID, let uid):
			try container.encode("googleCalendar", forKey: .storedLocation)
			try container.encode(calendarID, forKey: .calendarID)
			try container.encode(uid, forKey: .uid)
		case .appleCalendar(uid: let uid):
			try container.encode("appleCalendar", forKey: .storedLocation)
			try container.encode(uid, forKey: .uid)
		}
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let location = try container.decode(String.self, forKey: .storedLocation)
		if location == "localDevice" {
			self = .localDevice
		}else if location == "googleCalendar" {
			let calendarID = try container.decode(String.self, forKey: .calendarID)
			let uid = try container.decode(String.self, forKey: .uid)
			self = .googleCalendar(calendarID: calendarID, uid: uid)
		}else if location == "appleCalendar" {
			let uid = try container.decode(String.self, forKey: .uid)
			self = .appleCalendar(uid: uid)
		}else {
			throw DecodingError.keyNotFound(
				CodingKeys.storedLocation,
				DecodingError.Context(codingPath: CodingKeys.allCases, debugDescription: "Location of schedule stored is wrong"))
		}
	}
}
