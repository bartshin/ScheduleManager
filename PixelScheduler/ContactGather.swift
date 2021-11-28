//
//  ContactGather.swift
//  PixelScheduler
//
//  Created by Shin on 4/12/21.
//

import Foundation
import ContactsUI

class ContactGather: NSObject, ObservableObject {
    let store: CNContactStore
	private(set) var isContactAvailable: Bool
    
    func requestPermission(permittedHandler: @escaping () -> Void ,
                           deniedHandler: @escaping () -> Void) {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            permittedHandler()
        case .notDetermined:
            store.requestAccess(for: .contacts) { granted, error in
                if error != nil {
                    assertionFailure("Error during get contact permission \n \(error!.localizedDescription)")
                }
                if granted {
                    permittedHandler()
                }else {
                    deniedHandler()
                }
            }
        default:
            deniedHandler()
        }
    }
    
    func getContacts(by ids: [String], forImage: Bool) throws -> [CNContact] {
        var keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        if forImage {
            keys += [CNContactThumbnailImageDataKey, CNContactImageDataAvailableKey] as [CNKeyDescriptor]
        }else {
            keys.append(CNContactViewController.descriptorForRequiredKeys())
        }
        let predicate = CNContact.predicateForContacts(withIdentifiers: ids)
        do {
            return try store.unifiedContacts(matching: predicate, keysToFetch: keys as [CNKeyDescriptor])
        }
        catch {
            throw error
        }
    }
    
	override init() {
        store = CNContactStore()
		isContactAvailable = CNContactStore.authorizationStatus(for: .contacts) == .authorized
		super.init()
    }
}
