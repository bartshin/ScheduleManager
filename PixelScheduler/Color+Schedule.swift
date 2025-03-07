
import SwiftUI

extension UIColor {
	convenience init(red: Int, green: Int, blue: Int) {
		assert(red >= 0 && red <= 255, "Invalid red component")
		assert(green >= 0 && green <= 255, "Invalid green component")
		assert(blue >= 0 && blue <= 255, "Invalid blue component")
		
		self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1)
	}
	convenience init(rgb: Int) {
		self.init(
			red: (rgb >> 16) & 0xFF,
			green: (rgb >> 8) & 0xFF,
			blue: rgb & 0xFF
		)
	}
	static func byPriority(_ priority: Int) -> UIColor {
		guard priority > 0 , priority < 6 else {
			assertionFailure("Drawing fail: Invalid priority of schedule is passed to cell")
			return UIColor.black
		}
		return UIColor(named: "priority\(priority)")!
	}
	
	static func backgroundByPriority(_ priority: Int) -> UIColor {
		guard priority > 0 , priority < 6 else {
			assertionFailure("Drawing fail: Invalid priority of schedule is passed to cell")
			return UIColor.white
		}
		return UIColor(named: "priority\(priority)_background")!
	}
	static func nameByPriority(_ priority: Int) -> String {
		switch priority {
		case 1:
			return "red"
		case 2:
			return "orange"
		case 3:
			return "yellow"
		case 4:
			return "green"
		case 5:
			return "blue"
		default:
			fatalError()
		}
	}
}
extension Color {
	
	static func byPriority(_ priority: Int) -> Color {
		return Color(UIColor.byPriority(priority))
	}
	static func backgroundByPriority(_ priority: Int) -> Color {
		return Color(UIColor.backgroundByPriority(priority))
	}
	
	enum PriorityButton: String, CaseIterable {
		case red = "🔴"
		case orange = "🟠"
		case green = "🟡"
		case blue = "🟢"
		case black = "🔵"
		
		static func by(_ priority: Int) -> String {
			guard priority > 0,
						priority < 6 else {
							assertionFailure()
							return ""
						}
			return Self.allCases[priority - 1].rawValue
		}
	}
}
