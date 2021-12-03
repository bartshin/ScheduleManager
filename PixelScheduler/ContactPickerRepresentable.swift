//
//  ContactPickerRepresentable.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/12/03.
//

import SwiftUI
import ContactsUI

struct ContactPickerRepresentable: UIViewControllerRepresentable {
	
	@Environment(\.presentationMode) var presentationMode
	private let coordinator: Coordinator
	
	init(pickContact: @escaping (Schedule.Contact) -> Void) {
		coordinator = Coordinator(pickContact: pickContact)
	}
	
	func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
		
	}
	
	func makeUIViewController(context: Context) -> some UIViewController {
		let navigationController = UINavigationController()
		let contactPicker = CNContactPickerViewController()
		contactPicker.delegate = coordinator
		navigationController.present(contactPicker, animated: true)
		return navigationController
	}
	
	func makeCoordinator() -> Coordinator {
		coordinator.parent = self
		return coordinator
	}
	
	class Coordinator: NSObject, ObservableObject, CNContactPickerDelegate {
		
		private let pickContact: (Schedule.Contact) -> Void
		var parent: ContactPickerRepresentable?
		
		init(pickContact: @escaping (Schedule.Contact) -> Void) {
			self.pickContact = pickContact
		}
		
		func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
			let phoneNumber: String
			if let firstNumber = contact.phoneNumbers.first?.value {
				phoneNumber = firstNumber.stringValue
			}else {
				phoneNumber = String()
			}
	
			pickContact(.init(name: contact.familyName + contact.givenName, phoneNumber: phoneNumber, contactID: contact.identifier))
			parent?.presentationMode.wrappedValue.dismiss()
		}
		
		func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
			parent?.presentationMode.wrappedValue.dismiss()
		}
	}
	
}
