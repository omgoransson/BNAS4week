//
//  Workday.swift
//  Bristow Schedule Reader
//
//  Created by Ola Göransson on 2017-09-14.
//

import Foundation
import EventKit

// TODO: Add Comparable & Equatable

class Workday {
    
    
    
    // Must exist for both workdays and days off
    let date: Date
    var activity: String
    var location: String
    // For days off
    var allDay = false
    var isTimeOff = false
    
    // If scheduled workday
    var startTime: Date?
    var endTime: Date?
    var reportingTime: Date?
    var details: String?
    var notes: String?
    
    // For storing original information if updated in later schedule
    var originalStartTime: Date?
    var originalEndTime: Date?
    var originalReportingTime: Date?
    
    // Calendar adding tracking
    var isAddedToCalendar = false
    var calendarEventID: String?
    var reportingEventID: String?
	
	var hasChangedSinceLastSave = false
    
    var description: String {
        return date.date
    }
    
    
    // Debug description
    var fullDescription: String {
        let start = (startTime?.formatted("dd-MMM-yyyy HH:mm") ?? "No start")
        let end = (endTime?.formatted("dd-MMM-yyyy HH:mm") ?? "No end")
        return "From " + start + " to " + end + " " + activity
    }
    
    // MARK: INITIALIZERS
    
    init?(from line: String) {
        var collumn = line.components(separatedBy: "\t")

        // A Workday must have a date
        guard let date = collumn[0].date(formatedWith: "dd-MMM-yyyy") else { return nil }
        
        self.date = date
        self.activity = collumn[2]
        self.location = collumn[3]
        
        // Does not always exist the schedule should have 4, 8 or 9
        if collumn.count > 5 {
            self.startTime = collumn[4].date(formatedWith: "dd-MMM-yyyy HH:mm")
            self.endTime = collumn[5].date(formatedWith: "dd-MMM-yyyy HH:mm")
            self.reportingTime = collumn[6].date(formatedWith: "dd-MMM-yyyy HH:mm")
		}
		if collumn.count > 7 {
            self.details = collumn[7]
        }
        if collumn.count == 9 {
            self.notes = collumn[8]
        }

		
		// Clean up
		if startTime == nil {
			allDay = true
			isTimeOff = true
		}
		
		if details == "" || details == " " {
			details = nil
		}
		if notes == "" || notes == " " {
			notes = nil
		}
        
        
        if details != nil {
            details = details?.replacingOccurrences(of: "+ ", with: "\n")
            details = details?.replacingOccurrences(of: ", ", with: "\n")
            details = details?.replacingOccurrences(of: "-", with: "")
            details = details?.replacingOccurrences(of: "/", with: " / ")
        }
		// Added from an imported schedule - needs to save calendar info
        hasChangedSinceLastSave = true
    }
    
    init?(from dict: [String : String]) {
        // A Workday must have a date
        guard let date = dict["date"]?.date(formatedWith: "dd-MMM-yyyy") else { return nil }
        
        self.date = date
        self.activity = dict["activity"] ?? "Unknown"
        self.location = dict["location"] ?? "Unknown"
        self.startTime = dict["startTime"]?.date(formatedWith: "dd-MMM-yyyy HH:mm")
        self.endTime = dict["endTime"]?.date(formatedWith: "dd-MMM-yyyy HH:mm")
        self.reportingTime = dict["reportingTime"]?.date(formatedWith: "dd-MMM-yyyy HH:mm")
        self.details = dict["details"]
        self.notes = dict["notes"]
        self.calendarEventID = dict["calendarEventID"]
        self.reportingEventID = dict["reportingEventID"]
        if startTime == nil {
            self.allDay = true
            self.isTimeOff = true
        }
    }
    
    
//    // This one should not be needed since the originals won't be set until an existing is changed - for testing
//    init(title: String, startDate: Date, endDate: Date, originalStartDate: Date, originalEndDate: Date) {
//        self.init(activity: title, startDate: startDate, endDate: endDate)
//        self.originalStartTime = originalStartDate
//        self.originalEndTime = originalEndDate
//
//    }
//    init(activity: String, startDate: Date, endDate: Date)  {
//        self.date = startDate
//        self.activity = activity
//        self.location = ""
//        self.startTime = startDate
//        self.endTime = endDate
//    }
	
    
    // TODO: Instance method to update it if it already exists
	// mutating func update(with newValue: Workday, in eventStore: EKEventStore?) -> (EKEvent?, EKEvent?) {
	func update(with newValue: Workday) {
//        var event: EKEvent? = nil
//        var report: EKEvent? = nil
        self.activity = newValue.activity
        self.location = newValue.location
        // For days off
        self.allDay = newValue.allDay
        self.isTimeOff = newValue.isTimeOff
        
        // Store the original information if updated
        if self.startTime != newValue.startTime {
            self.originalStartTime = self.startTime
            self.startTime = newValue.startTime
        }
        if self.endTime != newValue.endTime {
            self.originalEndTime = self.endTime
            self.endTime = newValue.endTime
        }
        if self.reportingTime != newValue.reportingTime {
            self.originalReportingTime = self.reportingTime
            self.reportingTime = newValue.reportingTime
        }
        
        self.details = newValue.details
        self.notes = newValue.notes
		
		// Updated, thus needs calendar update
		self.hasChangedSinceLastSave = true
//        // Update in calendar
//        if self.isAddedToCalendar {
//            if let eventStore = eventStore {
//                event = updateEvent(in: eventStore)
//                report = updateReport(in: eventStore)
//            }
//        }
//        return (event, report)
		return
    }
    
    // MARK: Save to Firebase
    func save() -> [String: String] {
        
        var dict = [String : String]()
        
        dict["date"] = date.formatted("dd-MMM-yyyy")
        dict["activity"] = activity
        dict["location"] = location
        dict["startTime"] = startTime?.formatted("dd-MMM-yyyy HH:mm")
        dict["endTime"] = endTime?.formatted("dd-MMM-yyyy HH:mm")
        dict["reportingTime"] = reportingTime?.formatted("dd-MMM-yyyy HH:mm")
        dict["details"] = details
        dict["notes"] = notes
        dict["calendarEventID"] = calendarEventID
        dict["reportingEventID"] = reportingEventID
        
        return dict
    }
    
    // MARK: Calendar
	func event(in eventStore: EKEventStore) -> (Int) {
        // Create the event from self
        var event = EKEvent(eventStore: eventStore)
        event = fillEvent(event)
		
		guard !event.isAllDay else { return (0) }
		
		// Save the event and then the ID
		event.calendar = eventStore.defaultCalendarForNewEvents
		try? eventStore.save(event, span: .thisEvent, commit: true)
		self.calendarEventID = event.eventIdentifier
		
		
        // Continue setup of the reporting event
        guard (reportingTime != nil) else { return (1) }
        
        let report = EKEvent(eventStore: eventStore)
        
        report.title = "Check in"
        report.startDate = reportingTime
        report.endDate = reportingTime?.addingTimeInterval(3600)  // One hour long
        
        // Add two alarms 1 hour before and 30 minutes before
        report.alarms = [EKAlarm(relativeOffset: -3600), EKAlarm(relativeOffset: -1800)]
		
		// Save the event and then the ID
		report.calendar = eventStore.defaultCalendarForNewEvents
		try? eventStore.save(report, span: .thisEvent, commit: true)
		self.reportingEventID = report.eventIdentifier
		
		return (1)
    }
    
    func updateEvent(in eventStore: EKEventStore) -> Int {
        
        guard let calendarEventID = calendarEventID else { return 0 }
        guard var event = eventStore.event(withIdentifier: calendarEventID) else { return 0 }
        
        // Set all new values
        event = fillEvent(event)
		
		// Save the event
		do {
			try eventStore.save(event, span: .thisEvent, commit: true)
			print("Event updated!")
		} catch {
			print(error.localizedDescription)
		}

		
        
        return 1
    }
    
    func updateReport(in eventStore: EKEventStore) -> Int {
        
        guard let reportingEventID = reportingEventID else { return  0 }
        guard let report = eventStore.event(withIdentifier: reportingEventID) else { return 0 }
        
        // Set the new reporting time
        report.startDate = reportingTime
        report.endDate = reportingTime?.addingTimeInterval(3600)
		
		// Save the reporting event
		try? eventStore.save(report, span: .thisEvent, commit: true)
		
        return 1
    }
    
    // MARK: Private helper to fill out event details
    private func fillEvent(_ event: EKEvent) -> EKEvent {
        event.title = details ?? activity
        if let startTime = startTime, let endTime = endTime {
            event.startDate = startTime
            event.endDate = endTime
        } else {
            event.startDate = date
            event.endDate = date
            event.isAllDay = true
        }
        event.location = location
        event.notes = notes
        
        // Adding the original start and end times if the event has been changed
        if originalStartTime != nil || originalEndTime != nil {
            let original = "\nOriginal start time: \(originalStartTime!.time) \nOriginal end time: \(originalEndTime!.time)"
            if let notes = event.notes {    // If a note exist, append text
                event.notes = notes + original
            } else {                        // If the note doesn't exist, just add the text
                event.notes?.append(original)
            }
        }
        
        return event
    }
}

// MARK: Comparable & Equatable

extension Workday: Comparable, Equatable {
    static func <(lhs: Workday, rhs: Workday) -> Bool {
        return lhs.date < rhs.date
    }
    
    static func ==(lhs: Workday, rhs: Workday) -> Bool {
        return
            lhs.date == rhs.date &&
                lhs.startTime == rhs.startTime &&
                lhs.endTime == rhs.endTime &&
                lhs.activity == rhs.activity &&
                lhs.details == rhs.details &&
                lhs.reportingTime == rhs.reportingTime &&
                lhs.notes == rhs.notes
        
    }
}




// TODO: FIX THE ACTIVITY
//        // Behövs detta?
//        if collumn[2] == "F" {
//            day.details = "Fri"
//            day.date = date.toDateFormattedWith("dd-MMM-yyyy")
//            day.activity = "Fri"
//            day.allDay = true
//            day.isTimeOff = true
//            return day
//        }
//        if collumn[2] == "va" || collumn[2] == "VA" {
//            day.details = "Avspassering"
//            day.date = date.toDateFormattedWith("dd-MMM-yyyy")
//            day.activity = "Avspassering"
//            day.allDay = true
//            day.isTimeOff = true
//        }



