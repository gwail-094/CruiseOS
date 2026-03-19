//
//  MapModels.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 12.03.2026.
//


import Foundation
import MapKit
import SwiftUI

// --- DATA STRUCTURES ---

/// Represents a location saved by the user, like Home or Work.
struct PinnedPlace: Identifiable, Codable {
    var id = UUID()
    let icon: String
    let iconColorHex: String // Store color as hex for Codable
    let title: String
    let subtitle: String
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var iconColor: Color {
        Color(hex: iconColorHex) ?? .blue
    }
    
    init(id: UUID = UUID(), icon: String, iconColor: Color, title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.icon = icon
        self.iconColorHex = icon.toHex() // Placeholder logic, better to use a proper Color extension
        self.title = title
        self.subtitle = subtitle
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    // Improved init for proper hex support
    init(id: UUID = UUID(), icon: String, hexColor: String, title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.icon = icon
        self.iconColorHex = hexColor
        self.title = title
        self.subtitle = subtitle
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}

/// Represents a specific path calculated by MapKit.
struct RouteOption: Identifiable {
    let id = UUID()
    let route: MKRoute
    let isFastest: Bool
}

/// Represents a quick-search category like "Cafes" or "Gas".
struct SearchCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let query: String
}

// --- GLOBAL DATA ---

/// The list of categories displayed in the Search Sidebar.
let quickCategories: [SearchCategory] = [
    .init(name: "Cafes", icon: "cup.and.saucer.fill", color: .orange, query: "cafe"),
    .init(name: "Grocery Stores", icon: "cart.fill", color: .yellow, query: "grocery store"),
    .init(name: "Gas Stations", icon: "fuelpump.fill", color: .blue, query: "gas station"),
    .init(name: "Parks", icon: "leaf.fill", color: .green, query: "park")
]

// MARK: - Extensions for Codable Color support
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}

extension String {
    func toHex() -> String {
        // Simple mapping for common colors or a default
        return "#007AFF" // Default Apple Blue
    }
}
