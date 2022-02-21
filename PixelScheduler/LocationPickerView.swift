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
	@Binding var isPresenting: Bool
	@State private var selectedLocation: Schedule.Location?
	private let selectLocation: (Schedule.Location) -> Void
	
	
	init(isPresenting: Binding<Bool>, location: Schedule.Location?, selectLocation: @escaping (Schedule.Location) -> Void) {
		_selectedLocation = .init(initialValue: location)
		_isPresenting = isPresenting
		self.selectLocation = selectLocation
	}
	
	var body: some View {
		GeometryReader{ geometry in
			VStack {
				if selectedLocation != nil {
					selectedLocationLabel
				}else {
					searchBar
				}
				ZStack {
					Map(coordinateRegion: $showingRegion, showsUserLocation: true, annotationItems: searchResults) { location in
						drawAnnotation(for: location)
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
	
	private var searchBar: some View {
		HStack {
			TextField(searchPlaceHolder,
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
				.padding(.horizontal)
			Button {
				withAnimation {
					isPresenting = false
				}
			} label: {
				Image(systemName: "xmark.circle")
					.foregroundColor(.pink)
					.frame(width: 40, height: 40)
			}
		}
		.padding(.horizontal, 20)
	}
	
	private var searchPlaceHolder: String {
		if location.lastLocation != nil {
			return settingController.language == .korean ? "장소 검색어를 입력하세요": "Keyword for searching location"
		}else {
			return settingController.language == .korean ? "현재 위치 가져오는중...": "Now getting current location..."
		}
	}
	
	private var selectedLocationLabel: some View {
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
			
			Text(selectedLocation!.title)
				.font(.title2)
			
			Button {
				selectLocation(selectedLocation!)
				withAnimation {
					isPresenting = false
				}
			} label:  {
				Image(systemName: "checkmark")
					.foregroundColor(.green)
			}
			Spacer()
			
			Button {
				withAnimation {
					isPresenting = false
				}
			} label: {
				Image(systemName: "xmark")
					.foregroundColor(.red)
			}
			
			Spacer()
		}
		.padding(.horizontal, 20)
	}
	
	private struct AnnotationView: View {
		let settingController: SettingController
		@Binding var selectedLocation: Schedule.Location?
		let location: Schedule.Location
		
		var body: some View {
			Image(systemName: "mappin.circle.fill")
				.font(.title)
				.foregroundColor(foreGroundColor)
				.onTapGesture {
					withAnimation {
						selectedLocation = location
					}
				}
				.zIndex(selectedLocation == location ? 1: 0)
		}
		
		private var foreGroundColor: Color {
			if let selectedPlace = selectedLocation {
				return selectedPlace == location ? Color(settingController.palette.primary): Color(settingController.palette.primary.withAlphaComponent(0.5))
			}else {
				return Color(settingController.palette.secondary)
			}
		}
	}
	
	private func drawAnnotation(for location: Schedule.Location) -> MapAnnotation<AnnotationView>{
		MapAnnotation(coordinate: location.coordinates, anchorPoint: CGPoint(x: 0.5, y: 0.7)) {
			AnnotationView(settingController: settingController, selectedLocation: $selectedLocation,
								 location: location)
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
	
	private var sortedSearchResults: [(Schedule.Location, Double)] {
		if let lastLocation = location.lastLocation {
			let currentLocation = Schedule.Location(title: "currentLocation", address: "", coordinates: lastLocation.coordinate)
			return searchResults.compactMap { location in
				(location, currentLocation.calcDistance(to: location))
			}.sorted {
				$0.1 < $1.1
			}
		}else {
			return searchResults.compactMap { location in
				(location, 0)
			}
		}
	}
	
	private var searchResultView: some View {
		List {
			if searchResults.isEmpty {
				Text(settingController.language == .korean ? "검색 결과가 없습니다": "No location is found")
					.font(.title)
			}
			
			ForEach(sortedSearchResults, id: \.0.id) { (location, distance) in
				VStack(alignment: .leading) {
					HStack(spacing: 10) {
						Text(location.title)
							.font(.body)
							.foregroundColor(Color(settingController.palette.primary))
						if self.location.lastLocation != nil {
							Text(distance > 1000 ? String(format: "%.2f", Double(distance)/1000) + "km": String(format: "%.1f", Double(distance)) + "m")
								.font(.caption2)
								.foregroundColor(Color(settingController.palette.secondary))
						}
					}
					Text(location.address)
						.font(.caption)
						.foregroundColor(Color(settingController.palette.secondary))
				}
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
