

import SwiftUI
import Combine

class CalendarCell: UICollectionViewCell {
	
	var hostingController: UIHostingController<CalendarCellView>?
	
	static var reuseID: String {
		String(describing: Self.self)
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		self.contentView.autoresizingMask.insert(.flexibleWidth)
		self.contentView.autoresizingMask.insert(.flexibleHeight)
	}
	
	
}
