//
//  ScheduleEditorView.swift
//  NewRules
//
//  Created by Jason Jobe on 7/28/25.
//

import SwiftUI
/**
 --------------------------------------
 Schedule Editor
 --------------------------------------
 [Year: 2025]   [ Month: * ]   [ Day: * ]
 
 Weekday:  [Mon ▼]   Ordinal: [1 ▼]
 Time:     [ 09:00 AM ▼ ]
 
 Summary:  "First Monday of every month at 09:00 AM"
 DSL:      ym[Mon:1]@09:00  [Edit]
 --------------------------------------
 */
struct ScheduleEditorView: View {
    @State private var schedule = Schedule()
    @State private var dslInput = ""
    @State private var showAdvanced = false
    @State private var errorMessage: String? = nil
    
    let monthSymbols = Calendar.current.shortMonthSymbols
    let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    let daysOfMonth = Array(1...31)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Schedule Editor")
                .font(.title2)
                .padding(.bottom, 8)
            
            // Year
            HStack(spacing: 12) {
                TextField("Year", value: $schedule.year, format: .number)
                    .frame(width: 80)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            // Months multi-select
            VStack(alignment: .leading) {
                Text("Months")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
                    ForEach(monthSymbols.indices, id: \ .self) { idx in
                        Toggle(monthSymbols[idx], isOn: Binding(
                            get: { schedule.months.contains(MonthOptions(rawValue: 1 << idx)) },
                            set: { on in
                                if on {
                                    schedule.months.insert(MonthOptions(rawValue: 1 << idx))
                                } else {
                                    schedule.months.remove(MonthOptions(rawValue: 1 << idx))
                                }
                            }
                        ))
                    }
                }
            }

            // Days of month multi-select
            VStack(alignment: .leading) {
                Text("Days of Month")
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                    ForEach(daysOfMonth, id: \ .self) { day in
                        Toggle("\(day)", isOn: Binding(
                            get: { schedule.days.contains(day) },
                            set: { on in
                                if on {
                                    schedule.days.insert(day)
                                } else {
                                    schedule.days.remove(day)
                                }
                            }
                        ))
                    }
                }
            }

            // Weekdays multi-select
            VStack(alignment: .leading) {
                Text("Weekdays")
                HStack {
                    ForEach(weekdaySymbols.indices, id: \ .self) { idx in
                        Toggle(weekdaySymbols[idx], isOn: Binding(
                            get: { schedule.weekdays.contains(WeekdayOptions(rawValue: 1 << idx)) },
                            set: { on in
                                if on {
                                    schedule.weekdays.insert(WeekdayOptions(rawValue: 1 << idx))
                                } else {
                                    schedule.weekdays.remove(WeekdayOptions(rawValue: 1 << idx))
                                }
                            }
                        ))
                        .toggleStyle(.button)
                    }
                }
            }

            // Ordinal Picker
            Picker("Ordinal", selection: Binding(
                get: { schedule.ordinal ?? 0 },
                set: { schedule.ordinal = $0 == 0 ? nil : $0 }
            )) {
                Text("None").tag(0)
                Text("1st").tag(1)
                Text("2nd").tag(2)
                Text("3rd").tag(3)
                Text("Last").tag(-1)
            }
            .pickerStyle(MenuPickerStyle())

            // Time picker
            DatePicker("Time", selection: Binding(
                get: {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    if let t = schedule.time, let date = formatter.date(from: t) {
                        return date
                    }
                    return Date()
                },
                set: {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    schedule.time = formatter.string(from: $0)
                }
            ), displayedComponents: .hourAndMinute)
            .labelsHidden()
            
            Divider()
            
            // Summary & DSL
            Text("Summary: \(schedule.toHumanString())")
                .font(.subheadline)
            
            HStack {
                Text("DSL: \(schedule.toDSL())")
                    .font(.caption)
                Spacer()
                Button(showAdvanced ? "Hide Advanced" : "Advanced") {
                    showAdvanced.toggle()
                    if showAdvanced {
                        dslInput = schedule.toDSL()
                    }
                }
            }
            
            if showAdvanced {
                TextField("Edit DSL", text: $dslInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: dslInput) { newVal in
                        do {
                            schedule = try ScheduleParser.parse(newVal)
                            errorMessage = nil
                        } catch {
                            errorMessage = "Invalid DSL format"
                        }
                    }
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ScheduleEditorView()
        .frame(width: 300)
}
