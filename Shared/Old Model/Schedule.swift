//
//  Schedule.swift
//  Bristow Schedule Reader
//
//  Created by Ola Göransson on 2017-09-14.
//

import Foundation
import EventKit
import FirebaseDatabase

class Schedule {
	
	// MARK: Instance variables
	var workSchedule: [[Workday]] = [[]]        // Working schedule for the tableView ((today - 1 week) -> end)
	var firebaseSchedule: [Workday]             // Whats in firebase
	var saveSchedule: [[String:String]] {		// Does this work?
		get {
			var export = [[String:String]]()
			for day in firebaseSchedule {
				export.append(day.save())
			}
			return export
		}
	}
	// MARK: - INITIALIZERS
	//    init(from schedule: String) {
	//        self.importedSchedule = Schedule.parseSchedule(schedule)
	//    }
	
	// MARK: Init from FIREBASE
	init(from firebase: [[String:String]]) {
		var days = [Workday?]()
		for day in firebase {
			days.append(Workday(from: day))
		}
		self.firebaseSchedule = days.compactMap { $0 }
		setWorkSchedule()
	}
	
	// MARK: - Saving and importing Schedule
	// MARK: Split into weeks for WorkSchedule
	func setWorkSchedule() {
	
		var newSchedule = [[Workday]]()
		if let firstDay = Date().firstDayOfLastWeek, let lastDay = firebaseSchedule.last?.date {
			guard firstDay < lastDay else { return }
			let dateInterval = DateInterval(start: firstDay , end: lastDay)
			let lastFiveWeeks = firebaseSchedule.filter {
				dateInterval.contains($0.date)
			}
			newSchedule = lastFiveWeeks.chunked(into: 7)
			workSchedule = newSchedule
		}
	}
	
	
	
	
	// MARK: Import schedule
	
	// TODO: MAKE EVENTSTORE OPTIONAL IF USER DOESN'T WANT TO ADD TO CAL
	func add(_ copiedString: String, in eventStore: EKEventStore) -> (Bool, (new : Int, updated: Int)) {
		var importedSchedule = parseSchedule(copiedString)
		guard importedSchedule.count == 28 else { return (false, (0, 0)) }
		
		// MARK: Merge imported schedule into firebase
		if let indexOfFirstNewDay = firebaseSchedule.index(where: { $0.date == importedSchedule[0].date }) {
			let correspondingPartOfFirebaseSchedule = firebaseSchedule.suffix(from: indexOfFirstNewDay)
			// Firebase has more days i.e. There's nothing new to add...
			// Exit function with false?
			// Or overwrite?
			guard correspondingPartOfFirebaseSchedule.count < importedSchedule.count else { return (true, (0, 0)) }
			// Do shit!
			// For all days already in firebase
			// Check if fbDay == importDay -> break
			// If fbDay != importDay -> update fbDay with importDay
			// After fbSchedule runs out -> just append the rest of importSchedule as they are all new days
			for (index, fbDay) in correspondingPartOfFirebaseSchedule.enumerated() {
				//guard fbDay != importedSchedule[index] else { break }
				if fbDay != importedSchedule[index] {
				fbDay.update(with: importedSchedule[index])
				}
			}
			importedSchedule.removeFirst(correspondingPartOfFirebaseSchedule.count)
			for newDay in importedSchedule {
				firebaseSchedule.append(newDay)
			}
		} else {
			// Could not find the first date of the new schedule, just add it to firebase!
			firebaseSchedule.append(contentsOf: importedSchedule)
		}
		// New things imported, recreate data source for table view
		setWorkSchedule()
		
		// MARK: Get events to save
		let events = getEvents(in: eventStore)
		return (true, events)
	}
	
	
	
	
	// MARK: - Helper methods
	
	func getEvents(in eventStore: EKEventStore) -> (new: Int, updated: Int) {
		
		// Setup counters
		var new = 0
		var updated = 0
		
		// NOTE: Workday is now a class, thus this should update the saved one in firebaseSchedule
		for day in firebaseSchedule.filter({ $0.hasChangedSinceLastSave }) {

			switch (day.calendarEventID != nil, day.reportingEventID != nil) {
			case (true, true):
				_ = day.updateEvent(in: eventStore)
				_ = day.updateReport(in: eventStore)
				updated += 1
			case (true, false):
				_ = day.updateEvent(in: eventStore)
				updated += 1
			case (false, true):
				_ = day.updateReport(in: eventStore)
				updated += 1
			case (false, false):
				_ = day.event(in: eventStore)
				new += 1
			}
		}
		return (new, updated)
	}
	
	
	
	private func parseSchedule(_ importedSchedule: String) -> [Workday] {
		
		var days = [Workday?]()
		
		let rows = rowsFromSchedule(importedSchedule)
		
		for row in rows {
			days.append(Workday(from: row))
		}
		
		return days.compactMap { $0 }
	}
	
	/// Splits the schedule up into individual rows of days
	///
	/// - Parameter schedule: String containing the emailed schedule
	/// - Returns: Array of Strings containing singel rows of the schedule
	private func rowsFromSchedule(_ importedSchedule: String) -> [String] {
		var rows = importedSchedule.components(separatedBy: "\n")
		
		// Remove the empty strings and any header row
		rows = rows.filter { !$0.isEmpty }
		rows = rows.filter { !$0.hasPrefix("Week") }
		rows = rows.filter { !$0.hasPrefix("Date") }
		
		
		// If not empty remove the two first rows and the two last
		guard rows.count > 4 else { return [String]() }
		_ = rows.removeFirst(2)    // Remove "name" row and the "Please find your duty details..." row
		_ = rows.removeLast(2)     // Remove the "This is a system generated mail..." row and the "Note : All times are Local." row
		
		// Regex to find the 'notes' that are on the next row and move them back up one row
		// "\n(?!\d{2}-[A-z]{3}-\d{4})(?=.)/g" // This will match any new line not starting with a date in format "dd-MMM-yyyy"
		if let regex = try? NSRegularExpression(pattern: "\\d{2}-[A-z]{3}-\\d{4}", options: .caseInsensitive) {
			
			// Clean up in case of 'notes'
			for (index, row) in rows.enumerated() {
				if regex.numberOfMatches(in: row, options: .anchored, range: NSRange.init(location: 0, length: row.count)) == 0 && index != 0{
					rows[index-1] = rows[index-1] + "\t" + "\(row)"
					rows[index] = ""
				}
			}
		}
		// Remove the now empty 'notes' rows
		rows = rows.filter { !$0.isEmpty }
		
		return rows
	}
	
}



//
//func createCalendarEventsFromArray(_ events: Array<Workday>, addTimeOff: Bool) {
//
//    var eventStore : EKEventStore = EKEventStore()
//
//    switch EKEventStore.authorizationStatus(for: .event) {
//    case .authorized:
//        break
//    //insertEvent(events, eventStore: eventStore, addTimeOff: addTimeOff)
//    case .denied:
//        break
//        // TODO: access denied to calendar
//    // accessDenied()
//    case .notDetermined:
//        break
//        // 3
//        //            eventStore.requestAccessToEntityType(.event, completion:
//        //                {[weak self] (granted: Bool, error: NSError!) -> Void in
//        //                    if granted {
//        //                        self!.insertEvent(events, eventStore: eventStore, addTimeOff: addTimeOff)
//        //                    } else {
//        //                        self!.accessDenied()
//        //                    }
//    //            })
//    case .restricted:
//        print("RESTRICTED")
//    }
//}
//
//func insertEvent(events: Array<Workday>, eventStore: EKEventStore, addTimeOff: Bool) {
//
//    var numberOfEventsCreated = 0
//    //Start creating events
//    eventCreatorLoop: for day in events {
//        // If the title is Fri and the user don't want it, skip it
//        if !addTimeOff && day.activity.hasPrefix("Fri") {continue}
//
//

//        // Save the event
//        event.calendar = eventStore.defaultCalendarForNewEvents
//        // TODO : Fix try?
//        try? eventStore.save(event, span: .thisEvent, commit: false)
//        print("Saved Event")
//        numberOfEventsCreated += 1
//    }
//
//saveEvents(eventStore: eventStore, numberOfEventsCreated: numberOfEventsCreated)

// TODO: Save events to calendar - Remove Alert Controllers

//    func saveEvents(eventStore: EKEventStore, numberOfEventsCreated: Int) {
//
//        if numberOfEventsCreated > 0 {
//            // Setup an alert letting the user know how many new events were created
//            var refreshAlert = UIAlertController(title: "Events created", message: "\(numberOfEventsCreated) new events were created", preferredStyle: UIAlertControllerStyle.Alert)
//
//            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
//            }))
//
//
//            // Present an action letting the user choose if they want to save
//            var saveAlert = UIAlertController(title: "Save events", message: "\(numberOfEventsCreated) new events will be created", preferredStyle: UIAlertControllerStyle.ActionSheet)
//
//            saveAlert.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action: UIAlertAction!) in
//                eventStore.commit()
//                // Display alert
//                self.presentViewController(refreshAlert, animated: true, completion: nil)
//                print("Events saved successfully")
//            }))
//
//            saveAlert.addAction(UIAlertAction(title: "Dismiss", style: .Cancel , handler: { (action: UIAlertAction!) in
//                eventStore.reset()
//            }))
//
//            //iPad suport
//            saveAlert.popoverPresentationController?.sourceView = self.view
//            saveAlert.popoverPresentationController?.sourceRect = CGRectMake(self.view.bounds.width / 2.0, self.view.bounds.height, 1.0, 1.0) // this is the center bottom of the screen
//
//            self.presentViewController(saveAlert, animated: true, completion: nil)
//        }
//        else {
//            var refreshAlert = UIAlertController(title: "No new events", message: "There are no new events to be created", preferredStyle: UIAlertControllerStyle.Alert)
//
//            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
//            }))
//            self.presentViewController(refreshAlert, animated: true, completion: nil)
//        }
//    }



