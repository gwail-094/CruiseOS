//
//  SearchRoutePreview.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 12.03.2026.
//

import SwiftUI
import MapKit

struct SearchRoutePreview: View {
    @Bindable var nav: CarPlayNavigation
    let item: MKMapItem
    @Binding var routes: [RouteOption]
    @Binding var selectedRoute: MKRoute?
    let isCalculating: Bool
    @Binding var isNavigating: Bool
    var onBack: () -> Void

    // --- UPDATED UI SETTINGS ---
    private let panelWidth: CGFloat = 325
    private let panelHeight: CGFloat = 340

    var body: some View {
        VStack(spacing: 0) {
            // --- HEADER (Static) ---
            headerArea
            
            // --- BUTTON STACK (Non-Scrollable) ---
            VStack(spacing: 15) {
                if isCalculating {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    Spacer()
                } else if let fastest = routes.first(where: { $0.isFastest }) ?? routes.first {
                    
                    // 1. FASTEST ROUTE (The Blue Pill)
                    Button(action: {
                        withAnimation(.spring()) {
                            isNavigating = true
                        }
                    }) {
                        HStack(spacing: 15) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 24, weight: .bold))
                            
                            Text("\(Int(fastest.route.expectedTravelTime / 60)) min")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 65)
                        .background(Color.blue.gradient)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    // 2. OTHER ROUTES
                    Button(action: { /* Logic for other routes */ }) {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 20, weight: .bold))
                            
                            Text("other_routes")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 65)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    // 3. SHARE & PIN (Horizontal Row)
                    HStack(spacing: 12) {
                        // SHARE
                        Button(action: { /* Trigger Share Sheet Logic */ }) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 20, weight: .bold))
                                
                                Text("share")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 65)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        
                        // PIN (The smaller round-ish button)
                        Button(action: { 
                            withAnimation {
                                nav.pinLocation(item)
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 65, height: 65)
                                
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 10) // Push buttons lower
            .padding(.horizontal, 20)
            .padding(.bottom, 25)
        }
        .frame(width: panelWidth, height: panelHeight)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Sub-Layouts

    private var headerArea: some View {
        HStack(spacing: 12) {
            // Back Button
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.black.opacity(0.35)))
                    .overlay(Circle().stroke(.white.opacity(0.05), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            
            // Destination Label
            Text(item.name?.uppercased() ?? "DESTINATION")
                .font(.system(size: 20, weight: .bold, design: .rounded)) // Larger Font
                .foregroundStyle(.white)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10) // Push higher
        .padding(.bottom, 5)
    }
}
