//
//  ContactView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2022/01/11.
//

import SwiftUI
import ContactsUI

struct ContactVCRepresentation: UIViewControllerRepresentable {
	let contact: CNContact
	func makeUIViewController(context: Context) -> CNContactViewController {
		let contactVC = CNContactViewController(for: contact)
		contactVC.hidesBottomBarWhenPushed = true
		contactVC.allowsEditing = false
		return contactVC
	}
	
	func updateUIViewController(_ uiViewController: CNContactViewController, context: Context) {
		print("Update contact view controller")
	}
}

extension CNContact: Identifiable {
	public var id: String {
		self.identifier
	}
}
