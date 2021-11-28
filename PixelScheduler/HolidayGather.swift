
import Foundation

struct HolidayGather {
	private let apiKey = "9c57014c99e72d106d1fe7b23487390294256eb5"
	private let urlEndpoint = "https://calendarific.com/api/v2/holidays?"
	
	struct Holiday: Codable, Hashable {
		let dateInt: Int
		let title: String
		let description: String
		let type: HolidayType
		
		func translateTitle(to language: SettingKey.DateLanguage) -> String {
			switch language {
			case .english:
				return title
			case .korean:
				return HolidayDictionay.engToKor(from: title) ?? title
			}
		}
		
		func getDateString(for language: SettingKey.DateLanguage) -> String {
			let date = dateInt.toDate!
			switch language {
				case .korean:
					return "\(date.year)년 \(date.month)월 \(date.day)일"
				case .english:
					return date.description
			}
		}
		
		enum HolidayType: String, Codable {
			case national = "National holiday"
			case observance = "Observance"
			case season = "Season"
			case commonLocal = "Common local holiday"
		}
		init(dateInt: Int, title: String, description: String, type: HolidayType) {
			self.dateInt = dateInt
			self.title = title
			self.description = description
			self.type = type
		}
		
		init(from data: Response.HolidayCapsule){
			self.dateInt = (data.date.datetime["year"]! * 10000) + (data.date.datetime["month"]! * 100) + data.date.datetime["day"]!
			self.title = data.name
			self.description = data.description
			self.type = HolidayType(rawValue: data.type[0]) ?? .national
		}
	}
	
	enum CountryCode: String{
		case korea = "KR"
		case us = "US"
	}
	
	/**
	Get national holidays from api server [Calendarific](https://calendarific.com)
	- parameter country:  National Holiday to retrieve (US or KR)
	- parameter handler: Function handle data come from api sever
	*/
	func retrieveHolidays(about year: Int, of country: CountryCode,  handler: @escaping (Data) -> Void) {
		
		let urlString = urlEndpoint + "&api_key=" + apiKey + "&country=" + country.rawValue + "&year=" + String(year)
		let url = URL(string: urlString)!
		let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
			guard let data = data else {
				print("Fail to get holiday data from server")
				print("response: \(response.debugDescription)")
				print("error: \(error.debugDescription)")
				return }
			handler(data)
		}
		task.resume()
	}
	
	struct Response: Codable {
		var meta: [String: Int]
		var response: Data
		
		struct Data: Codable {
			var holidays: [HolidayCapsule]
		}
		struct HolidayCapsule: Codable {
			var name: String
			var type: [String]
			var description: String
			var date: DateCapsule
			
			struct DateCapsule: Codable {
				var iso: String
				var datetime: [String: Int]
			}
		}
	}
}
