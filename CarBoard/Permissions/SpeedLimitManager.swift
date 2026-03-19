//
//  SpeedLimitManager.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 14.03.2026.
//

import Foundation
import CoreLocation
import Observation
import SwiftUI

@MainActor
@Observable
class SpeedLimitManager {
    var currentLimit: Int? = nil
    var region: String = "eu" // "eu" or "us"
    
    private var lastQueryLocation: CLLocation?
    private var lastQueryTime: Date = .distantPast
    private var isFetching = false
    
    // Simple Cache to avoid redundant requests for same road/area
    private var speedLimitCache: [String: (limit: Int, region: String, timestamp: Date)] = [:]

    func updateSpeedLimit(for location: CLLocation) {
        let distanceMoved = lastQueryLocation?.distance(from: location) ?? 999
        let timeElapsed = Date().timeIntervalSince(lastQueryTime)
        
        // Throttling: 50 meters or 5 seconds for more frequent checks
        guard !isFetching && (distanceMoved > 50 || timeElapsed > 5) else { return }
        
        // Caching check: use a 3-decimal lat/lon string to represent ~110m "buckets"
        let latKey = String(format: "%.3f", location.coordinate.latitude)
        let lonKey = String(format: "%.3f", location.coordinate.longitude)
        let cacheKey = "\(latKey)_\(lonKey)"
        
        if let cached = speedLimitCache[cacheKey], Date().timeIntervalSince(cached.timestamp) < 300 {
            withAnimation(.spring()) {
                self.currentLimit = cached.limit
                self.region = cached.region
            }
            return
        }

        lastQueryLocation = location
        lastQueryTime = Date()
        
        Task {
            // "Lookahead" - we could also fetch slightly ahead in the car's heading 
            // but for now, we focus on making the current fetch as fast as possible.
            await fetchFromNominatim(location: location, cacheKey: cacheKey)
        }
    }
    
    private func fetchFromNominatim(location: CLLocation, cacheKey: String) async {
        isFetching = true
        defer { isFetching = false }
        
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        
        // zoom=18 targets the specific road segment
        let urlString = "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=\(lat)&lon=\(lon)&extratags=1&zoom=18"
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("CruiseOSApp/1.0 (ardit@sejdiu.me)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                return
            }
            
            let result = try JSONDecoder().decode(NominatimResponse.self, from: data)
            
            // 1. Detect Region from Country Code
            var newRegion = self.region
            if let countryCode = result.address?["country_code"]?.lowercased() {
                newRegion = (countryCode == "us") ? "us" : "eu"
            }
            
            // 2. Extract Speed Limit
            if let maxSpeedString = result.extratags?["maxspeed"] {
                let digits = maxSpeedString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                if let speedInt = Int(digits) {
                    // Update Cache
                    speedLimitCache[cacheKey] = (speedInt, newRegion, Date())
                    
                    withAnimation(.spring()) {
                        self.currentLimit = speedInt
                        self.region = newRegion
                    }
                }
            }
        } catch {
            print("Speed Limit API Error: \(error)")
        }
    }
}

// MARK: - Nominatim Models
struct NominatimResponse: Codable {
    let extratags: [String: String]?
    let address: [String: String]?
}
