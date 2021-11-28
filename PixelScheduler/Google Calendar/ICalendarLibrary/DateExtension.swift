import Foundation

extension Date {
    /// Convert String to Date
    func toIcalendarString() -> String {
        return ICalendar.dateFormatter.string(from: self)
    }
	
	var convertUTCToLocal: String? {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZZ"
		
		dateFormatter.timeZone = TimeZone.init(abbreviation: "UTC")
		let timeUTC = dateFormatter.date(from: "\(self)")
		
		if timeUTC != nil {
			dateFormatter.timeZone = NSTimeZone.local
			
			let localTime = dateFormatter.string(from: timeUTC!)
			return localTime
		}
		
		return nil
	}
}
