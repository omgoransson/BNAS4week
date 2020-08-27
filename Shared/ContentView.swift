//
//  ContentView.swift
//  Shared
//
//  Created by Ola Göransson on 2020-07-20.
//

import SwiftUI

struct ContentView: View {
  var body: some View {
    NavigationView {
      List(Day.mockDays) { day in
        DayView(day: day)
      }
      .navigationBarTitle("BNAS 4 week schedule", displayMode: .inline)
    }
    .navigationViewStyle(StackNavigationViewStyle())
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ContentView()
        .previewDevice("iPhone 11 Pro Max")
        .environment(\.locale, Locale.init(identifier: "sv-SE"))
        .previewDisplayName(Locale.current.debugDescription)
      ContentView()
        .preferredColorScheme(.dark)
        .previewDevice("iPhone 11 Pro Max")
  
        .previewDisplayName(Locale.current.debugDescription)
        
        
      
      ContentView()
        .environment(\.sizeCategory, .extraExtraExtraLarge)
        .previewDevice("iPhone SE (2nd generation)")
        .environment(\.locale, .init(identifier: "sv-SE"))
      ContentView()
        .previewDevice("iPad Air (3rd generation)")
        .environment(\.locale, .init(identifier: "sv-SE"))
      ContentView()
        .previewDevice("iPad Pro (12.9-inch) (4th generation)")
        .environment(\.locale, .init(identifier: "sv-SE"))
    }
  }
}


struct DayView: View {
  let day: Day
  var body: some View {
    
    VStack {
      HStack {
        DateView(date: day.date)
        
        VStack(alignment: .leading, spacing: /*@START_MENU_TOKEN@*/nil/*@END_MENU_TOKEN@*/) {
          HStack(alignment: .firstTextBaseline) {
            Spacer()
            
            TimeView(startTime: day.startTime!, endTime: day.endTime!)
            
            Spacer()
            
            ReportingTimeView(reportingTime: day.reportingTime!)
          }
          HStack {
            Text(day.details!)
              .font(Font.system(.body, design: .default).monospacedDigit())
              .multilineTextAlignment(.leading)
              .padding([.top, .leading, .bottom])
            
            Spacer()
            
            Text(day.activity)
              .font(.callout)
          }
        }
      }
      HStack(alignment: .firstTextBaseline) {
        Text("Notes:")
          .foregroundColor(.secondary)
        Text(day.notes!)
        Spacer()
      }
      .font(.caption)
    }
    .padding(.all)
    
  }
  
}


struct DateView: View {
  let date: Date
  
  var body: some View {
    VStack(alignment: .center) {
      Text(date.weekdayFormat())
        .font(.callout)
        .textCase(.uppercase)
      Text(date.dayFormat())
        .font(.largeTitle)
        .fontWeight(.heavy)
      Text(date.monthYearFormat())
        .font(.callout)
        .textCase(.uppercase)
    }
    .foregroundColor(.accentColor)
  }
}

struct TimeView: View {
  let startTime: Date
  let endTime: Date
  
  var body: some View {
    
    
    
    
    VStack(spacing: 12) {
      Text(Image(systemName: "calendar.badge.clock"))
        .font(.title3)
        .foregroundColor(.accentColor)
      
      HStack(alignment: .center) {

        Text(startTime, style: .time)
          .font(.title3)
          .fontWeight(.bold)
        
        Text("-")
          .font(.title3)
          .fontWeight(.bold)
        
        Text(endTime, style: .time)
          .font(.title3)
          .fontWeight(.bold)
        
      }
    }
  }
}

struct ReportingTimeView: View {
  let reportingTime: Date
  
  var body: some View {
    VStack(spacing: 0) {
      Text(Image(systemName: "calendar.badge.exclamationmark"))
        .font(.title3)
        .foregroundColor(.accentColor)
      
      DatePicker.init("Reporting Time", selection: .constant(reportingTime), displayedComponents: .hourAndMinute)
        .datePickerStyle(GraphicalDatePickerStyle())
        .labelsHidden()
        .frame(width: 100, height: 50)
    }
  }
}

extension Date {
  func dayFormat() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd"
    return formatter.string(from: self)
  }
  func weekdayFormat() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "E"
    return formatter.string(from: self)
  }
  func monthYearFormat() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM yy"
    return formatter.string(from: self)
  }
}
