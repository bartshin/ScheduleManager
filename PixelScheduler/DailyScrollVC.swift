//
//  DailyTableVC.swift
//  PixelScheduler
//
//  Created by Shin on 2/26/21.
//

import SwiftUI
import Combine
import AVFoundation

class DailyScrollVC: UIHostingController<DailyScrollView> {
    
    // MARK: Controller
    var settingController: SettingController! {
        didSet {
            rootView.colorPalette = settingController.palette
            rootView.visualMode = settingController.visualMode
        }
    }
    var modelController: ScheduleModelController! {
        didSet {
            observeScheduleCancellable = modelController.objectWillChange.sink { [self] _ in
                if dateIntShowing != nil {
                    let newSchedules = modelController.getSchedules(for: dateIntShowing!)
                    rootView.dataSource.setNewSchedule(newSchedules, of: dateIntShowing!.toDate!)
                }
            }
        }
    }
    let contactGather = ContactGather()
    var observeScheduleCancellable: AnyCancellable?
    
    // MARK: - Properties
    
    private var isContactAvailable = false
    let vabrationGenerator = UIImpactFeedbackGenerator()
    var observeTopViewCancellable: AnyCancellable?
    var dateIntShowing: Int? {
        willSet {
            vabrationGenerator.prepare()
        }
        didSet {
            rootView.date = dateIntShowing!.toDate!
            let newSchedules = modelController.getSchedules(for: dateIntShowing!)
            rootView.dataSource.setNewSchedule(newSchedules, of: dateIntShowing!.toDate!)
            // Map [ scheduleID: contactID ]
            var contactMap = [ String : UUID ]()
            newSchedules.forEach {
                if let contact = $0.contact, contactMap[contact.contactID] == nil {
                    contactMap[contact.contactID] = $0.id
                }
            }
            
            if isContactAvailable, !contactMap.isEmpty,
               let result = try? contactGather.getContacts(
                by: Array(contactMap.keys) , forImage: true){
                result.forEach { contact in
                    let scheduleID = contactMap[contact.identifier]!
                    if rootView.dataSource.profileImages[scheduleID] == nil ,
                        let data = contact.thumbnailImageData,
                       let image = UIImage(data: data) {
                        rootView.dataSource.profileImages[scheduleID] = image
                    }
                }
            }
            vabrationGenerator.generateFeedback(for: settingController.hapticMode)
        }
    }
    
    // MARK: - User intents
    private func tapSchedule(_ schedule: Schedule) {
        performSegue(withIdentifier: SegueID.ShowDetailSegue.rawValue, sender: schedule.id)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueID.ShowDetailSegue.rawValue,
           let detailVC = segue.destination as? scheduleDetailVC,
           let id = sender as? UUID {
            detailVC.modelController = modelController
            detailVC.settingController = settingController 
            detailVC.schedulePresenting = modelController.getSchedule(by: id)
            detailVC.dateIntShowing = dateIntShowing!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rootView.tapSchedule = tapSchedule
        rootView.labelLanguage = settingController.language
        contactGather.requestPermission {
            self.isContactAvailable = true
        } deniedHandler: {
            self.isContactAvailable = false
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder, rootView:
		DailyScrollView(data: DailyViewDataSource(),
						date: Date(),
						colorPalette: .basic,
						visualMode: .system,
						language: .korean))
    }
    
    enum SegueID: String{
        case ShowDetailSegue
    }
}
