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
	@State private var isShowingResultView = false
	
    var body: some View {
		GeometryReader{ geometry in
			VStack {
				TextField(settingController.language == .korean ? "장소 검색어를 입력하세요": "Keyword for searching location", text: $searchString,
						  onCommit: {
					DispatchQueue.main.async {
						withAnimation {
							isShowingResultView.toggle()
						}
					}
				})
					.textFieldStyle(.roundedBorder)
				ZStack {
					Map(coordinateRegion: $showingRegion)
					if isShowingResultView {
						searchResultView
							.frame(width: geometry.size.width * 0.5,
								   height: 300)
							.offset(x: geometry.size.width * 0.25)
							.transition(.move(edge: .trailing))
					}
				}
				.frame(width: geometry.size.width, height: 300)
			}
			.onAppear {
				location.requestAuthorization()
			}
			.onChange(of: location.lastLocation) {
				if let location = $0 {
					DispatchQueue.main.async {
						withAnimation {
							showingRegion = MKCoordinateRegion(center: location.coordinate, span: LocationManager.streetBounds)
						}
					}
				}
			}
		}
    }
	
	private var searchResultView: some View {
		List {
			Text("Search result")
		}
		.clipShape(RoundedRectangle(cornerRadius: 30))
	}
}

struct LocationPickerView_Previews: PreviewProvider {
    static var previews: some View {
		LocationPickerView()
			.previewLayout(.fixed(width: 350, height: 400))
				.environmentObject(SettingController())
    }
}
