//
//  NavigationBanner.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 12.03.2026.
//

import SwiftUI
import MapKit

struct NavigationBanner: View {
    var instruction: String
    var nextInstruction: String?
    var distance: CLLocationDistance
    var isRerouting: Bool
    var onCancel: () -> Void

    var body: some View {
        let showFooter = nextInstruction != nil && !isRerouting
        
        VStack(spacing: 0) {
            // 1. MAIN BANNER (Current Instruction)
            HStack(spacing: 20) {
                // ICON SLOT
                if !isRerouting {
                    Image(iconFor(instruction: instruction))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if isRerouting {
                        HStack(spacing: 15) {
                            ProgressView()
                                .tint(.white)
                            Text("Recalculating...")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                        }
                    } else {
                        Text(instruction)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 25)
            .padding(.vertical, 18)
            .background(.thickMaterial)
            .clipShape(
                .rect(
                    topLeadingRadius: 30,
                    bottomLeadingRadius: showFooter ? 0 : 30,
                    bottomTrailingRadius: showFooter ? 0 : 30,
                    topTrailingRadius: 30
                )
            )
            
            // 2. FOOTER (Next Instruction)
            if showFooter, let next = nextInstruction {
                HStack(spacing: 15) {
                    Image(iconFor(instruction: next))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundStyle(.white.opacity(0.8))

                    Text(next)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(
                    .rect(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 30,
                        bottomTrailingRadius: 30,
                        topTrailingRadius: 0
                    )
                )
            }
        }
        .frame(width: 380)
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}
