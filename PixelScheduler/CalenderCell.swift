

import SwiftUI
import Combine

class CalendarCell: UICollectionViewCell {
	
	static var reuseID: String {
		String(describing: Self.self)
	}
	
	var calendarCellView: CalendarCellView {
		get {
			calendarCellHC.rootView
		}
		set{
			calendarCellHC.rootView = newValue
		}
	}
	override func awakeFromNib() {
		super.awakeFromNib()
		self.contentView.autoresizingMask.insert(.flexibleWidth)
		self.contentView.autoresizingMask.insert(.flexibleHeight)
	}
	
	// Swift UI
	var calendarCellHC = UIHostingController(rootView: CalendarCellView())
	
	static func size(in frameSize: CGSize, with rows: Int) -> CGSize{
		CGSize(width: frameSize.width / 8,
					 height: frameSize.height / CGFloat(rows + 1))
	}
}
