//
//  HomeCalendarWidget.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 15.03.2026.
//

import SwiftUI
import EventKit
import Combine

struct HomeCalendarWidget: View {
    @Bindable var nav: CarPlayNavigation
    let timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect() // Refresh every 5 mins
    
    var body: some View {
        @Bindable var calendarManager = nav.calendarManager
        
        VStack(spacing: 8) {
            if calendarManager.upcomingEvents.isEmpty {
                VStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                    Text(calendarManager.isCalendarAuthorized ? "no_events" : "calendar_access_needed")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(Array(calendarManager.upcomingEvents.prefix(2).enumerated()), id: \.element.eventIdentifier) { index, event in
                    CalendarRow(event: event, isFirst: index == 0)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .frame(height: 125) // Reduced from 140
        .background(Color(white: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onAppear {
            calendarManager.checkAuthorization()
        }
        .onReceive(timer) { _ in
            calendarManager.fetchUpcomingEvents()
        }
    }
}

struct CalendarRow: View {
    let event: EKEvent
    let isFirst: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Day label
            Text(dayString(for: event.startDate))
                .font(.system(size: 13, weight: .bold)) // Slightly smaller
                .foregroundStyle(.white)
                .frame(width: 60, alignment: .leading)
            
            // Color indicator
            Capsule()
                .fill(Color(event.calendar?.cgColor ?? UIColor.blue.cgColor))
                .frame(width: 4)
                .padding(.vertical, 4)
            
            // Event Details
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 15, weight: .bold)) // Slightly smaller
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Time
            VStack(alignment: .trailing, spacing: 0) {
                Text(event.startDate, format: .dateTime.hour().minute())
                Text(event.endDate, format: .dateTime.hour().minute())
            }
            .font(.system(size: 11, weight: .medium)) // Slightly smaller
            .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isFirst ? Color.white.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func dayString(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d" // e.g. Mar 20
            return formatter.string(from: date)
        }
    }
}
