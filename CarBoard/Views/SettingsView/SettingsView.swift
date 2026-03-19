//
//  SettingsView.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 13.03.2026.
//

import SwiftUI

struct SettingsView: View {
    @Bindable var nav: CarPlayNavigation
    
    // Tunable Mask Settings from your Maps sidebar
    private let topClearLimit: Double = 0.05
    private let topOpaqueLimit: Double = 0.20
    private let bottomFadeStart: Double = 0.85
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // --- MAIN CONTENT ---
            ZStack(alignment: .topLeading) {
                
                // 1. SCROLLABLE LIST WITH MASK
                ScrollView {
                    VStack(spacing: 8) {
                        // Top Spacer: Ensures first row starts below the pinned header
                        Color.clear.frame(height: 110)
                        
                        SettingsRow(
                            title: "wallpaper",
                            iconAsset: "wallpaper_settings",
                            action: {
                                // Wired: This tells the Root Container to switch to the WallpaperView
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    nav.currentView = "wallpaper"
                                }
                            }
                        )
                        
                        SettingsRow(
                            title: "language",
                            iconAsset: "language_settings",
                            action: {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    nav.currentView = "language_picker"
                                }
                            }
                        )
                        
                        // Add more rows here as needed
                        ForEach(1..<10, id: \.self) { i in
                             SettingsRow(title: "Option \(i)", iconAsset: "wallpaper_settings") { }
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 120) // Space for home button
                }
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .clear, location: topClearLimit),
                            .init(color: .black, location: topOpaqueLimit),
                            .init(color: .black, location: bottomFadeStart),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

                // 2. PINNED HEADER (Stays on top)
                Text("settings")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.top, 30)
            }
            
            // --- FIXED HOME BUTTON ---
            Button(action: {
                withAnimation { nav.currentView = "home" }
            }) {
                if #available(iOS 26.0, *) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                        .frame(width: 75, height: 75)
                        .glassEffect(.clear)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                } else {
                    // Fallback on earlier versions
                }
            }
            .padding(.leading, 30)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Subviews
struct SettingsRow: View {
    let title: String
    let iconAsset: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(iconAsset)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 45, height: 45)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Text(LocalizedStringKey(title))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.gray)
            }
            .padding(.leading, 20)
            .padding(.trailing, 40)
            .frame(height: 85)
            .background(Color(white: 0.15))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.trailing, 20)
    }
}
