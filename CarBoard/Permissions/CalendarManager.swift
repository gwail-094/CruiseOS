//
//  CalendarManager.swift
//  CruiseOS
//
//  Created by Ardit Sejdiu on 15.03.2026.
//

import Foundation
import EventKit
import Observation
import SwiftUI

@MainActor
@Observable
class CalendarManager {
    private let eventStore = EKEventStore()
    var upcomingEvents: [EKEvent] = []
    var upcomingReminders: [EKReminder] = []
    
    var isCalendarAuthorized = false
    var isRemindersAuthorized = false
    
    // For editing/details
    var selectedCalendarID: String?
    var selectedEventForEditing: EKEvent?
    
    // User Settings: Which calendars to show in the list
    var enabledCalendarIDs: Set<String> = [] {
        didSet {
            UserDefaults.standard.set(Array(enabledCalendarIDs), forKey: "enabled_calendar_ids")
            fetchUpcomingEvents()
        }
    }
    
    init() {
        // Load saved settings
        if let saved = UserDefaults.standard.stringArray(forKey: "enabled_calendar_ids") {
            self.enabledCalendarIDs = Set(saved)
        }
        checkAuthorization()
    }
    
    func allCalendars() -> [EKCalendar] {
        // Return only calendars that allow adding new events
        return eventStore.calendars(for: .event).filter { $0.allowsContentModifications }
    }
    
    func toggleCalendar(_ id: String) {
        if enabledCalendarIDs.contains(id) {
            enabledCalendarIDs.remove(id)
        } else {
            enabledCalendarIDs.insert(id)
        }
    }
    
    func checkAuthorization() {
        let calStatus = EKEventStore.authorizationStatus(for: .event)
        self.isCalendarAuthorized = (calStatus == .authorized || calStatus == .fullAccess)
        
        // If first time and no specific calendars chosen, enable all by default
        if isCalendarAuthorized && enabledCalendarIDs.isEmpty {
            self.enabledCalendarIDs = Set(allCalendars().map { $0.calendarIdentifier })
        }
        
        if isCalendarAuthorized { fetchUpcomingEvents() }
        
        let remStatus = EKEventStore.authorizationStatus(for: .reminder)
        self.isRemindersAuthorized = (remStatus == .authorized || remStatus == .fullAccess)
        if isRemindersAuthorized { fetchUpcomingReminders() }
        
        if calStatus == .notDetermined || remStatus == .notDetermined {
            requestAccess()
        }
    }
    
    func requestAccess() {
        Task {
            do {
                let calGranted = try await eventStore.requestFullAccessToEvents()
                self.isCalendarAuthorized = calGranted
                if calGranted { 
                    if enabledCalendarIDs.isEmpty {
                        self.enabledCalendarIDs = Set(allCalendars().map { $0.calendarIdentifier })
                    }
                    fetchUpcomingEvents() 
                }
                
                let remGranted = try await eventStore.requestFullAccessToReminders()
                self.isRemindersAuthorized = remGranted
                if remGranted { fetchUpcomingReminders() }
            } catch {
                print("EventKit Access Error: \(error)")
            }
        }
    }
    
    func fetchUpcomingEvents() {
        guard isCalendarAuthorized else { return }
        
        // Filter: only use enabled calendars
        let allCals = allCalendars()
        let filteredCals = allCals.filter { enabledCalendarIDs.contains($0.calendarIdentifier) }
        
        guard !filteredCals.isEmpty else {
            withAnimation { self.upcomingEvents = [] }
            return
        }
        
        let startDate = Date()
        let endDate = Date().addingTimeInterval(30 * 24 * 3600)
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: filteredCals)
        let events = eventStore.events(matching: predicate)
        
        withAnimation {
            self.upcomingEvents = events.sorted { $0.startDate < $1.startDate }
        }
    }
    
    func fetchUpcomingReminders() {
        guard isRemindersAuthorized else { return }
        let predicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: nil)
        
        eventStore.fetchReminders(matching: predicate) { reminders in
            DispatchQueue.main.async {
                withAnimation {
                    self.upcomingReminders = reminders?.sorted { 
                        let d1 = $0.dueDateComponents?.date ?? .distantFuture
                        let d2 = $1.dueDateComponents?.date ?? .distantFuture
                        return d1 < d2
                    } ?? []
                }
            }
        }
    }
    
    func saveEvent(title: String, location: String, startDate: Date, endDate: Date, isAllDay: Bool) {
        guard isCalendarAuthorized else { return }
        
        let eventToSave: EKEvent
        if let existing = selectedEventForEditing {
            eventToSave = existing
        } else {
            eventToSave = EKEvent(eventStore: eventStore)
        }
        
        eventToSave.title = title.isEmpty ? "New Event" : title
        eventToSave.location = location
        eventToSave.startDate = startDate
        eventToSave.endDate = endDate
        eventToSave.isAllDay = isAllDay
        
        if let targetID = selectedCalendarID, let targetCal = allCalendars().first(where: { $0.calendarIdentifier == targetID }) {
            eventToSave.calendar = targetCal
        } else if eventToSave.calendar == nil {
            eventToSave.calendar = eventStore.defaultCalendarForNewEvents
        }
        
        do {
            try eventStore.save(eventToSave, span: .thisEvent)
            self.selectedEventForEditing = nil // Clear after save
            fetchUpcomingEvents()
        } catch {
            print("Failed to save event: \(error)")
        }
    }
    
    func deleteEvent(_ event: EKEvent) {
        do {
            try eventStore.remove(event, span: .thisEvent)
            fetchUpcomingEvents()
        } catch {
            print("Failed to delete event: \(error)")
        }
    }
    
    func saveReminder(title: String, notes: String, dueDate: Date?, priority: Int) {
        guard isRemindersAuthorized else { return }
        
        let newReminder = EKReminder(eventStore: eventStore)
        newReminder.title = title.isEmpty ? "New Reminder" : title
        newReminder.notes = notes
        newReminder.priority = priority
        
        if let date = dueDate {
            newReminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            // Also add an alarm for the due date
            newReminder.addAlarm(EKAlarm(absoluteDate: date))
        }
        
        newReminder.calendar = eventStore.defaultCalendarForNewReminders()
        
        do {
            try eventStore.save(newReminder, commit: true)
            fetchUpcomingReminders()
        } catch {
            print("Failed to save reminder: \(error)")
        }
    }
}
