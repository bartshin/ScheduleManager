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
	@State private var searchResults = [Schedule.Location]()
	@State private var searchResultViewPositionRatio: CGFloat = 0.75
	@State private var selectedLocation: Schedule.Location?
	
	init(location: Schedule.Location?) {
		_selectedLocation = .init(initialValue: location)
	}
	
	var body: some View {
		GeometryReader{ geometry in
			VStack {
				if let selectedLocation = selectedLocation {
					HStack(spacing: 30) {
						Button {
							searchString = ""
							searchResults.removeAll()
							slideSearchResultView(hide: true)
							withAnimation {
								self.selectedLocation = nil
							}
						} label: {
							Image(systemName: "chevron.backward")
						}
						Text(selectedLocation.title)
						Spacer()
					}
					.padding(.horizontal, 20)
				}else {
					TextField(settingController.language == .korean ? "장소 검색어를 입력하세요": "Keyword for searching location",
										text: $searchString,
										onEditingChanged: { startEditing in
						if startEditing {
							searchResults.removeAll()
						}
					},
										onCommit: {
						if !searchString.isEmpty {
							searchLocation(keyword: searchString)
						}
						slideSearchResultView(hide: false)
					})
						.textFieldStyle(.roundedBorder)
						.padding(.horizontal, 50)
				}
				ZStack {
					Map(coordinateRegion: $showingRegion, showsUserLocation: true, annotationItems: searchResults) { location in
						MapAnnotation(coordinate: location.coordinates, anchorPoint: CGPoint(x: 0.5, y: 0.7)) {
							Image(systemName: "mappin.circle.fill")
								.font(.title)
								.foregroundColor(getAnnotationColor(for: location))
								.onTapGesture {
									withAnimation {
										selectedLocation = location
									}
								}
								.zIndex(selectedLocation == location ? 1: 0)
						}
					}
					if isShowingResultView {
						searchResultView
							.frame(width: geometry.size.width * 0.5,
										 height: 300)
							.offset(x:
												geometry.size.width * searchResultViewPositionRatio + searchResultViewGestureOffset)
							.gesture(dragSearchResultView(in: geometry.size))
					}else if !searchString.isEmpty {
						showSearchResultButton
							.position(x: geometry.size.width - 30, y: 30)
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
	
	private func getAnnotationColor(for location: Schedule.Location) -> Color {
		if let selectedPlace = selectedLocation {
			return selectedPlace == location ? .blue: .gray
		}else {
			return .orange
		}
	}

	private func slideSearchResultView(hide: Bool) {
		let animationDuration = 0.5
		if !hide {
			isShowingResultView = true
		}
		DispatchQueue.main.async {
			withAnimation (.easeInOut(duration: animationDuration)){
				searchResultViewPositionRatio = hide ? 0.75: 0.25
			}
		}
		if hide {
			DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
				isShowingResultView = false
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
				searchResults = response.mapItems.compactMap { place in
					Schedule.Location(title: place.placemark.name ?? "",
														address: place.placemark.postalAddress?.street ?? "",
														coordinates: place.placemark.coordinate)
				}
			}
		}
	}
	@GestureState var searchResultViewGestureOffset: CGFloat = 0
	private var searchResultView: some View {
		List {
			if searchResults.isEmpty {
				Text(settingController.language == .korean ? "검색 결과가 없습니다": "No location is found")
					.font(.title)
			}
			ForEach(searchResults) { location in
				Text(location.title)
					.onTapGesture {
						selectedLocation = location
						withAnimation {
							showingRegion = MKCoordinateRegion(center: location.coordinates, span: LocationManager.streetBounds)
							slideSearchResultView(hide: true)
						}
					}
			}
		}
		.clipShape(RoundedRectangle(cornerRadius: 15))
		.padding(.vertical, 10)
	}
	
	private func dragSearchResultView(in size: CGSize) -> some Gesture {
		DragGesture()
			.updating($searchResultViewGestureOffset) { gestureValue, searchResultViewGestureOffset, _ in
				searchResultViewGestureOffset = gestureValue.translation.width
			}
			.onEnded { gestureValue in
				searchResultViewPositionRatio += gestureValue.translation.width / size.width
				slideSearchResultView(hide: gestureValue.translation.width > 50)
			}
	}
	
	private var showSearchResultButton: some View {
		Button {
			slideSearchResultView(hide: false)
		} label: {
			Image(systemName: "list.bullet.rectangle.portrait")
				.renderingMode(.template)
				.font(.title)
				.foregroundColor(.blue)
				.padding(5)
				.background(
					Circle()
						.fill(.white)
				)
		}
		.transition(.opacity)
	}
}

struct LocationPickerView_Previews: PreviewProvider {
	static var previews: some View {
		LocationPickerView(location: nil)
			.previewLayout(.fixed(width: 350, height: 400))
			.environmentObject(SettingController())
	}
}
