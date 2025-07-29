import SwiftUI

struct ScheduleKeyboardView: View {
    enum Mode { case weekdays, months, numbers }
    @Binding var schedule: Schedule
    @Binding var humanReadable: String
    @State private var mode: Mode = .weekdays
    
    let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    let months = Calendar.current.shortMonthSymbols
    let days = Array(1...31)
    
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
            }
            .font(.title2)
            .padding(.horizontal)
            
            // Keypad grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(keysForMode(), id: \.self) { key in
                    Button(action: {
                        handleKeyTap(key)
                    }) {
                        Text(key)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(keyBackgroundColor(key))
                            .foregroundColor(keyForegroundColor(key))
                            .cornerRadius(8)
                    }
                }
            }
            
            // Control row
            HStack(spacing: 8) {
                Button("Clear") {
                    clearCurrent()
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                
                Button("Done") {
                    updateHumanReadable()
                }
                .frame(maxWidth: .infinity, minHeight: 44)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private func keysForMode() -> [String] {
        let extraKeys = ["", "", ""] // No extra keys for toggles
        switch mode {
        case .weekdays:
            return weekdays + extraKeys
        case .months:
            return months + extraKeys
        case .numbers:
            return days.map { String($0) }
        }
    }

    private func handleKeyTap(_ key: String) {
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
            if let day = Int(key), (1...31).contains(day) {
                schedule.days = DayOfMonth.from([day])
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
        }
        return .gray.opacity(0.2)
    }

    private func keyForegroundColor(_ key: String) -> Color {
        switch mode {
        case .weekdays, .months, .numbers:
            return .primary
        }
    }

    private func clearCurrent() {
        switch mode {
        case .weekdays:
            schedule.weekdays = []
        case .months:
            schedule.months = []
        case .numbers:
            schedule.days = DayOfMonth()
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
