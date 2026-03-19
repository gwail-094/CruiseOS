//
//  CreateCalendarEntryView.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 15.03.2026.
//

import SwiftUI
import EventKit

struct CreateCalendarEntryView: View {
    @Bindable var nav: CarPlayNavigation
    
    // Form States
    @State private var title: String = ""
    @State private var location: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600)
    @State private var isAllDay = false
    @State private var travelTime = "None"
    @State private var repeatOption = "None"
    @State private var alertOption = "None"
    
    // UI State
    @State private var showCalendarPicker = false
    
    var body: some View {
        @Bindable var calendarManager = nav.calendarManager
        
        ZStack(alignment: .leading) {
            // 1. SIDEBAR
            VStack(spacing: 15) {
                // Back Button
                Button(action: { withAnimation { nav.currentView = "calendar" } }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 75, height: 75)
                        .glassEffect(.clear)
                        .background(.white.opacity(0.2))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                }
                
                // Done Button (Tick) - Light Blue
                Button(action: { 
                    calendarManager.saveEvent(title: title, location: location, startDate: startDate, endDate: endDate, isAllDay: isAllDay)
                    withAnimation { nav.currentView = "calendar" }
                }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 75, height: 75)
                        .background(Color.blue.opacity(0.8))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                }
                
                Spacer()
                
                // Select Calendar Button
                Button(action: { withAnimation(.spring()) { showCalendarPicker.toggle() } }) {
                    Image(systemName: "calendar")
                        .font(.system(size: 28))
                        .foregroundStyle(showCalendarPicker ? .blue : .white)
                        .frame(width: 75, height: 75)
                        .glassEffect(.clear)
                        .background(.white.opacity(showCalendarPicker ? 0.2 : 0.1))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 1))
                }
                
                // Home Button
                Button(action: { withAnimation { nav.currentView = "home" } }) {
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
            .padding(.vertical, 20)
            .zIndex(20)
            
            // 2. FORM CONTENT
            VStack(spacing: 15) {
                // SECTION 1: TITLE & LOCATION
                VStack(spacing: 0) {
                    TextField("Title", text: $title, prompt: Text("Title").foregroundColor(.white.opacity(0.5)))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 15)
                    
                    Divider()
                        .background(.white.opacity(0.2))
                        .padding(.horizontal, 25)
                    
                    TextField("Location or Video Call", text: $location, prompt: Text("Location or Video Call").foregroundColor(.white.opacity(0.5)))
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 15)
                }
                .background(Color(white: 0.15))
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                
                // SECTION 2: TIMES & OPTIONS
                VStack(spacing: 15) {
                    HStack {
                        VStack(alignment: .leading, spacing: 15) {
                            // STARTS
                            HStack(spacing: 15) {
                                Text("Starts")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                                    .frame(width: 80, alignment: .leading)
                                
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .scaleEffect(1.1)
                                    .grayscale(isAllDay ? 1 : 0)
                                    .opacity(isAllDay ? 0.5 : 1)
                                    .disabled(isAllDay)
                                
                                DatePicker("", selection: $startDate, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .scaleEffect(1.1)
                                    .grayscale(isAllDay ? 1 : 0)
                                    .opacity(isAllDay ? 0.5 : 1)
                                    .disabled(isAllDay)
                            }
                            
                            // ENDS
                            HStack(spacing: 15) {
                                Text("Ends")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                                    .frame(width: 80, alignment: .leading)
                                
                                DatePicker("", selection: $endDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .scaleEffect(1.1)
                                    .grayscale(isAllDay ? 1 : 0)
                                    .opacity(isAllDay ? 0.5 : 1)
                                    .disabled(isAllDay)
                                
                                DatePicker("", selection: $endDate, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .scaleEffect(1.1)
                                    .grayscale(isAllDay ? 1 : 0)
                                    .opacity(isAllDay ? 0.5 : 1)
                                    .disabled(isAllDay)
                            }
                            
                            // TRAVEL TIME
                            HStack {
                                Text("Travel Time")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                                
                                Spacer()
                                
                                Menu {
                                    Button("None") { travelTime = "None" }
                                    Button("5 min") { travelTime = "5 min" }
                                    Button("15 min") { travelTime = "15 min" }
                                    Button("30 min") { travelTime = "30 min" }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(travelTime)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 14))
                                    }
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                                }
                            }
                        }
                        
                        Divider()
                            .background(.white.opacity(0.2))
                            .padding(.horizontal, 20)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            // ALL DAY
                            Toggle(isOn: $isAllDay) {
                                Text("All Day")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                            }
                            .tint(.green)
                            
                            // REPEAT
                            HStack {
                                Text("Repeat")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                                Menu {
                                    Button("None") { repeatOption = "None" }
                                    Button("Daily") { repeatOption = "Daily" }
                                    Button("Weekly") { repeatOption = "Weekly" }
                                } label: {
                                    Image(systemName: "chevron.up.chevron.down")
                                        .foregroundStyle(.white)
                                }
                            }
                            
                            // ALERT
                            HStack {
                                Text("Alert")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                                Menu {
                                    Button("None") { alertOption = "None" }
                                    Button("At time of event") { alertOption = "At time of event" }
                                    Button("5 min before") { alertOption = "5 min before" }
                                } label: {
                                    Image(systemName: "chevron.up.chevron.down")
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                    .padding(25)
                }
                .background(Color(white: 0.15))
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            }
            .padding(.leading, 110)
            .padding(.trailing, 40)
            .padding(.vertical, 20)
            
            // 3. CALENDAR PICKER OVERLAY
            if showCalendarPicker {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation { showCalendarPicker = false } }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Select Calendar")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(calendarManager.allCalendars(), id: \.calendarIdentifier) { cal in
                                    Button(action: { 
                                        calendarManager.selectedCalendarID = cal.calendarIdentifier
                                        withAnimation { showCalendarPicker = false }
                                    }) {
                                        HStack(spacing: 18) {
                                            Circle()
                                                .fill(Color(cal.cgColor))
                                                .frame(width: 16, height: 16)
                                            
                                            Text(cal.title)
                                                .font(.system(size: 20, weight: .medium))
                                                .foregroundStyle(.white)
                                            
                                            Spacer()
                                            
                                            let isSelected = calendarManager.selectedCalendarID == cal.calendarIdentifier || (calendarManager.selectedCalendarID == nil && cal == EKEventStore().defaultCalendarForNewEvents)
                                            
                                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 24))
                                                .foregroundStyle(isSelected ? .blue : .secondary)
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
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(30)
            }
        }
        .onAppear {
            calendarManager.checkAuthorization()
            
            // Pre-fill if editing
            if let event = calendarManager.selectedEventForEditing {
                self.title = event.title
                self.location = event.location ?? ""
                self.startDate = event.startDate
                self.endDate = event.endDate
                self.isAllDay = event.isAllDay
                
                // Set the picker to the event's calendar
                if let calID = event.calendar?.calendarIdentifier {
                    calendarManager.selectedCalendarID = calID
                }
            }
        }
    }
}
