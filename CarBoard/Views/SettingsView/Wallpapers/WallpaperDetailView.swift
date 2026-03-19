//
//  WallpaperDetailView.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 13.03.2026.
//


import SwiftUI

struct WallpaperDetailView: View {
    @Bindable var nav: CarPlayNavigation
    
    @State private var isDark = false
    
    private var currentImageName: String {
        "\(nav.previewWallpaperBase)_\(isDark ? "dark" : "bright")"
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1. THE ACTUAL WALLPAPER (Background)
                Image(currentImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .id(currentImageName)
                
                // 2. APPS OVERLAY (Centered Preview)
                // We scale this to 70% of screen height to leave room for buttons
                Image("apps_overlay")
                    .resizable()
                    .scaledToFit()
                    .frame(height: geo.size.height * 0.7)
                    .allowsHitTesting(false)
                    .padding(.bottom, 60) // Lift it up away from the pills

                // 3. UI LAYER
                VStack {
                    // TOP BAR
                    HStack {
                        Button(action: {
                            withAnimation { nav.currentView = "wallpaper" }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 75, height: 75)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                        }
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.leading, 30) // Align with home button leading

                    Spacer()

                    // BOTTOM BAR
                    HStack(alignment: .bottom, spacing: 12) {
                        // Home Button
                        Button(action: {
                            withAnimation { nav.currentView = "home" }
                        }) {
                            Image(systemName: "square.grid.3x3.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                                .frame(width: 75, height: 75)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                        }
                        
                        // PILL BUTTONS
                        HStack(spacing: 10) {
                            pillButton(title: "Set", width: geo.size.width * 0.22) {
                                nav.selectedWallpaper = currentImageName
                                withAnimation { nav.currentView = "home" }
                            }
                            
                            pillButton(title: "Cancel", width: geo.size.width * 0.22) {
                                withAnimation { nav.currentView = "wallpaper" }
                            }
                            
                            pillButton(title: "Appearance", width: geo.size.width * 0.22) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    isDark.toggle()
                                }
                            }
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(Color.black)
    }

    // Updated Pill with flexible width based on screen size
    private func pillButton(title: String, width: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(LocalizedStringKey(title.lowercased()))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: width, height: 65)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
        }
    }
}

