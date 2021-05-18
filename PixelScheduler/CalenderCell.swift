

import SwiftUI
import Combine

class CalendarCell: UICollectionViewCell {
    
    static let reuseID = "CalendarCell"
    var calendarCellView: CalendarCellView {
        get {
            calendarCellHC.rootView
        }
        set{
            calendarCellHC.rootView = newValue
        }
    }
    
    
    // Swift UI
    var calendarCellHC = UIHostingController(rootView: CalendarCellView())
   
    static func size(in frameSize: CGSize) -> CGSize{
        CGSize(width: frameSize.width / 8,
               height: frameSize.height / 6)
    }
}
