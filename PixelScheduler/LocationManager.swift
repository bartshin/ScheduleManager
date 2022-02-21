//
//  LocationManager.swift
//  PixelScheduler
//
//  Created by bart Shin on 30/05/2021.
//

import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject {
	
	static let seoulLocation = CLLocationCoordinate2D(latitude: 37.532600, longitude: 127.024612)
	/// Bounds base on size of Seoul
	static let cityBounds = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
	static let streetBounds = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
	
	private let manager: CLLocationManager
	@Published private(set) var isPermitted: Bool {
		didSet {
			if isPermitted {
				manager.requestLocation()
			}
		}
	}
	@Published private(set) var lastLocation: CLLocation? {
		didSet{
			getCityInfomation(near: lastLocation)
		}
	}
	@Published private(set) var cityname: String?
	
	func requestAuthorization() {
		if manager.authorizationStatus == .notDetermined {
			manager.requestWhenInUseAuthorization()
		}else if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse{
			isPermitted = true
		}
	}
	
	static func showLocationInAppleMap(for schedule: Schedule) {
		guard let location = schedule.location else {
			return
		}
		let mapAnnotation = ScheduleAnnotaion(
			title: location.title,
			address: location.address,
			priority: schedule.priority,
			coordinate: location.coordinates)
		let launchOptions = [
			MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
		mapAnnotation.mapItem?.openInMaps(launchOptions: launchOptions)
	}
	
	private func getCityInfomation(near location: CLLocation?) {
		guard let location = location else {
			return
		}
		let geocoder = CLGeocoder()
		geocoder.reverseGeocodeLocation(
			location,
			preferredLocale: .init(identifier: "Ko-kr")) {[weak weakSelf = self] placemarks, error in
				if let lastPlacemark = placemarks?.last {
					weakSelf?.cityname = lastPlacemark.administrativeArea
				}
			}
	}
	
	override init() {
		manager = CLLocationManager()
		manager.desiredAccuracy = kCLLocationAccuracyBest
		isPermitted = false
		super.init()
		manager.delegate = self
	}
}

extension LocationManager: CLLocationManagerDelegate {
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		isPermitted = manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let lastLocation = locations.last else {
			return
		}
		self.lastLocation = lastLocation
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("Fail to get location \(error.localizedDescription)")
	}
}
