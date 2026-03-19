//
//  AppleMapsSidebar.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 12.03.2026.

import MapKit
import SwiftUI

struct AppleMapsSidebar: View {
    @Bindable var nav: CarPlayNavigation
    
    var onSearchTap: () -> Void
    var onSelectPlace: (PinnedPlace) -> Void
    var onClose: () -> Void
    
    // Tunable Mask Settings
    private let topClearLimit: Double = 0.15
    private let topOpaqueLimit: Double = 0.35
    private let bottomFadeStart: Double = 0.85
    private let panelWidth: CGFloat = 650
    private let panelHeight: CGFloat = 340
    
    var body: some View {
        ZStack(alignment: .top) {
            // Scrolling Columns
            HStack(spacing: 15) {
                scrollColumn(title: "pinned", items: nav.pinnedPlaces)
                scrollColumn(title: "recents", items: nav.recentPlaces, isRecent: true)
            }
            .padding(.horizontal, 20)
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
            
            // Floating Header
            headerArea.padding(.top, 5)
        }
        .frame(width: panelWidth, height: panelHeight)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
    
    private var headerArea: some View {
        HStack(spacing: 15) {
            // Search Capsule (Now fills full width minus the ellipsis)
            Button(action: onSearchTap) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass").font(.system(size: 18, weight: .bold))
                    Text("search").font(.system(size: 18, weight: .semibold, design: .rounded))
                    Spacer()
                }
                .padding(.horizontal, 22)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(Capsule().fill(Color.black.opacity(0.35)))
                .overlay(Capsule().stroke(.white.opacity(0.05), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            
            // --- NEW ELLIPSIS MENU ---
            Menu {
                Button(action: { /* Placeholder for Share */ }) {
                    Label("share_location", systemImage: "square.and.arrow.up")
                }
                
                Button(action: { 
                    // Open search to find a place to pin
                    onSearchTap()
                }) {
                    Label("add_pinned_place", systemImage: "mappin.and.ellipse")
                }
                
                Divider()
                
                Button(role: .destructive, action: { /* Placeholder for Clear */ }) {
                    Label("clear_recents", systemImage: "trash")
                }
            } label: {
                // This is the floating ellipsis button
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.black.opacity(0.35)))
                    .overlay(Circle().stroke(.white.opacity(0.05), lineWidth: 0.5))
            }
            .menuStyle(.button) // Ensures it behaves like a tap-trigger
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .foregroundStyle(.primary)
    }
    
    private func scrollColumn(title: String, items: [PinnedPlace], isRecent: Bool = false) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                Color.clear.frame(height: 100)
                
                HStack(spacing: 4) {
                    Text(LocalizedStringKey(title))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, 10)
                
                if items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: isRecent ? "clock.arrow.circlepath" : "mappin.and.ellipse")
                            .font(.system(size: 30))
                            .foregroundStyle(.secondary)
                        
                        Text(isRecent ? "" : "pinned_empty_state")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                } else {
                    ForEach(items) { item in 
                        locationRow(item: item, isRecent: isRecent)
                            .onTapGesture {
                                onSelectPlace(item)
                            }
                    }
                }
                
                Color.clear.frame(height: 50)
            }
        }
    }
    
    private func locationRow(item: PinnedPlace, isRecent: Bool = false) -> some View {
        HStack(spacing: 15) {
            Circle().fill(isRecent ? AnyShapeStyle(Color.gray.opacity(0.25)) : AnyShapeStyle(item.iconColor.gradient))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: isRecent ? item.icon : item.icon).font(.system(size: 16, weight: .bold)).foregroundStyle(.white))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title).font(.system(size: 17, weight: .bold))
                Text(item.subtitle).font(.system(size: 13)).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 15).frame(height: 78).background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.08)))
        .contentShape(Rectangle()) // Makes the whole row tappable
    }

    private func headerButton(icon: String) -> some View {
        Image(systemName: icon).font(.system(size: 20, weight: .bold))
            .frame(width: 56, height: 56).background(Circle().fill(Color.black.opacity(0.35)))
            .overlay(Circle().stroke(.white.opacity(0.05), lineWidth: 0.5))
    }
}
