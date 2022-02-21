//
//  ScheduleAnnotaion.swift
//  PixelScheduler
//
//  Created by Shin on 3/2/21.
//

import MapKit
import Contacts


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
