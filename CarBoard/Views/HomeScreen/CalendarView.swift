//
//  CalendarView.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 15.03.2026.
//

import SwiftUI
import EventKit

enum CalendarMode {
    case calendar
    case reminders
}

struct CalendarView: View {
    @Bindable var nav: CarPlayNavigation
    @State private var mode: CalendarMode = .calendar
    @State private var showSettings = false
    
    // Detail States
    @State private var selectedEvent: EKEvent?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        @Bindable var calendarManager = nav.calendarManager
        
        ZStack(alignment: .leading) {
            // 1. SIDE BUTTONS
            VStack(spacing: 15) {
                Spacer()
                
                // Settings Button (Gears)
                Button(action: { withAnimation(.spring()) { showSettings.toggle() } }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(showSettings ? .blue : .white)
                        .frame(width: 75, height: 75)
                        .glassEffect(.clear)
                        .background(.white.opacity(showSettings ? 0.2 : 0.1))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                }
                
                // Toggle Button (Reminders/Calendar)
                Button(action: { toggleMode() }) {
                    Image(systemName: mode == .calendar ? "list.bullet" : "calendar")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 75, height: 75)
                        .glassEffect(.clear)
                        .background(.white.opacity(0.1))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                }
                
                // Plus Button
                Button(action: {
                    calendarManager.selectedEventForEditing = nil
                    withAnimation { 
                        nav.currentView = (mode == .calendar) ? "calendar_add" : "reminder_add"
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 75, height: 75)
                        .glassEffect(.clear)
                        .background(.white.opacity(0.1))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                }
                
                // Home Button
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
            .padding(.leading, 15)
            .padding(.bottom, 20)
            .zIndex(20)
            
            // 2. MAIN CONTENT
            VStack(alignment: .leading, spacing: 0) {
                Text(mode == .calendar ? "Calendar" : "Reminders")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.top, 40)
                    .padding(.leading, 110)
                    .padding(.bottom, 20)
                    .id(mode)
                
                ScrollView {
                    VStack(spacing: 16) {
                        if mode == .calendar {
                            calendarList
                                .transition(.scale(scale: 0.95).combined(with: .opacity))
                        } else {
                            reminderList
                                .transition(.scale(scale: 0.95).combined(with: .opacity))
                        }
                    }
                    .padding(.leading, 110)
                    .padding(.trailing, 40)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
                .mask {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.15),
                            .init(color: .black, location: 0.9),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            
            // 3. OVERLAYS (Settings & Detail)
            
            // Background dim for any overlay
            if showSettings || selectedEvent != nil {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { 
                        withAnimation { 
                            showSettings = false 
                            selectedEvent = nil
                        }
                    }
                    .zIndex(25)
            }

            // Calendar Picker
            if showSettings {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Visible Calendars")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(calendarManager.allCalendars(), id: \.calendarIdentifier) { cal in
                                Button(action: { calendarManager.toggleCalendar(cal.calendarIdentifier) }) {
                                    HStack(spacing: 18) {
                                        Circle()
                                            .fill(Color(cal.cgColor))
                                            .frame(width: 16, height: 16)
                                        
                                        Text(cal.title)
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundStyle(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: calendarManager.enabledCalendarIDs.contains(cal.calendarIdentifier) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(calendarManager.enabledCalendarIDs.contains(cal.calendarIdentifier) ? .blue : .secondary)
                                    }
                                    .padding(.vertical, 18)
                                    .padding(.horizontal, 22)
                                    .background(Color.white.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(30)
                .frame(width: 550, height: 380)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 32).stroke(.white.opacity(0.1), lineWidth: 1))
                .padding(.leading, 110)
                .padding(.trailing, 70)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(30)
            }
            
            // Event Detail Overlay
            if let event = selectedEvent {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text(event.title)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    
                    HStack(alignment: .top, spacing: 40) {
                        VStack(alignment: .leading, spacing: 8) {
                            // Date
                            Text(event.startDate, format: .dateTime.weekday(.wide).day().month().year())
                                .font(.system(size: 22, weight: .medium))
                                .foregroundStyle(.white.opacity(0.8))
                            
                            // Time
                            Text("\(event.startDate, format: .dateTime.hour().minute()) – \(event.endDate, format: .dateTime.hour().minute())")
                                .font(.system(size: 20))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        // Location
                        if let loc = event.location, !loc.isEmpty {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Location")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.secondary)
                                Text(loc)
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Buttons
                    HStack(spacing: 20) {
                        // Edit Button
                        Button(action: {
                            calendarManager.selectedEventForEditing = event
                            withAnimation { nav.currentView = "calendar_add" }
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit")
                            }
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(Color.gray.opacity(0.3))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        
                        // Delete Button
                        Button(action: { showDeleteConfirmation = true }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .background(Color.red)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(40)
                .frame(width: 650, height: 380)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 40).stroke(.white.opacity(0.1), lineWidth: 1))
                .padding(.leading, 110)
                .padding(.trailing, 70)
                .contentShape(Rectangle()) // Make the whole pop-up area tappable
                .onTapGesture { 
                    withAnimation { selectedEvent = nil }
                }
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                .zIndex(35)
                .alert("Delete Event?", isPresented: $showDeleteConfirmation) {
                    Button("Delete", role: .destructive) {
                        calendarManager.deleteEvent(event)
                        selectedEvent = nil
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Are you sure you want to remove this event from your calendar?")
                }
            }
        }
        .onAppear {
            nav.calendarManager.checkAuthorization()
        }
    }
    
    @ViewBuilder
    private var calendarList: some View {
        let calendarManager = nav.calendarManager
        if calendarManager.upcomingEvents.isEmpty {
            placeholderView(text: "no_events")
        } else {
            ForEach(calendarManager.upcomingEvents, id: \.eventIdentifier) { event in
                Button(action: { withAnimation(.spring()) { selectedEvent = event } }) {
                    CalendarEntryRow(event: event)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    @ViewBuilder
    private var reminderList: some View {
        let calendarManager = nav.calendarManager
        if calendarManager.upcomingReminders.isEmpty {
            placeholderView(text: "no_reminders")
        } else {
            ForEach(calendarManager.upcomingReminders, id: \.calendarItemIdentifier) { reminder in
                ReminderEntryRow(reminder: reminder)
            }
        }
    }
    
    private func placeholderView(text: String) -> some View {
        Text(LocalizedStringKey(text))
            .font(.system(size: 18))
            .foregroundStyle(.secondary)
            .padding(.top, 100)
    }
    
    private func toggleMode() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            mode = (mode == .calendar) ? .reminders : .calendar
        }
    }
}

struct CalendarEntryRow: View {
    let event: EKEvent
    
    var body: some View {
        HStack(spacing: 25) {
            Text(event.startDate, format: .dateTime.day().month(.twoDigits))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 80, alignment: .leading)
            
            Text(event.title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(event.startDate, format: .dateTime.hour().minute())
                Text(event.endDate, format: .dateTime.hour().minute())
            }
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 22)
        .background(Color(white: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ReminderEntryRow: View {
    let reminder: EKReminder
    
    var body: some View {
        HStack(spacing: 25) {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundStyle(reminder.isCompleted ? .green : .white)
                .frame(width: 80, alignment: .leading)
            
            Text(reminder.title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
            
            Spacer()
            
            if let dueDate = reminder.dueDateComponents?.date {
                Text(dueDate, format: .dateTime.day().month(.twoDigits))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 22)
        .background(Color(white: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}
