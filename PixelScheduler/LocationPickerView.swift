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
	@State private var searchResults = [Place]()
	
	
	private struct Place: Identifiable {
		let name: String
		let coordinate: CLLocationCoordinate2D
		var id: String {
			"\(coordinate.latitude), \(coordinate.longitude)"
		}
	}
	var body: some View {
		GeometryReader{ geometry in
			VStack {
				TextField(settingController.language == .korean ? "장소 검색어를 입력하세요": "Keyword for searching location", text: $searchString,
									onCommit: {
					if !searchString.isEmpty {
						searchLocation(keyword: searchString)
					}
				})
					.textFieldStyle(.roundedBorder)
				ZStack {
					Map(coordinateRegion: $showingRegion, showsUserLocation: true, annotationItems: searchResults) {
						MapMarker(coordinate: $0.coordinate, tint: .blue)
					}
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
	
	private func searchLocation(keyword: String) {
		
		let request = MKLocalSearch.Request()
		request.naturalLanguageQuery = keyword
		
		MKLocalSearch(request: request).start { response, error in
			guard error == nil,
						let response = response else{
							print("Error to search location \(error?.localizedDescription ?? "")")
							return
						}
			DispatchQueue.main.async {
				searchResults = response.mapItems.compactMap {
					Place(name: $0.name ?? "", coordinate: $0.placemark.coordinate)
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
