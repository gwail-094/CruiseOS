//
//  AppGridView.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 12.03.2026.
//


import SwiftUI

@MainActor
struct AppGridView: View {
    @Bindable var nav: CarPlayNavigation
    
    private let columns = [
        GridItem(.adaptive(minimum: 110, maximum: 130), spacing: 25)
    ]
    
    var body: some View {
        ZStack(alignment: .leading) {
            FloatingSidebar(nav: nav)
                .padding(.leading, 12)
                .zIndex(1)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Apps")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.bottom, 10)
                    
                    LazyVGrid(columns: columns, spacing: 30) {
                        // 1. THE SETTINGS APP
                        AppIcon(
                            name: "Settings",
                            icon: "gearshape.fill",
                            imageName: "settings_icon", // Uses your PNG
                            action: {
                                withAnimation { nav.currentView = "settings" }
                            }
                        )
                        
                        // 2. THE MUSIC APP
                        AppIcon(
                            name: "Music",
                            icon: "music.note",
                            imageName: "music_icon", // Assumed asset name
                            action: {
                                withAnimation { nav.currentView = "music" }
                            }
                        )

                        // 3. THE CALENDAR APP
                        AppIcon(
                            name: "Calendar",
                            icon: "calendar",
                            imageName: nil,
                            action: {
                                withAnimation { nav.currentView = "calendar" }
                            }
                        )
                        
                        // 4. PLACEHOLDERS (Starting from 4 now)
                        ForEach(4...16, id: \.self) { i in
                            AppIcon(
                                name: "App \(i)",
                                icon: "app.dashed",
                                imageName: nil,
                                action: { print("Tapped app \(i)") }
                            )
                        }
                    }
                }
                .padding(40)
                .padding(.leading, 110)
            }
            .scrollIndicators(.hidden)
        }
    }
}

struct AppIcon: View {
    let name: String
    let icon: String
    let imageName: String? // New property for assets
    let action: () -> Void // Added action for tapping

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 100, height: 100)
                    
                    if let img = imageName {
                        Image(img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                }
                
                Text(name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(PlainButtonStyle()) // Prevents the whole VStack from dimming weirdly
    }
}
