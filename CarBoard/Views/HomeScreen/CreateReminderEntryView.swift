//
//  CreateReminderEntryView.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 15.03.2026.
//

import SwiftUI

struct CreateReminderEntryView: View {
    @Bindable var nav: CarPlayNavigation
    
    // Form States
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var dueDate = Date()
    @State private var repeatOption = "None"
    @State private var priority = 0 // 0: None, 1: High, 5: Medium, 9: Low (EKPriority)
    
    private var priorityText: String {
        switch priority {
        case 1: return "High"
        case 5: return "Medium"
        case 9: return "Low"
        default: return "None"
        }
    }
    
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
                    calendarManager.saveReminder(title: title, notes: notes, dueDate: dueDate, priority: priority)
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
                
                // Calendar Shortcut
                Button(action: { withAnimation { nav.currentView = "calendar" } }) {
                    Image(systemName: "calendar")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                        .frame(width: 75, height: 75)
                        .glassEffect(.clear)
                        .background(.white.opacity(0.1))
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
            .zIndex(10)
            
            // 2. FORM CONTENT
            VStack(spacing: 15) {
                // SECTION 1: TITLE & NOTES
                VStack(spacing: 0) {
                    TextField("New Reminder", text: $title, prompt: Text("New Reminder").foregroundColor(.white.opacity(0.5)))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 15)
                    
                    Divider()
                        .background(.white.opacity(0.2))
                        .padding(.horizontal, 25)
                    
                    TextField("Notes", text: $notes, prompt: Text("Notes").foregroundColor(.white.opacity(0.5)))
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 15)
                }
                .background(Color(white: 0.15))
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                
                // SECTION 2: DATE, TIME & OPTIONS
                VStack(spacing: 15) {
                    HStack(alignment: .top, spacing: 40) {
                        // Left: Date & Time
                        VStack(alignment: .leading, spacing: 15) {
                            HStack(spacing: 15) {
                                Text("Date")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                                    .frame(width: 60, alignment: .leading)
                                
                                DatePicker("", selection: $dueDate, displayedComponents: .date)
                                    .labelsHidden()
                                    .scaleEffect(1.1)
                            }
                            
                            HStack(spacing: 15) {
                                Text("Time")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                                    .frame(width: 60, alignment: .leading)
                                
                                DatePicker("", selection: $dueDate, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .scaleEffect(1.1)
                            }
                        }
                        
                        Divider()
                            .background(.white.opacity(0.2))
                            .frame(height: 100)
                        
                        // Right: Repeat & Priority
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Repeat")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                                Menu {
                                    Button("None") { repeatOption = "None" }
                                    Button("Daily") { repeatOption = "Daily" }
                                    Button("Weekly") { repeatOption = "Weekly" }
                                    Button("Monthly") { repeatOption = "Monthly" }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(repeatOption)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 14))
                                    }
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                                }
                            }
                            
                            HStack {
                                Text("Priority")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                                Menu {
                                    Button("None") { priority = 0 }
                                    Button("Low") { priority = 9 }
                                    Button("Medium") { priority = 5 }
                                    Button("High") { priority = 1 }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(priorityText)
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.system(size: 14))
                                    }
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                    .padding(25)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(white: 0.15))
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                
                Spacer()
            }
            .padding(.leading, 110)
            .padding(.trailing, 40)
            .padding(.vertical, 20)
        }
    }
}
