//
//  LanguagePickerView.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 14.03.2026.
//

import SwiftUI

struct LanguagePickerView: View {
    @Bindable var nav: CarPlayNavigation
    
    // Tunable Mask Settings
    private let topClearLimit: Double = 0.05
    private let topOpaqueLimit: Double = 0.20
    private let bottomFadeStart: Double = 0.85
    
    // Available Languages
    private let languages: [AppLanguage] = [
        .init(id: "en", name: "English", nativeName: "English"),
        .init(id: "de", name: "German", nativeName: "Deutsch")
    ]
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black.ignoresSafeArea()
            
            // --- MAIN CONTENT ---
            ZStack(alignment: .topLeading) {
                
                // 1. SCROLLABLE LIST WITH MASK
                ScrollView {
                    VStack(spacing: 12) {
                        // Top Spacer: Ensures first row starts below the pinned header
                        Color.clear.frame(height: 110)
                        
                        ForEach(languages) { lang in
                            LanguageRow(
                                language: lang,
                                isSelected: nav.languageIdentifier == lang.id
                            ) {
                                withAnimation {
                                    nav.languageIdentifier = lang.id
                                }
                            }
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
                HStack(spacing: 15) {
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
                    
                    Text("language")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 30) // Align leading with home button
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
    }
}

struct AppLanguage: Identifiable {
    let id: String
    let name: String
    let nativeName: String
}

struct LanguageRow: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.nativeName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                    Text(language.name)
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 25)
            .padding(.trailing, 40) // Avoid Dynamic Island
            .frame(height: 80)
            .background(Color(white: 0.15))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
