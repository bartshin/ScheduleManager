//
//  LocationSelector.swift
//  ScheduleManager
//
//  Created by Shin on 3/4/21.
//

import UIKit
import MapKit
import Combine

class LocationSelectorVC: UIViewController {
    
    // MARK: Controllers
    private var locationManager = CLLocationManager()
    var modelController: ScheduleModelController!
    var settingController: SettingController!
    private var searchResultTableVC: SearchResultTableVC!
    
    // MARK:- Properties
    
    @IBOutlet private weak var mapView: MKMapView!
    @Published private(set) var presentingAnnotation: ScheduleAnnotaion? {
        didSet {
            mapView.removeAnnotations(mapView.annotations)
            if presentingAnnotation != nil {
                mapView.addAnnotation(presentingAnnotation!)
                mapView.centerToLocation(
                    CLLocation(latitude: presentingAnnotation!.coordinate.latitude,
                               longitude:
                                presentingAnnotation!.coordinate.longitude))
            }
        }
    }
    @IBOutlet weak var emptySearchResultLabel: UILabel!
    @IBOutlet private weak var loadingSpinner: UIActivityIndicatorView!
    @IBOutlet weak var searchBar: UISearchBar!
    private var sesarchResultObserveCancellable: AnyCancellable?
    private var searchLocationObserveCancellable: AnyCancellable?
    var locationTitle: String?
    var priority = 3
    
    // MARK:- User intents
    @IBAction private func tapBackButton(_ sender: UIButton) {
        presentingAnnotation = nil
        dismiss(animated: true)
    }
    @IBAction func tapAddButton(_ sender: UIButton) {
        dismiss(animated: true)
    }
    @objc private func longPressMapView(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let title = (locationTitle != nil && !locationTitle!.isEmpty) ? locationTitle! :
                "User pinned"
            let coordinates = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
            presentingAnnotation = ScheduleAnnotaion(
                title: title,
                address: "(\(coordinates.latitude), \(coordinates.longitude)",
                priority: priority, coordinate: coordinates)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        locationManager.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initMapView()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyColorScheme(settingController.visualMode)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let navigationVC = presentingViewController as? UINavigationController,
           let editScheduleVC = navigationVC.viewControllers.last as? EditScheduleVC{
            if presentingAnnotation != nil {
                editScheduleVC.locationState = .on(annotation: presentingAnnotation!)
            }
        }
    }
    
    private func initMapView() {
        mapView.delegate = self
        mapView.register(ScheduleMarkerView.self, forAnnotationViewWithReuseIdentifier: ScheduleMarkerView.reuseID)
        mapView.addGestureRecognizer(
            UILongPressGestureRecognizer(
                target: self, action: #selector(longPressMapView)))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueID.SearchResult.rawValue,
           let searchResultTableVC = segue.destination as? SearchResultTableVC{
            searchResultTableVC.locationManager = locationManager
            self.searchResultTableVC = searchResultTableVC
            searchResultTableVC.searchBar = searchBar
            searchBar.delegate = searchResultTableVC
            sesarchResultObserveCancellable = searchResultTableVC.$isSearchSuccess.sink{ [weak weakSelf = self] isSuccess in
                weakSelf?.emptySearchResultLabel.isHidden = isSuccess ?? true
            }
            searchLocationObserveCancellable = searchResultTableVC.$selectedPlacemark.sink { [weak weakSelf = self] in
                if $0 != nil {
                    weakSelf?.presentingAnnotation = ScheduleAnnotaion(
                        title: $0!.name,
                        address: "\($0!.postalAddress?.street ?? ""), \($0!.subLocality ?? ""), \($0!.locality ?? "")",
                        priority: weakSelf?.priority ?? 3, coordinate: $0!.coordinate)
                }
            }
        }
    }
    
    enum SegueID: String {
        case SearchResult
    }
}

// MARK:- Map view delegate
extension LocationSelectorVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        if let deqeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: ScheduleMarkerView.reuseID) as? ScheduleMarkerView{
            deqeuedView.annotation = annotation
            return deqeuedView
        }else {
            return ScheduleMarkerView(annotation: annotation, reuseIdentifier: ScheduleMarkerView.reuseID)
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotaion = view.annotation as? ScheduleAnnotaion else { return }
        
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        annotaion.mapItem?.openInMaps(launchOptions: launchOptions)
    }
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        loadingSpinner.isHidden = false
    }
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        loadingSpinner.isHidden = true
    }
}

// MARK:- Location handling
extension LocationSelectorVC: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways ||
            manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else { return }
        mapView.centerToLocation(location, regionRadius: 500)
        mapView.showsUserLocation = true
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [self] placemark, error in
            guard error == nil else {
                print("geocoder error: \(error!.localizedDescription)")
                return }
            searchResultTableVC.currentPlacemark = placemark?.first
            let boundingRegion = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 12_000,
                longitudinalMeters: 12_000)
            searchResultTableVC.boundingRegion = boundingRegion
            searchResultTableVC.suggestionController.updatePlacemark(
                placemark?.first,
                boundingRegion: boundingRegion)
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
