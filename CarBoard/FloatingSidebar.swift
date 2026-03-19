//
//  FloatingSidebar.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 12.03.2026.
//

import SwiftUI
import Combine

struct FloatingSidebar: View {
    @Bindable var nav: CarPlayNavigation
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // 1. TOP STATUS
            VStack(spacing: 4) {
                Text(currentTime, format: .dateTime.hour().minute())
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                Image(systemName: nav.networkManager.cellularIcon, variableValue: nav.networkManager.signalValue)
                    .font(.system(size: 18))
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(.top, 24)
            
            Spacer()

            // 2. THE GRID BUTTON
            Button(action: { toggleView() }) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 24))
                // Change color if we are actively in the grid
                    .foregroundColor(nav.currentView == "grid" ? .blue : .primary)
            }
            .frame(width: 80, height: 80)
            .padding(.bottom, 15)
        }
        .frame(width: 80)
        // This gives it the "full length" floating pill look
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 35, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .padding(.vertical, 15)
        .onReceive(timer) { currentTime = $0 }
    }
    
    private func toggleView() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if nav.currentView == "grid" {
                // If we're already on the grid, go back to home
                nav.currentView = "home"
            } else {
                // Otherwise, open the grid
                nav.currentView = "grid"
            }
        }
    }
}

