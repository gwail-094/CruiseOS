//
//  SearchManager.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 12.03.2026.
//

import Foundation
import MapKit
import Combine
import Observation

@Observable
class SearchManager {
    // This handles the typing from the UI
    var searchQuery: String = "" {
        didSet {
            // Every time the UI updates searchQuery, we push it into the subject
            searchQuerySubject.send(searchQuery)
        }
    }
    
    private let searchQuerySubject = CurrentValueSubject<String, Never>("")
    var results: [MKMapItem] = []
    private var cancellable: AnyCancellable?
    
    init() {
        cancellable = searchQuerySubject
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .removeDuplicates() // Only search if the text actually changed
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            self.results = []
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print("Search error: \(error.localizedDescription)")
                return
            }
            // Update the results on the main thread
            Task { @MainActor in
                self.results = response?.mapItems ?? []
            }
        }
    }
}
