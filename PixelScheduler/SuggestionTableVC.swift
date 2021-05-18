//
//  SuggestionTableVC.swift
//  ScheduleManager
//
//  Created by Shin on 3/5/21.
//

import UIKit
import MapKit

class SuggestionTableVC: UITableViewController {
    
    private var searchCompleter: MKLocalSearchCompleter?
    var searchRegion: MKCoordinateRegion = MKCoordinateRegion(MKMapRect.world)
    private var currentPlacemark: CLPlacemark?
    
    @Published var completerResults: [MKLocalSearchCompletion]?
    
    func searchTextDidUpdate(to text: String?) {
        searchCompleter?.queryFragment = text ?? ""
    }
    
    func updatePlacemark(_ placemark: CLPlacemark?, boundingRegion: MKCoordinateRegion) {
        currentPlacemark = placemark
        searchCompleter?.region = searchRegion
    }
    func startProvidingCompletions() {
        searchCompleter = MKLocalSearchCompleter()
        searchCompleter?.delegate = self
        searchCompleter?.resultTypes = .pointOfInterest
        searchCompleter?.region = searchRegion

    }
    
    func stopProvidingCompletions() {
        searchCompleter = nil
    }
    init() {
        super.init(style: .grouped)
       
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK:- Search completer delegate
extension SuggestionTableVC: MKLocalSearchCompleterDelegate {
    
    /// - Tag: QueryResults
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completerResults = completer.results
    }
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Handle any errors returned from MKLocalSearchCompleter.
        if let error = error as NSError? {
            print("MKLocalSearchCompleter encountered an error: \(error.localizedDescription). The query fragment is: \"\(completer.queryFragment)\"")
        }
    }
}

