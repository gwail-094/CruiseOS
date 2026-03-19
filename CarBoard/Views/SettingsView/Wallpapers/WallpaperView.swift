//
//  WallpaperView.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 13.03.2026.
//

import SwiftUI

struct WallpaperView: View {
    @Bindable var nav: CarPlayNavigation
    
    // Tunable Mask Settings
    private let topClearLimit: Double = 0.05
    private let topOpaqueLimit: Double = 0.20
    private let bottomFadeStart: Double = 0.85
    
    // Your wallpaper assets
    private let wallpapers = ["bg1_select", "bg2_select", "bg3_select", "bg4_select"]
    
    // Flexible 2-column grid that fits any screen width
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            
            // --- MAIN CONTENT ---
            ZStack(alignment: .topLeading) {
                
                // 1. REGULAR VERTICAL SCROLL
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header Spacer
                        Color.clear.frame(height: 120)
                        
                        LazyVGrid(columns: columns, spacing: 30) {
                            ForEach(wallpapers, id: \.self) { wallpaper in
                                Button(action: {
                                    withAnimation {
                                        nav.previewWallpaperBase = wallpaper.replacingOccurrences(of: "_select", with: "")
                                        nav.currentView = "wallpaper_detail"
                                        print("Selected \(wallpaper)")
                                    }
                                }) {
                                    VStack(spacing: 0) {
                                        Image(wallpaper)
                                            .resizable()
                                            // .fit = NO SCALING/CROPPING. Whole image is visible.
                                            .aspectRatio(contentMode: .fit)
                                            .background(Color.black.opacity(0.2)) // Fills empty space if aspect differs
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(.white.opacity(0.15), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.leading, 80) // Added padding so it doesn't hide behind sidebar
                        
                        // Bottom Spacer
                        Color.clear.frame(height: 120)
                    }
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

                // 2. PINNED HEADER AREA
                HStack(spacing: 20) {
                    Button(action: {
                        withAnimation { nav.currentView = "settings" }
                    }) {
                        if #available(iOS 26.0, *) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 75, height: 75)
                                .glassEffect(.clear)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                    
                    Text("wallpaper")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 30)
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
            .zIndex(10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
