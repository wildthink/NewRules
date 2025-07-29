import SwiftUI

struct ScheduleKeyboardView: View {
    enum Mode { case weekdays, months, numbers, year }
    @Binding var schedule: Schedule
    @Binding var humanReadable: String
    @State private var mode: Mode = .weekdays
    @State private var numberInput: String = ""
    @State private var yearInput: String = ""
    @State private var selectedOrdinal: Int? = nil // nil = Every
    
    let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    let months = Calendar.current.shortMonthSymbols
    let days = Array(1...31)
    
    private static let digitKeys: [String] = ["1","2","3","4","5","6","7","8","9","0"]
    
    var body: some View {
        VStack(spacing: 8) {
            // Mode toggle
            HStack {
                Button(action: { mode = .weekdays }) {
                    Image(systemName: "calendar")
                        .foregroundColor(mode == .weekdays ? .blue : .primary)
                }
                Spacer()
                Button(action: { mode = .months }) {
                    Image(systemName: "calendar.circle")
                        .foregroundColor(mode == .months ? .blue : .primary)
                }
                Spacer()
                Button(action: { mode = .numbers }) {
                    Image(systemName: "123.rectangle")
                        .foregroundColor(mode == .numbers ? .blue : .primary)
                }
                Spacer()
                Button(action: { mode = .year }) {
                    Image(systemName: "number.square")
                        .foregroundColor(mode == .year ? .blue : .primary)
                }
            }
            .font(.title2)
            .padding(.horizontal)

            // Weekday pad with ordinal column
            if mode == .weekdays {
                let ordinals: [(String, Int?)] = [
                    ("1st", 1),
                    ("2nd", 2),
                    ("3rd", 3),
                    ("Last", -1),
                    ("Every", nil)
                ]
                HStack(alignment: .top, spacing: 8) {
                    VStack(spacing: 8) {
                        ForEach(ordinals, id: \.1) { label, value in
                            Button(action: {
                                selectedOrdinal = value
                                schedule.ordinal = value
                                updateHumanReadable()
                            }) {
                                Text(label)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background((selectedOrdinal == value || (selectedOrdinal == nil && value == nil)) ? Color.green.opacity(0.3) : Color.green.opacity(0.12))
                                    .foregroundColor(.primary)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    VStack(spacing: 8) {
                        ForEach(0..<5) { row in
                            HStack(spacing: 8) {
                                ForEach(0..<2) { col in
                                    let idx = row * 2 + col
                                    if row == 4 && col == 1 {
                                        // Bottom trailing spot: cancel key
                                        Button(action: {
                                            schedule.weekdays = []
                                            selectedOrdinal = nil
                                            schedule.ordinal = nil
                                            updateHumanReadable()
                                        }) {
                                            Image(systemName: "xmark.circle")
                                                .frame(maxWidth: .infinity, minHeight: 44)
                                                .background(Color.red.opacity(0.12))
                                                .foregroundColor(.red)
                                                .cornerRadius(8)
                                        }
                                    } else if idx < weekdays.count {
                                        let day = weekdays[idx]
                                        Button(action: {
                                            let opt = WeekdayOptions(rawValue: 1 << idx)
                                            if schedule.weekdays.contains(opt) {
                                                schedule.weekdays.remove(opt)
                                            } else {
                                                schedule.weekdays.insert(opt)
                                            }
                                            updateHumanReadable()
                                        }) {
                                            Text(day)
                                                .frame(maxWidth: .infinity, minHeight: 44)
                                                .background(schedule.weekdays.contains(WeekdayOptions(rawValue: 1 << idx)) ? Color.blue : Color.gray.opacity(0.2))
                                                .foregroundColor(.primary)
                                                .cornerRadius(8)
                                        }
                                    } else {
                                        Spacer().frame(maxWidth: .infinity, minHeight: 44)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
            } else {
                // Keypad grid (3x5) for other modes
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(Array(keysForMode().enumerated()), id: \.offset) { idx, key in
                        if key == "delete.left" {
                            Button(action: { handleKeyTap(key) }) {
                                Image(systemName: key)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.red)
                                    .cornerRadius(8)
                            }
                        } else {
                            Button(action: { handleKeyTap(key) }) {
                                Text(key)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(keyBackgroundColor(key))
                                    .foregroundColor(keyForegroundColor(key))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            
            // Input display
            if mode == .numbers {
                Text(numberInput.isEmpty ? "Enter day of month" : numberInput)
                    .font(.title2)
                    .padding(.vertical, 4)
            } else if mode == .year {
                Text(yearInput.isEmpty ? "Enter year" : yearInput)
                    .font(.title2)
                    .padding(.vertical, 4)
            }

            // Remove old control row with Clear button
        }
        .padding(.vertical)
    }
    
    private func keysForMode() -> [String] {
        let clearSymbol = "delete.left"
        switch mode {
        case .weekdays:
            var keys = weekdays
            while keys.count < 14 { keys.append("") }
            keys.append(clearSymbol)
            return keys
        case .months:
            var keys = months
            while keys.count < 14 { keys.append("") }
            keys.append(clearSymbol)
            return keys
        case .numbers, .year:
            var keys = Self.digitKeys
            while keys.count < 14 { keys.append("") }
            keys.append(clearSymbol)
            return keys
        }
    }

    private func handleKeyTap(_ key: String) {
        let clearSymbol = "delete.left"
        if key == clearSymbol {
            clearCurrent()
            return
        }
        switch mode {
        case .weekdays:
            if let idx = weekdays.firstIndex(of: key) {
                let opt = WeekdayOptions(rawValue: 1 << idx)
                if schedule.weekdays.contains(opt) {
                    schedule.weekdays.remove(opt)
                } else {
                    schedule.weekdays.insert(opt)
                }
            }
        case .months:
            if let idx = months.firstIndex(of: key) {
                let opt = MonthOptions(rawValue: 1 << idx)
                if schedule.months.contains(opt) {
                    schedule.months.remove(opt)
                } else {
                    schedule.months.insert(opt)
                }
            }
        case .numbers:
            if key.allSatisfy({ $0.isNumber }) {
                if numberInput == "0" { numberInput = "" }
                numberInput.append(key)
                if let day = Int(numberInput), (1...31).contains(day) {
                    schedule.days = DayOfMonth.from([day])
                } else if let day = Int(numberInput), day > 31 {
                    numberInput = ""
                }
            }
        case .year:
            if key.allSatisfy({ $0.isNumber }) {
                if yearInput == "0" { yearInput = "" }
                yearInput.append(key)
                if yearInput.count > 4 { yearInput = String(yearInput.prefix(4)) }
                if let year = Int(yearInput), yearInput.count == 4 {
                    schedule.year = year
                }
            }
        }
        updateHumanReadable()
    }

    private func keyBackgroundColor(_ key: String) -> Color {
        switch mode {
        case .weekdays:
            if let idx = weekdays.firstIndex(of: key) {
                let opt = WeekdayOptions(rawValue: 1 << idx)
                return schedule.weekdays.contains(opt) ? .blue : .gray.opacity(0.2)
            }
        case .months:
            if let idx = months.firstIndex(of: key) {
                let opt = MonthOptions(rawValue: 1 << idx)
                return schedule.months.contains(opt) ? .blue : .gray.opacity(0.2)
            }
        case .numbers:
            if let day = Int(key), schedule.days.contains(day) {
                return .blue
            }
        case .year:
            if let year = Int(key), yearInput.count == 4 && year == Int(yearInput) {
                return .blue
            }
        }
        return .gray.opacity(0.2)
    }

    private func keyForegroundColor(_ key: String) -> Color {
        switch mode {
        case .weekdays, .months, .numbers, .year:
            return .primary
        }
    }

    private func clearCurrent() {
        switch mode {
        case .weekdays:
            schedule.weekdays = []
            selectedOrdinal = nil
            schedule.ordinal = nil
        case .months:
            schedule.months = []
        case .numbers:
            schedule.days = DayOfMonth()
            numberInput = ""
        case .year:
            schedule.year = nil
            yearInput = ""
        }
        updateHumanReadable()
    }

    private func updateHumanReadable() {
        humanReadable = schedule.toHumanString()
    }
}

struct ScheduleKeyboardDemo: View {
    @State private var schedule = Schedule()
    @State private var humanReadable: String = "every day"
    
    var body: some View {
        VStack(spacing: 12) {
            Text("DSL: \(schedule.toDSL())")
                .font(.headline)
            Text(humanReadable)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            ScheduleKeyboardView(schedule: $schedule, humanReadable: $humanReadable)
        }
        .padding()
        .frame(width: 300, height: 500)
    }
}

#Preview {
    ScheduleKeyboardDemo()
}
