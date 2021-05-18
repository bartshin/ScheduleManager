//
//  EventListCell.swift
//  Schedule_B
//
//  Created by Shin on 2/24/21.
//

import UIKit

class ExternalCalendarEventCell: UITableViewCell {
    
    // MARK: Properites
    static let reuseID = "ExternalCalendarEventCell"
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var alarmButton: UIButton!
    
    var eventPresented: Schedule?
}
