//
//  DatePickerPopup.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/11/11.
//

import SwiftUI

struct DatePickerPopup: View {
	@Binding var date: Date
	let language: SettingKey.Language
	
    var body: some View {
		DatePicker("", selection: $date, displayedComponents: .date)
			.datePickerStyle(.graphical)
			.environment(\.locale, Locale.init(identifier: language.locale))
    }
}

struct DatePickerPopup_Previews: PreviewProvider {
    static var previews: some View {
		DatePickerPopup(date: .constant(Date()), language: .korean)
    }
}
