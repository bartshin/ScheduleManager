//
//  EventListTableVC.swift
//  Schedule_B
//
//  Created by Shin on 2/24/21.
//

import UIKit

class ExternalCalendarEventListController: NSObject, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Properties
    var tableView: UITableView!
    /// Do not set to nil
    var events: [Schedule]? {
        didSet {
            selectedEventID.removeAll()
            events!.forEach {
                if case let .googleCalendar(_, newID) = $0.origin{
                    selectedEventID.insert(newID)
                }else if case .appleCalendar(_) = $0.origin {
                    selectedEventID.insert($0.id.uuidString)
                }
            }
            DispatchQueue.runOnlyMainThread { [ weak weakSelf = self] in
                weakSelf?.tableView.reloadData()
            }
        }
    }
    private var selectedEventID = Set<String>()
    
    var schedulesToImport: [Schedule] {
        return events!.filter {
            if case let .googleCalendar(_, eventID) = $0.origin {
                return selectedEventID.contains(eventID)
            }else if case .appleCalendar(_) = $0.origin {
                return selectedEventID.contains($0.id.uuidString)
            }else {
                return false
            }
        }
    }
    
    // MARK:- User intents
    
    func changeGroupInclusion(to isIncluded: Bool) {
        
        if isIncluded {
            events!.forEach {
                if case let .googleCalendar(_, newID) = $0.origin{
                    selectedEventID.insert(newID)
                }else if case .appleCalendar(_) = $0.origin {
                    selectedEventID.insert($0.id.uuidString)
                }
            }
        }else {
            selectedEventID.removeAll()
        }
        tableView.reloadData()
    }
    
    // MARK:- Table view delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        events?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ExternalCalendarEventCell.reuseID) as! ExternalCalendarEventCell
        guard events != nil else { return cell }
        cell.eventPresented = events![indexPath.row]
        // Title label
        cell.titleLabel.text = cell.eventPresented!.title
        // Date Label
        switch cell.eventPresented!.time {
        case .spot(let date):
            cell.dateLabel.text = date.dayShortString
        case .period(start: let startDate, end: let endDate):
            cell.dateLabel.text = startDate.dayShortString + " ~ " + endDate.dayShortString
            cell.dateLabel.font = UIFont.systemFont(ofSize: 10)
        default:
            break
        }
        if cell.eventPresented!.alarm != nil {
            cell.alarmButton.isHidden = false
            cell.alarmButton.isSelected = cell.eventPresented!.isAlarmOn
        }else {
            cell.alarmButton.isHidden = true
        }
        let eventID: String
        switch cell.eventPresented!.origin {
        case .googleCalendar(_, uid: let googleEventID):
            eventID = googleEventID
        case .appleCalendar(_):
            eventID = cell.eventPresented!.id.uuidString
        default:
            eventID = ""
        }
        cell.accessoryType = selectedEventID.contains(eventID) ? .checkmark : .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let eventID: String
        let event = events![indexPath.row]
        switch event.origin {
        case .googleCalendar(_, uid: let googleEventID):
            eventID = googleEventID
        case .appleCalendar(_):
            eventID = event.id.uuidString
        default:
            eventID = ""
        }
        if selectedEventID.contains(eventID){
            selectedEventID.remove(eventID)
        }else {
            selectedEventID.insert(eventID)
        }
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
}
