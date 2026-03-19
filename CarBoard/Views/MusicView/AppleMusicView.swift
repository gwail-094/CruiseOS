//
//  AppleMusicView.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 13.03.2026.
//

import SwiftUI
import MusicKit

@MainActor
@Observable
class AppleMusicManager {
    var libraryAlbums: MusicItemCollection<Album> = []
    // MusicKit doesn't have a "pinned" property, so we'll treat 'isFavorite' albums as Pinned
    var pinnedAlbums: [Album] = []
    var isAuthorized = false
    var isLoading = false
    
    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        self.isAuthorized = (status == .authorized)
        if isAuthorized {
            await fetchLibrary()
        }
    }
    
    func fetchLibrary() async {
        guard isAuthorized else { return }
        isLoading = true
        do {
            let request = MusicLibraryRequest<Album>()
            let response = try await request.response()
            
            self.libraryAlbums = response.items
            
            // FIX: Instead of isFavorite, we take the 6 most recently added albums
            // to serve as your "Pinned" section.
            self.pinnedAlbums = Array(response.items.prefix(6))
            
        } catch {
            print("MusicKit library fetch error: \(error)")
        }
        isLoading = false
    }
}

@MainActor
struct AppleMusicView: View {
    @Bindable var nav: CarPlayNavigation
    @State private var musicManager = AppleMusicManager()

    // 4-column grid to match the proportions in your screenshot
    let columns = [
        GridItem(.adaptive(minimum: 220), spacing: 25)
    ]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // --- 1. HEADER ---
                Text("Library")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.top, 30)
                    .padding(.bottom, 10)

                // --- 2. MAIN SCROLL AREA ---
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 40) {
                        
                        // --- PINNED ROW (Top 6) ---
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(musicManager.pinnedAlbums) { album in
                                    PinnedAlbumCard(album: album)
                                }
                            }
                            .padding(.horizontal, 40)
                        }

                        // --- MAIN LIBRARY GRID ---
                        LazyVGrid(columns: columns, spacing: 40) {
                            ForEach(musicManager.libraryAlbums) { album in
                                LibraryAlbumCard(album: album)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 120) // Spacing for the Home Button
                    }
                    .padding(.top, 10)
                }
            }

            // --- 3. HOME BUTTON (Consistent with MapsView) ---
            Button(action: {
                withAnimation { nav.currentView = "home" }
            }) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.primary)
                    .frame(width: 75, height: 75)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
            }
            .padding(.leading, 12)
            .padding(.bottom, 12)
        }
        .task {
            await musicManager.requestAuthorization()
        }
    }
}

// MARK: - Subviews

struct PinnedAlbumCard: View {
    let album: Album
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            if let artwork = album.artwork {
                ArtworkImage(artwork, width: 140, height: 140)
                    .cornerRadius(22)
            }
            
            Text(album.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(width: 140)
        }
    }
}

struct LibraryAlbumCard: View {
    let album: Album
    
    var body: some View {
        Button(action: {
            Task {
                SystemMusicPlayer.shared.queue = [album]
                try? await SystemMusicPlayer.shared.play()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                if let artwork = album.artwork {
                    ArtworkImage(artwork, width: 240, height: 240)
                        .cornerRadius(32)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(album.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Text(album.artistName)
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                }
                .padding(.leading, 8)
            }
        }
        .buttonStyle(.plain)
    }
}
