//
//  CarPlayNavigation.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 12.03.2026.
//

import SwiftUI
import MapKit
import MusicKit
import Combine

@MainActor
@Observable
class CarPlayNavigation {
    var currentView: String = "home"
    
    // Persistence for language
    var languageIdentifier: String = UserDefaults.standard.string(forKey: "app_language") ?? "en" {
        didSet {
            UserDefaults.standard.set(languageIdentifier, forKey: "app_language")
        }
    }
    
    var selectedLocale: Locale {
        Locale(identifier: languageIdentifier)
    }
    
    var isDashboardOpen: Bool = true
    var selectedWallpaper: String = "bg1_bright"
    var previewWallpaperBase: String = "bg1"
    
    // Global Managers
    var calendarManager = CalendarManager()
    
    // Pinned Places Data with Persistence
    var pinnedPlaces: [PinnedPlace] = [] {
        didSet { savePinnedPlaces() }
    }
    
    var recentPlaces: [PinnedPlace] = [] {
        didSet { saveRecentPlaces() }
    }
    
    // Notification State
    var showPinnedNotification: Bool = false
    var pinnedNotificationMessage: String = ""
    
    init() {
        loadPinnedPlaces()
        loadRecentPlaces()
    }
    
    func pinLocation(_ item: MKMapItem) {
        let newPinned = PinnedPlace(
            icon: "mappin.and.ellipse",
            iconColor: .red,
            title: item.name ?? "Pinned Place",
            subtitle: item.placemark.title ?? "",
            coordinate: item.placemark.coordinate
        )
        // Avoid duplicates based on coordinates (simple check)
        if !pinnedPlaces.contains(where: { $0.latitude == newPinned.latitude && $0.longitude == newPinned.longitude }) {
            pinnedPlaces.append(newPinned)
            
            // Trigger Notification
            self.pinnedNotificationMessage = "location_pinned"
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                self.showPinnedNotification = true
            }
            
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    self.showPinnedNotification = false
                }
            }
        }
    }
    
    func addToRecents(_ item: MKMapItem) {
        let newRecent = PinnedPlace(
            icon: "clock.fill",
            iconColor: .gray,
            title: item.name ?? "Recent Place",
            subtitle: item.placemark.title ?? "",
            coordinate: item.placemark.coordinate
        )
        
        // Remove if already exists to move to top
        recentPlaces.removeAll(where: { $0.latitude == newRecent.latitude && $0.longitude == newRecent.longitude })
        recentPlaces.insert(newRecent, at: 0)
        
        // Keep only top 10
        if recentPlaces.count > 10 {
            recentPlaces = Array(recentPlaces.prefix(10))
        }
    }
    
    private func savePinnedPlaces() {
        if let encoded = try? JSONEncoder().encode(pinnedPlaces) {
            UserDefaults.standard.set(encoded, forKey: "pinned_places")
        }
    }
    
    private func loadPinnedPlaces() {
        if let data = UserDefaults.standard.data(forKey: "pinned_places"),
           let decoded = try? JSONDecoder().decode([PinnedPlace].self, from: data) {
            self.pinnedPlaces = decoded
        }
    }
    
    private func saveRecentPlaces() {
        if let encoded = try? JSONEncoder().encode(recentPlaces) {
            UserDefaults.standard.set(encoded, forKey: "recent_places")
        }
    }
    
    private func loadRecentPlaces() {
        if let data = UserDefaults.standard.data(forKey: "recent_places"),
           let decoded = try? JSONDecoder().decode([PinnedPlace].self, from: data) {
            self.recentPlaces = decoded
        }
    }
    
    // Status Properties
    var networkManager = NetworkManager()
    
    // Shared Navigation Properties
    var selectedRoute: MKRoute?
    var isNavigating: Bool = false
    var navigationStepIndex: Int = 1
    var currentStepRemainingDistance: CLLocationDistance = 0
    var isRerouting: Bool = false
    var mapPosition: MapCameraPosition = MapCameraPosition.userLocation(followsHeading: false, fallback: .automatic)
    
    var totalRemainingDistance: CLLocationDistance {
        guard let route = selectedRoute else { return 0 }
        let remainingStepsDistance = route.steps.dropFirst(navigationStepIndex + 1).reduce(0) { $0 + $1.distance }
        return currentStepRemainingDistance + remainingStepsDistance
    }
    
    // Live Nav Logic
    func updateLiveNavigation(currentLocation: CLLocation) {
        guard let route = selectedRoute, route.steps.indices.contains(navigationStepIndex) else { return }
        let currentStep = route.steps[navigationStepIndex]
        let stepEndPoint = currentStep.polyline.points()[currentStep.polyline.pointCount - 1].coordinate
        let targetLoc = CLLocation(latitude: stepEndPoint.latitude, longitude: stepEndPoint.longitude)
        self.currentStepRemainingDistance = currentLocation.distance(from: targetLoc)
        
        if currentStepRemainingDistance < 35 && navigationStepIndex < route.steps.count - 1 {
            self.navigationStepIndex += 1
        }
    }
}

//MARK: - Music Widget
@MainActor
struct HomeMusicWidget: View {
    // We use the shared player
    private let musicPlayer = SystemMusicPlayer.shared
    
    // Observed state to trigger UI updates when the song changes
    @State private var currentEntry: MusicPlayer.Queue.Entry?
    @State private var playbackStatus: MusicPlayer.PlaybackStatus = .stopped
    @State private var isAuthorized = false
    
    // Animation Triggers
    @State private var playTrigger = 0
    @State private var backTrigger = 0
    @State private var nextTrigger = 0

    var body: some View {
        VStack(spacing: 12) { // Tighter spacing
            // --- TOP: Cover & Info ---
            HStack(alignment: .center, spacing: 16) {
                // Album Art
                if let artwork = currentEntry?.artwork {
                    ArtworkImage(artwork, width: 80, height: 80) // Slightly smaller
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.3))
                        .frame(width: 80, height: 80)
                        .overlay(Image(systemName: "music.note").foregroundStyle(.secondary))
                }
                
                // Song Metadata
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentEntry?.title ?? "Not Playing")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    
                    Text(currentEntry?.subtitle ?? (isAuthorized ? "Pick a song" : "Tap to Connect"))
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
                Spacer()
            }
            
            // --- BOTTOM: Playback Controls ---
            HStack(spacing: 40) {
                Button(action: { 
                    backTrigger += 1
                    Task { try? await musicPlayer.skipToPreviousEntry() } 
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 24))
                        .symbolEffect(.bounce, value: backTrigger)
                }
                
                Button(action: {
                    playTrigger += 1
                    if playbackStatus == .playing {
                        musicPlayer.pause()
                    } else {
                        Task { try? await musicPlayer.play() }
                    }
                    updateEntry()
                }) {
                    Image(systemName: playbackStatus == .playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 32))
                        .symbolEffect(.bounce, value: playTrigger)
                }
                
                Button(action: { 
                    nextTrigger += 1
                    Task { try? await musicPlayer.skipToNextEntry() } 
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 24))
                        .symbolEffect(.bounce, value: nextTrigger)
                }
            }
            .foregroundStyle(.white)
        }
        .padding(15)
        .frame(maxWidth: .infinity)
        .frame(height: 190) // Reduced from 220
        .background(Color(white: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .onAppear {
            checkPermissions()
            updateEntry()
        }
        // Listener to refresh the UI whenever the music player state changes
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            updateEntry()
        }
    }
    
    private func updateEntry() {
        self.currentEntry = musicPlayer.queue.currentEntry
        self.playbackStatus = musicPlayer.state.playbackStatus
    }

    private func checkPermissions() {
        Task {
            let status = await MusicAuthorization.request()
            withAnimation {
                self.isAuthorized = (status == .authorized)
            }
        }
    }
}

// MARK: - 2. The Main Root Container
@MainActor
struct CarPlayRootView: View {
    @State private var nav = CarPlayNavigation()
    
    var body: some View {
        @Bindable var nav = nav
        
        ZStack(alignment: .leading) {
            Color.black.ignoresSafeArea()

            // 1. CONTENT LAYER
            Group {
                if nav.currentView == "home" {
                    CarPlayHomeView(nav: nav)
                } else if nav.currentView == "maps" {
                    if #available(iOS 26.0, *) {
                        MapsView(nav: nav)
                    } else {
                        // Fallback on earlier versions
                    }
                } else if nav.currentView == "grid" {
                    AppGridView(nav: nav)
                } else if nav.currentView == "settings" {
                    SettingsView(nav: nav)
                } else if nav.currentView == "music" {
                    AppleMusicView(nav: nav)
                } else if nav.currentView == "wallpaper" {
                    WallpaperView(nav: nav)
                } else if nav.currentView == "wallpaper_detail" {
                    WallpaperDetailView(nav: nav)
                        .transition(.opacity)
                } else if nav.currentView == "language_picker" {
                    LanguagePickerView(nav: nav)
                } else if nav.currentView == "calendar" {
                    CalendarView(nav: nav)
                } else if nav.currentView == "calendar_add" {
                    CreateCalendarEntryView(nav: nav)
                } else if nav.currentView == "reminder_add" {
                    CreateReminderEntryView(nav: nav)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: nav.currentView)

            // SIDEBAR REMOVED FROM HERE
            
            // 2. GLOBAL NOTIFICATION LAYER
            VStack {
                if nav.showPinnedNotification {
                    HStack {
                        Spacer()
                        ToastNotification(message: nav.pinnedNotificationMessage)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .padding(.top, 20)
            .zIndex(100)
        }
        .environment(\.locale, nav.selectedLocale)
        .ignoresSafeArea(.container, edges: .all)
    }
}

struct ToastNotification: View {
    let message: String
    
    var body: some View {
        if #available(iOS 26.0, *) {
            HStack(spacing: 15) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                
                Text(LocalizedStringKey(message))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 15)
            .glassEffect(.clear)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        } else {
            // Fallback on earlier versions
        }
    }
}

// MARK: - 5. CarPlay Home View (Dashboard)
@MainActor
struct CarPlayHomeView: View {
    @Bindable var nav: CarPlayNavigation
    
    var body: some View {
        ZStack(alignment: .leading) {
            FloatingSidebar(nav: nav)
                .padding(.leading, 12)
            
            HStack(spacing: 16) {
                Spacer(minLength: 90) // Gap for sidebar
                
                // LEFT: The Map Widget
                ZStack {
                    Map(position: $nav.mapPosition, interactionModes: []) {
                        UserAnnotation()
                        if let route = nav.selectedRoute {
                            MapPolyline(route.polyline).stroke(.blue, lineWidth: 4)
                        }
                    }
                    .mapStyle(.standard(emphasis: .muted))
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    
                    // Dashboard Navigation Banner
                    if nav.isNavigating {
                        VStack {
                            HStack {
                                HStack(spacing: 8) {
                                    let instruction = nav.selectedRoute?.steps[nav.navigationStepIndex].instructions ?? "Continue"
                                    
                                    Image(iconFor(instruction: instruction))
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .foregroundStyle(.white)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(instruction)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                        
                                        Text("In \(Int(nav.currentStepRemainingDistance)) m")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white.opacity(0.7))
                                    }
                                }
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                Spacer()
                            }
                            .padding(12)
                            Spacer()
                        }
                    }

                    Button(action: { withAnimation { nav.currentView = "maps" } }) {
                        Color.clear.contentShape(Rectangle())
                    }
                }
                .padding(.vertical, 16)
                

                // RIGHT: The Music Widget (REPLACES THE SPACER)
                VStack(spacing: 12) {
                    Spacer()
                    Button(action: {
                        withAnimation { nav.currentView = "calendar" }
                    }) {
                        HomeCalendarWidget(nav: nav)
                    }
                    .buttonStyle(.plain)
                    
                    HomeMusicWidget()
                }
                .padding(.vertical, 16)
                .frame(width: 310) // Restored closer to original width
            }
            .padding(.trailing, 60) // Increased to clear dynamic island
        }
    }
}

// MARK: - Preview
#Preview(traits: .landscapeLeft) {
    CarPlayRootView()
}
