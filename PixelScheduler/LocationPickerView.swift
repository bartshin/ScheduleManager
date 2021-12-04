//
//  LocationPickerView.swift
//  PixelScheduler
//
//  Created by bart Shin on 2021/12/04.
//

import SwiftUI
import MapKit

struct LocationPickerView: View {
	
	@EnvironmentObject var settingController: SettingController
	@StateObject private var location = LocationManager()
	@State private var searchString = ""
	@State private var showingRegion = MKCoordinateRegion(center: LocationManager.seoulLocation, span: LocationManager.cityBounds)
	
    var body: some View {
			VStack {
				TextField(settingController.language == .korean ? "장소 검색어를 입력하세요": "Keyword for searching location", text: $searchString)
					.textFieldStyle(.roundedBorder)
				Map(coordinateRegion: $showingRegion)
			}
			.onAppear {
				location.requestAuthorization()
			}
			.onChange(of: location.lastLocation) {
				if let location = $0 {
					withAnimation {
						showingRegion = MKCoordinateRegion(center: location.coordinate, span: LocationManager.streetBounds)
					}
				}
			}
    }
}

struct LocationPickerView_Previews: PreviewProvider {
    static var previews: some View {
        LocationPickerView()
				.environmentObject(SettingController())
    }
}
