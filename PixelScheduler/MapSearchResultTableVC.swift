//
//  MapSearchResultTableVC.swift
//  ScheduleManager
//
//  Created by Shin on 3/5/21.
//

import UIKit
import MapKit
import Combine

class MapSearchResultTableVC: UITableViewController {
    
    // MARK: Controllers
    private(set) var suggestionController: SuggestionTableVC!
    private var cellType: CellType = .suggestion
    var locationManager: CLLocationManager!
    
    // MARK:- Properties
    @Published private(set) var places: [MKMapItem]? {
        didSet{
            tableView.reloadData()
        }
    }
    @Published var isSearchSuccess: Bool?
    private var suggestionResult: [MKLocalSearchCompletion]?
    private var suggestionObserveCacellabe: AnyCancellable?
    
    var searchBar: UISearchBar!
    var currentPlacemark: CLPlacemark?
    @Published var boundingRegion: MKCoordinateRegion = MKCoordinateRegion(MKMapRect.world) {
        didSet{
            suggestionController.searchRegion = boundingRegion
        }
    }
    @Published private(set) var selectedPlacemark: MKPlacemark?
    private var localSearch: MKLocalSearch? {
        willSet {
            // Clear the results and cancel the currently running local search before starting a new search.
            places = nil
            localSearch?.cancel()
        }
    }
    /// - Parameter suggestedCompletion: A search completion provided by `MKLocalSearchCompleter` when tapping on a search completion table row
    private func search(for suggestedCompletion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: suggestedCompletion)
        search(using: searchRequest)
    }
    
    /// - Parameter queryString: A search string from the text the user entered into `UISearchBar`
    private func search(for queryString: String?) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = queryString
        search(using: searchRequest)
    }
    
    /// - Tag: SearchRequest
    private func search(using searchRequest: MKLocalSearch.Request) {
        // Confine the map search area to an area around the user's current location.
        searchRequest.region = boundingRegion
        
        // Include only point of interest results. This excludes results based on address matches.
        searchRequest.resultTypes = .pointOfInterest
        
        localSearch = MKLocalSearch(request: searchRequest)
        localSearch?.start { [self] (response, error) in
            guard error == nil else {
                print(error!.localizedDescription)
                isSearchSuccess = false
                return
            }
            
            places = response?.mapItems
            // Used when setting the map's region in `prepareForSegue`.
            if let updatedRegion = response?.boundingRegion {
                boundingRegion = updatedRegion
            }
            if places!.count == 1,
               let oneAndOnlyResult = places!.first{
                selectedPlacemark = oneAndOnlyResult.placemark
            }
            isSearchSuccess = !places!.isEmpty
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        suggestionController = SuggestionTableVC()
        suggestionController.tableView.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        definesPresentationContext = true
        tableView.register(SuggestedCompletionTableViewCell.self, forCellReuseIdentifier: SuggestedCompletionTableViewCell.reuseID)
        suggestionObserveCacellabe = suggestionController.$completerResults.sink { [self] in
            suggestionResult = $0
            if cellType == .suggestion {
                tableView.reloadData()
            }
        }
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways:
            fallthrough
        case .authorizedWhenInUse:
            locationManager.requestLocation()
        default:
            let alertController = UIAlertController(
                title: "위치 사용 제한",
                message: "현재 위치를 보기 위해서는 휴대폰의 설정에서 권한을 변경해 주세요",
                preferredStyle: .alert)
            let openSetting = UIAlertAction(
                title: "설정 열기",
                style: .default){_ in
                guard let settingURL = URL(string: UIApplication.openSettingsURLString) else { return }
                if UIApplication.shared.canOpenURL(settingURL) {
                    UIApplication.shared.open(settingURL) { isSueccess in
                        print(isSueccess ? "open setting" : "fail to open setting")
                    }
                }
            }
            let dismiss = UIAlertAction(
                title: "취소", style: .cancel)
            alertController.addAction(openSetting)
            alertController.addAction(dismiss)
            present(alertController, animated: true)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        suggestionController.startProvidingCompletions()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        suggestionController.stopProvidingCompletions()
    }
    
    enum CellReuseID: String {
        case resultCell
    }
}

// MARK:- UI TableView data source

extension MapSearchResultTableVC {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch cellType {
        case .searchResult:
            return places?.count ?? 0
        case .suggestion:
            return suggestionResult?.count ?? 0
        }
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch cellType {
        case .searchResult:
            return drawSearchResultCell(in: tableView, at: indexPath)
        case .suggestion:
            return drawSuggesionCell(in: tableView, at: indexPath)
        }
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var header = NSLocalizedString("SEARCH_RESULTS", comment: "Standard result text")
        if let city = currentPlacemark?.locality {
            let templateString = NSLocalizedString("SEARCH_RESULTS_LOCATION", comment: "Search result text with city")
            header = String(format: templateString, city)
        }
        return header
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        searchBar.resignFirstResponder()
        switch cellType {
        case .suggestion:
            if let suggestion = suggestionResult?[indexPath.row] {
                searchBar.text = suggestion.title
                search(for: suggestion)
                cellType = .searchResult
            }
        case .searchResult:
            if let place = places?[indexPath.row] {
                selectedPlacemark = place.placemark
            }
        }
    }
    
    private func drawSearchResultCell(in tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellReuseID.resultCell.rawValue, for: indexPath)
        if let mapItem = places?[indexPath.row] {
            cell.textLabel?.text = mapItem.name
            cell.detailTextLabel?.text = "\(mapItem.placemark.postalAddress?.street ?? ""), \(mapItem.placemark.subLocality ?? ""), \(mapItem.placemark.locality ?? "")"
               
        }
        return cell
    }
    private func drawSuggesionCell(in tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SuggestedCompletionTableViewCell.reuseID, for: indexPath)
        if let suggestion = suggestionResult?[indexPath.row]{
            // Each suggestion is a MKLocalSearchCompletion with a title, subtitle, and ranges describing what part of the title
            // and subtitle matched the current query string. The ranges can be used to apply helpful highlighting of the text in
            // the completion suggestion that matches the current query fragment.
            cell.textLabel?.attributedText =   createHighlightedString(text: suggestion.title, rangeValues: suggestion.titleHighlightRanges)
            cell.detailTextLabel?.attributedText =  createHighlightedString(text: suggestion.subtitle, rangeValues: suggestion.subtitleHighlightRanges)
        }
        return cell
    }
    
    private func createHighlightedString(text: String, rangeValues: [NSValue]) -> NSAttributedString {
        let attributes = [NSAttributedString.Key.backgroundColor: UIColor(named: "suggestionHighlight")! ]
        let highlightedString = NSMutableAttributedString(string: text)
        
        // Each `NSValue` wraps an `NSRange` that can be used as a style attribute's range with `NSAttributedString`.
        let ranges = rangeValues.map { $0.rangeValue }
        ranges.forEach { (range) in
            highlightedString.addAttributes(attributes, range: range)
        }
        
        return highlightedString
    }
    
    enum CellType {
        case suggestion
        case searchResult
    }
}
 
extension MapSearchResultTableVC: UISearchBarDelegate {

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        // The user tapped search on the `UISearchBar` or on the keyboard. Since they didn't
        // select a row with a suggested completion, run the search with the query text in the search field.
        cellType = .searchResult
        search(for: searchBar.text)
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearchSuccess = nil
        }
        cellType = .suggestion
        suggestionController.searchTextDidUpdate(to: searchText)
    }
}


private class SuggestedCompletionTableViewCell: UITableViewCell {
    
    static let reuseID = "SuggestedCompletionCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
