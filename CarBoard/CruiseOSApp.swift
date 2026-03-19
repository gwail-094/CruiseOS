//
//  CruiseOSApp.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 12.03.2026.
//

import SwiftUI

@main
struct CruiseOSApp: App {
    var body: some Scene {
        WindowGroup {
            // This is the "Boss" view that holds the Sidebar AND the Home Screen
            CarPlayRootView()
                .preferredColorScheme(.dark)
        }
    }
}
