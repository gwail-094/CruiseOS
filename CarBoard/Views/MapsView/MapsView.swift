//
//  MapsView.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 12.03.2026.
//

import SwiftUI
import MapKit

struct MapsView: View {
    // Shared navigation state from the root
    @Bindable var nav: CarPlayNavigation
    
    // Local UI states for search and previews
    @State private var isSearching = false
    @State private var searchManager = SearchManager()
    @State private var inspectedSearchItem: MKMapItem?
    @State private var searchRouteOptions: [RouteOption] = []
    @State private var isCalculatingSearchRoute = false
    @State private var searchResultToCalculate: MKMapItem?
    @State private var currentDestinationName: String?
    @State private var showTraffic = false
    @State private var speedLimitManager = SpeedLimitManager()
    @State private var locationManager = LocationManager()

    private var isFollowing: Bool {
        return nav.mapPosition.followsUserLocation
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // --- LAYER 1: THE MAP ---
            Map(position: $nav.mapPosition) {
                UserAnnotation()
                
                if let route = nav.selectedRoute {
                    MapPolyline(route.polyline)
                        .stroke(.blue, lineWidth: 6)
                }
            }
            .mapStyle(.standard(elevation: .realistic, emphasis: .muted, showsTraffic: showTraffic))
            .mapControls { }
            .contentMargins(.leading, 325, for: .automatic)
            .ignoresSafeArea()
            .onMapCameraChange(frequency: .continuous) { context in
                guard nav.isNavigating else { return }
                let center = context.camera.centerCoordinate
                let pseudoLoc = CLLocation(latitude: center.latitude, longitude: center.longitude)
                
                nav.updateLiveNavigation(currentLocation: pseudoLoc)
                checkForReroute(currentLocation: pseudoLoc)
            }
            .onChange(of: locationManager.lastLocation) { _, newLocation in
                if nav.isNavigating, let loc = newLocation {
                    applyAdaptiveZoom(for: loc)
                    speedLimitManager.updateSpeedLimit(for: loc)
                }
            }

            // --- LAYER 2: DASHBOARD & BUTTONS ---
            ZStack(alignment: .bottomLeading) {
                HStack(alignment: .bottom, spacing: 10) {
                    // LEFT COLUMN BUTTONS
                    VStack(spacing: 12) {
                        Spacer()

                        // 1. TRAFFIC TOGGLE
                        Button(action: { withAnimation { showTraffic.toggle() } }) {
                            Image(systemName: showTraffic ? "car.2.fill" : "car.2")
                                .font(.system(size: 26))
                                .foregroundStyle(showTraffic ? .blue : .primary)
                                .frame(width: 75, height: 75)
                                .glassEffect(.clear)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                        }

                        // 2. RE-CENTER BUTTON
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                nav.mapPosition = MapCameraPosition.userLocation(followsHeading: true, fallback: .automatic)
                            }
                        }) {
                            Image(systemName: isFollowing ? "location.fill" : "location")
                                .font(.system(size: 26))
                                .foregroundStyle(.white)
                                .frame(width: 75, height: 75)
                                .glassEffect(.clear)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                        }

                        if !nav.isNavigating {
                            // 3. MAP DASHBOARD TOGGLE
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    if nav.isDashboardOpen || isSearching || inspectedSearchItem != nil {
                                        nav.isDashboardOpen = false
                                        isSearching = false
                                        inspectedSearchItem = nil
                                    } else {
                                        nav.isDashboardOpen = true
                                    }
                                }
                            }) {
                                Image(systemName: nav.isDashboardOpen || isSearching || inspectedSearchItem != nil ? "map.fill" : "map")
                                    .font(.system(size: 26))
                                    .foregroundStyle(nav.isDashboardOpen || isSearching || inspectedSearchItem != nil ? .blue : .primary)
                                    .frame(width: 75, height: 75)
                                    .glassEffect(.clear)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                            }
                        } else {
                            // END NAVIGATION BUTTON (Red "X")
                            Button(action: {
                                withAnimation {
                                    nav.isNavigating = false
                                    nav.selectedRoute = nil
                                    nav.isDashboardOpen = false
                                    inspectedSearchItem = nil
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 75, height: 75)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                            }
                            .transition(.scale.combined(with: .opacity))
                        }

                        // 4. HOME BUTTON
                        Button(action: {
                            withAnimation { nav.currentView = "home" }
                        }) {
                            Image(systemName: "square.grid.3x3.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                                .frame(width: 75, height: 75)
                                .glassEffect(.clear)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                        }
                    }
                    
                    // MIDDLE & RIGHT AREA
                    if nav.isNavigating {
                        TripInfoPanel(nav: nav)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        
                        Spacer()
                        
                        if let limit = speedLimitManager.currentLimit {
                            SpeedLimitSign(speed: limit, region: speedLimitManager.region)
                                .transition(.scale.combined(with: .opacity))
                                .padding(.trailing, 20)
                        }
                    }
                }
                .padding(.leading, 12)
                .padding(.trailing, 12)
                .padding(.bottom, 20)

                // 3. THE FLOATING OVERLAYS
                if !nav.isNavigating {
                    Group {
                        if isSearching {
                            MapsSearchView(
                                searchManager: searchManager,
                                onSelect: { item in handleSearchSelection(item) },
                                onCancel: { isSearching = false }
                            )
                        } else if let searchItem = inspectedSearchItem {
                            SearchRoutePreview(
                                nav: nav,
                                item: searchItem,
                                routes: $searchRouteOptions,
                                selectedRoute: $nav.selectedRoute,
                                isCalculating: isCalculatingSearchRoute,
                                isNavigating: $nav.isNavigating,
                                onBack: {
                                    withAnimation {
                                        inspectedSearchItem = nil
                                        isSearching = true
                                        nav.selectedRoute = nil
                                    }
                                }
                            )
                        } else if nav.isDashboardOpen {
                            AppleMapsSidebar(
                                nav: nav,
                                onSearchTap: { isSearching = true },
                                onSelectPlace: { place in
                                    handlePlaceSelection(place)
                                },
                                onClose: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        nav.isDashboardOpen = false
                                    }
                                }
                            )
                        }
                    }
                    .padding(.leading, 100)
                    .padding(.bottom, 30)
                    .transition(.opacity)
                }
            }

            // --- LAYER 3: NAVIGATION BANNER (Top-most) ---
            if nav.isNavigating, let route = nav.selectedRoute, route.steps.indices.contains(nav.navigationStepIndex) {
                VStack(alignment: .leading) {
                    let step = route.steps[nav.navigationStepIndex]
                    let nextStep = route.steps.indices.contains(nav.navigationStepIndex + 1) ? route.steps[nav.navigationStepIndex + 1] : nil
                    
                    NavigationBanner(
                        instruction: step.instructions,
                        nextInstruction: nextStep?.instructions,
                        distance: nav.currentStepRemainingDistance,
                        isRerouting: nav.isRerouting,
                        onCancel: {
                            withAnimation {
                                nav.isNavigating = false
                                nav.selectedRoute = nil
                                nav.isDashboardOpen = false
                                inspectedSearchItem = nil
                            }
                        }
                    )
                    .padding(.top, 20)
                    .padding(.leading, 105) // Move it to the right of the buttons
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: nav.isDashboardOpen)
        .onAppear {
            locationManager.requestPermission()
        }
        .onChange(of: nav.isNavigating) { _, newValue in
            if newValue {
                startRealNavigation()
            } else {
                stopRealNavigation()
            }
        }
    }
    
    // MARK: - Helper Logic
    private func applyAdaptiveZoom(for location: CLLocation) {
        let speed = location.speed > 0 ? location.speed : 0
        let distToTurn = nav.currentStepRemainingDistance
        var targetDistance: Double = 400
        targetDistance += (speed * 20)
        if distToTurn < 300 {
            targetDistance = max(200, distToTurn * 1.5)
        }
        targetDistance = min(max(targetDistance, 200), 1500)
        
        withAnimation(.linear(duration: 0.8)) {
            nav.mapPosition = .camera(MapCamera(
                centerCoordinate: location.coordinate,
                distance: targetDistance,
                heading: location.course >= 0 ? location.course : 0,
                pitch: 0
            ))
        }
    }

    private func checkForReroute(currentLocation: CLLocation) {
        guard let route = nav.selectedRoute else { return }
        let points = route.polyline.points()
        let pointCount = route.polyline.pointCount
        var minDistance = Double.greatestFiniteMagnitude
        for i in stride(from: 0, to: pointCount, by: 10) {
            let pointLoc = CLLocation(latitude: points[i].coordinate.latitude, longitude: points[i].coordinate.longitude)
            let dist = currentLocation.distance(from: pointLoc)
            if dist < minDistance { minDistance = dist }
        }
        if minDistance > 100 { recalculateRoute(from: currentLocation.coordinate) }
    }
    
    private func recalculateRoute(from coordinate: CLLocationCoordinate2D) {
        guard !nav.isRerouting && nav.isNavigating else { return }
        withAnimation { nav.isRerouting = true }
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        guard let destination = inspectedSearchItem else { nav.isRerouting = false; return }
        request.destination = destination
        request.transportType = .automobile
        MKDirections(request: request).calculate { response, error in
            if let _ = error { nav.isRerouting = false; return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                guard let newRoute = response?.routes.first else { nav.isRerouting = false; return }
                withAnimation(.easeInOut) {
                    nav.selectedRoute = newRoute
                    nav.navigationStepIndex = 1
                    nav.currentStepRemainingDistance = newRoute.steps[1].distance
                    nav.isRerouting = false
                }
            }
        }
    }

    private func startRealNavigation() {
        guard let route = nav.selectedRoute else { return }
        nav.navigationStepIndex = 1
        if route.steps.indices.contains(1) { nav.currentStepRemainingDistance = route.steps[1].distance }
        withAnimation(.easeInOut(duration: 1.5)) {
            if let loc = locationManager.lastLocation {
                nav.mapPosition = .camera(MapCamera(centerCoordinate: loc.coordinate, distance: 400, heading: loc.course, pitch: 0))
            } else {
                nav.mapPosition = .userLocation(followsHeading: true, fallback: .automatic)
            }
        }
    }

    private func stopRealNavigation() {
        withAnimation(.easeInOut) {
            nav.mapPosition = MapCameraPosition.userLocation(followsHeading: false, fallback: .automatic)
            nav.selectedRoute = nil
        }
    }
    
    private func handleSearchSelection(_ item: MKMapItem) {
        withAnimation {
            isSearching = false
            inspectedSearchItem = item
            nav.addToRecents(item)
            calculateSearchRoute(to: item)
        }
    }

    private func handlePlaceSelection(_ place: PinnedPlace) {
        let placemark = MKPlacemark(coordinate: place.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = place.title
        withAnimation {
            nav.isDashboardOpen = false
            inspectedSearchItem = mapItem
            nav.addToRecents(mapItem)
            calculateSearchRoute(to: mapItem)
        }
    }
    
    private func calculateSearchRoute(to item: MKMapItem) {
        isCalculatingSearchRoute = true
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = item
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        MKDirections(request: request).calculate { response, _ in
            isCalculatingSearchRoute = false
            guard let response = response, let first = response.routes.first else { return }
            self.searchRouteOptions = response.routes.enumerated().map { index, route in
                RouteOption(route: route, isFastest: index == 0)
            }
            nav.selectedRoute = first
            withAnimation(.easeInOut(duration: 0.8)) {
                let tightRect = first.polyline.boundingMapRect
                let paddedRect = tightRect.insetBy(dx: -tightRect.width * 0.15, dy: -tightRect.height * 0.3)
                nav.mapPosition = MapCameraPosition.rect(paddedRect)
            }
        }
    }
}

// MARK: - Subviews

struct SpeedLimitSign: View {
    let speed: Int
    let region: String
    var body: some View {
        Image("\(speed)_\(region)")
            .resizable()
            .scaledToFit()
            .frame(width: 75, height: 75)
            .glassEffect(.clear)
            .clipShape(Circle())
            .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
    }
}

struct TripInfoPanel: View {
    @Bindable var nav: CarPlayNavigation
    @State private var isExpanded = false
    
    private var arrivalTime: Date {
        guard let route = nav.selectedRoute else { return Date() }
        let totalDist = route.distance
        guard totalDist > 0 else { return Date() }
        let remainingTime = (nav.totalRemainingDistance / totalDist) * route.expectedTravelTime
        return Date().addingTimeInterval(remainingTime)
    }
    private var arrivalTimeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: arrivalTime)
    }
    private var durationText: String {
        guard let route = nav.selectedRoute else { return "0m" }
        let totalDist = route.distance
        guard totalDist > 0 else { return "0m" }
        let remainingTime = (nav.totalRemainingDistance / totalDist) * route.expectedTravelTime
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: remainingTime) ?? "0m"
    }
    private var distanceValue: String {
        let km = nav.totalRemainingDistance / 1000.0
        return String(format: "%.1f", km)
    }
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                VStack(spacing: 15) {
                    HStack(spacing: 35) {
                        ExpandedActionButton(icon: "plus.circle.fill", label: "add_stop", color: .blue)
                        ExpandedActionButton(icon: "person.crop.circle.badge.plus", label: "share_eta", color: .green)
                        ExpandedActionButton(icon: "speaker.wave.2.fill", label: "audio_nav", color: .gray)
                    }
                    .padding(.top, 20).padding(.horizontal, 35)
                    .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.9, anchor: .bottomLeading)), removal: .opacity.combined(with: .scale(scale: 0.9, anchor: .bottomLeading))))
                    Divider().background(.white.opacity(0.2)).padding(.horizontal, 40)
                }
            }
            VStack(spacing: 8) {
                Capsule().fill(.white.opacity(0.2)).frame(width: 40, height: 4).padding(.top, 8)
                HStack(spacing: 35) {
                    VStack(spacing: 2) {
                        Text(arrivalTimeText).font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("arrival").font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
                    }.fixedSize()
                    VStack(spacing: 2) {
                        Text(durationText).font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("time").font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
                    }.fixedSize()
                    VStack(spacing: 2) {
                        Text(distanceValue).font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("km").font(.system(size: 14, weight: .medium)).foregroundStyle(.secondary)
                    }.fixedSize()
                }.lineLimit(1).padding(.horizontal, 35).padding(.bottom, 15)
            }
            .contentShape(Rectangle())
            .onTapGesture { withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) { isExpanded.toggle() } }
        }
        .foregroundStyle(.white).glassEffect(.clear).background(.ultraThinMaterial).clipShape(Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 1))
        .frame(minWidth: 330, alignment: .leading)
    }
}

struct ExpandedActionButton: View {
    let icon: String
    let label: String
    let color: Color
    var body: some View {
        Button(action: { }) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 24)).foregroundStyle(color).frame(width: 52, height: 52).background(.white.opacity(0.1)).clipShape(Circle())
                Text(LocalizedStringKey(label)).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
            }
        }.buttonStyle(.plain)
    }
}
