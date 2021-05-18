//
//  MKMapViewExtension.swift
//  Schedule_B
//
//  Created by Shin on 3/2/21.
//

import MapKit
import Contacts

extension MKMapView {
    func centerToLocation(_ location: CLLocation,
                          regionRadius: CLLocationDistance = 1000) {
        let coordinateRegion = MKCoordinateRegion(
          center: location.coordinate,
          latitudinalMeters: regionRadius,
          longitudinalMeters: regionRadius)
        setRegion(coordinateRegion, animated: true)
      }
}
class ScheduleAnnotaion: NSObject, MKAnnotation{
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let priority: Int
    
    init(title: String?, address: String?, priority: Int ,coordinate: CLLocationCoordinate2D) {
        self.title = title ?? ""
        self.subtitle = address ?? ""
        self.priority = priority
        self.coordinate = coordinate
    }
    var mapItem: MKMapItem? {
        guard let address = subtitle else { return nil }
        
        let addressDict = [CNPostalAddressStreetKey: address]
        let placemark = MKPlacemark(
            coordinate: coordinate,
            addressDictionary: addressDict)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = title
        return mapItem
    }
}
class ScheduleMarkerView: MKMarkerAnnotationView {
    static let reuseID = "scheduleAnnotation"
    override var annotation: MKAnnotation? {
        willSet {
            guard let annotaion = newValue as? ScheduleAnnotaion else { return }
            canShowCallout = true
            calloutOffset = CGPoint(x: -5, y: 5)
            let launchMapButton = UIButton(
                frame: CGRect(
                    origin: CGPoint(x: 0, y: 0),
                    size: CGSize(width: 40, height: 40)))
            launchMapButton.setImage(UIImage(named: "apple_maps_icon"), for: .normal)
            let addressLabel = UILabel()
            addressLabel.numberOfLines = 0
            addressLabel.font = addressLabel.font.withSize(12)
            addressLabel.text = annotaion.subtitle
            rightCalloutAccessoryView = launchMapButton
            markerTintColor = UIColor.byPriority(annotaion.priority)
        }
    }
}
