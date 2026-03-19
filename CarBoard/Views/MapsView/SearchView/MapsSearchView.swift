//
//  MapsSearchView.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 12.03.2026.
//


import SwiftUI
import MapKit

struct MapsSearchView: View {
    @Bindable var searchManager: SearchManager
    var onSelect: (MKMapItem) -> Void
    var onCancel: () -> Void
    
    @FocusState private var isFocused: Bool

    // Tunable UI Settings
    private let topClearLimit: Double = 0.15
    private let topOpaqueLimit: Double = 0.35
    private let bottomFadeStart: Double = 0.85
    private let panelWidth: CGFloat = 650
    private let panelHeight: CGFloat = 340

    var body: some View {
        ZStack(alignment: .top) {
            // --- 1. THE UNIFIED SCROLLING LAYER ---
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15) {
                    Color.clear.frame(height: 100) // Top mask spacer

                    if searchManager.searchQuery.isEmpty {
                        // --- CATEGORY GRID VIEW ---
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach(quickCategories) { category in
                                categoryButton(category)
                            }
                        }
                    } else if searchManager.results.isEmpty {
                        ContentUnavailableView.search(text: searchManager.searchQuery)
                            .opacity(0.5)
                    } else {
                        // --- SEARCH RESULTS LIST ---
                        VStack(spacing: 12) {
                            ForEach(searchManager.results, id: \.self) { item in
                                searchResultRow(item: item)
                            }
                        }
                    }
                    
                    Color.clear.frame(height: 50) // Bottom mask spacer
                }
                .padding(.horizontal, 20)
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

            // --- 2. FLOATING HEADER ---
            headerArea.padding(.top, 5)
        }
        .frame(width: panelWidth, height: panelHeight)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.white.opacity(0.1), lineWidth: 1))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { isFocused = true }
        }
    }

    // MARK: - Sub-Layouts

    private var headerArea: some View {
        HStack(spacing: 15) {
            Button(action: onCancel) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.black.opacity(0.35)))
                    .overlay(Circle().stroke(.white.opacity(0.05), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass").font(.system(size: 18, weight: .bold)).foregroundStyle(.secondary)
                TextField("Search for a place...", text: $searchManager.searchQuery)
                    .focused($isFocused)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .submitLabel(.search)
            }
            .padding(.horizontal, 22).frame(maxWidth: .infinity).frame(height: 56)
            .background(Capsule().fill(Color.black.opacity(0.35)))
            .overlay(Capsule().stroke(.white.opacity(0.05), lineWidth: 0.5))
        }
        .padding(.horizontal, 20).padding(.vertical, 15).foregroundStyle(.primary)
    }

    private func categoryButton(_ category: SearchCategory) -> some View {
        Button(action: {
            searchManager.searchQuery = category.name
            // Logic to trigger immediate map search goes here
        }) {
            HStack(spacing: 15) {
                Circle()
                    .fill(category.color.gradient)
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: category.icon).font(.system(size: 18, weight: .bold)).foregroundStyle(.white))
                
                Text(category.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
            }
            .padding(.horizontal, 15)
            .frame(height: 85) // Same height as your reference
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }

    private func searchResultRow(item: MKMapItem) -> some View {
        Button(action: { onSelect(item) }) {
            HStack(spacing: 15) {
                Circle().fill(Color.blue.gradient).frame(width: 44, height: 44)
                    .overlay(Image(systemName: "mappin.and.ellipse").font(.system(size: 16, weight: .bold)).foregroundStyle(.white))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name ?? "Unknown").font(.system(size: 17, weight: .bold))
                    Text(item.placemark.title ?? "").font(.system(size: 13)).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 15).frame(height: 78).background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }
}
