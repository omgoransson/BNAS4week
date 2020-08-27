//
//  Day.swift
//  BNAS4week
//
//  Created by Ola Göransson on 2020-07-20.
//

import Foundation

struct Day {
  let id = UUID()
  let date: Date
  var activity: String
  var location: String

  var startTime: Date?
  var endTime: Date?
  var reportingTime: Date?
  var details: String?
  var notes: String?
}

extension Day: Identifiable {}

extension Day {
  static var mockDay: Day {
    get {
      Day(date: Date.init(timeIntervalSinceReferenceDate: 616888800), activity: "A", location: "ENBR", startTime: Date.init(timeIntervalSinceReferenceDate: 616889800), endTime: Date.init(timeIntervalSinceReferenceDate: 616890800), reportingTime: Date.init(timeIntervalSinceReferenceDate: 616889800), details: "1100 / Stby St\n1200 / BHL001 / OGO\n1300 / BHL002 / OGO\n1500 / Stby E", notes: "Test")
    }
  }
}

extension Day {
  static var mockDays: [Day] {
    get {
      [
        Day(date: Date.init(timeIntervalSinceReferenceDate: 616888800), activity: "A", location: "ENBR", startTime: Date.init(timeIntervalSinceReferenceDate: 616889800), endTime: Date.init(timeIntervalSinceReferenceDate: 616890800), reportingTime: Date.init(timeIntervalSinceReferenceDate: 616889800), details: "1100 / Stby St\n1200 / BHL001 / OGO\n1300 / BHL002 / OGO\n1500 / Stby E", notes: "Really long note to test how it looks"),
        Day(date: Date.init(timeIntervalSinceReferenceDate: 616888800), activity: "A", location: "ENBR", startTime: Date.init(timeIntervalSinceReferenceDate: 616889800), endTime: Date.init(timeIntervalSinceReferenceDate: 616890800), reportingTime: Date.init(timeIntervalSinceReferenceDate: 616889800), details: "1100 - Stby St\n1200 - BHL001 - OGO\n1300 - BHL002 - OGO\n1500 - Stby E", notes: "Test"),
        Day(date: Date.init(timeIntervalSinceReferenceDate: 616888800), activity: "A", location: "ENBR", startTime: Date.init(timeIntervalSinceReferenceDate: 616889800), endTime: Date.init(timeIntervalSinceReferenceDate: 616890800), reportingTime: Date.init(timeIntervalSinceReferenceDate: 616889800), details: "1100   Stby St\n1200   BHL001   OGO\n1300   BHL002   OGO\n1500   Stby E", notes: "Test"),
        Day(date: Date.init(timeIntervalSinceReferenceDate: 616888800), activity: "A", location: "ENBR", startTime: Date.init(timeIntervalSinceReferenceDate: 616889800), endTime: Date.init(timeIntervalSinceReferenceDate: 616890800), reportingTime: Date.init(timeIntervalSinceReferenceDate: 616889800), details: "1100   Stby St\n1200   BHL001 - OGO\n1300   BHL002 - OGO\n1500   Stby E", notes: "Test"),
       ]
    }
  }
}
