import SwiftUI

struct ScheduleKeyboardView: View {
    enum Mode { case year, months, numbers, weekdays }
    @Binding var schedule: Schedule
    @State private var mode: Mode = .year
    @State private var numberInput: String = ""
    @State private var yearInput: String = ""
    @State private var selectedOrdinal: Int? = nil // nil = Every
    
    let weekdays = Calendar.current.shortWeekdaySymbols
    let months = Calendar.current.shortMonthSymbols
    let days = Array(1...31)
    
    private static let digitKeys: [String] = ["1","2","3","4","5","6","7","8","9","0"]
    
    var body: some View {
        TabView(selection: $mode) {
            digitPad
                .tag(Mode.year)
                .tabItem {
                    Image(systemName: "number.square")
                    Text("Year")
                }
            
            monthPad
                .tag(Mode.months)
                .tabItem {
                    Image(systemName: "calendar.circle")
                    Text("Months")
                }
            
            digitPad
                .tag(Mode.numbers)
                .tabItem {
                    Image(systemName: "123.rectangle")
                    Text("Day")
                }
            
            weekdayPad
                .tag(Mode.weekdays)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Weekdays")
                }
        }
        .padding(.vertical)
    }

    // MARK: - Pads
    private var digitPad: some View {

        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
            ForEach(ScheduleKeyboardView.digitKeys, id: \.self) { mon in
                KeypadButton(text: mon) {
                    handleKeyTap(mon)
                }
                .background(keyBackgroundColor(mon))
                .foregroundColor(keyForegroundColor(mon))
            }
            ForEach([0, 1, 2, 3], id: \.self) { _ in
                Color.clear
            }
            let key = "delete.left"
            KeypadButton(systemSymbol: key) {
                handleKeyTap(key)
            }
        }
    }

    private var monthPad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
            ForEach(months, id: \.self) { mon in
                KeypadButton(text: mon) {
                    handleKeyTap(mon)
                }
                .background(keyBackgroundColor(mon))
                .foregroundColor(keyForegroundColor(mon))
            }
            ForEach([0, 1], id: \.self) { _ in
                Color.clear
            }
            let key = "delete.left"
            KeypadButton(systemSymbol: key) {
                handleKeyTap(key)
            }
            .background(keyBackgroundColor(key))
            .foregroundColor(keyForegroundColor(key))
        }
    }

    private var weekdayPad: some View {
        // 5x3 grid: col 1 = ordinals,
        // col 2 = [Mon, Tue, Wed, Thu, Fri],
        // col 3 = [Sat, Sun, _, _, Cancel]
        let ordinals: [(String, Int?)] = [
            ("1st", 1),
            ("2nd", 2),
            ("3rd", 3),
            ("Last", -1),
            ("Every", nil)
        ]
        let weekdays = Calendar.current.shortWeekdaySymbols
        let col2 = weekdays[1...5].map(\.description)
        let col3 = [
            weekdays[6].description,
            weekdays[0].description,
            "", "", "cancel"]
        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(0..<5) { row in
                // Ordinal column
                let (label, value) = ordinals[row]
                KeypadButton(text: label) {
                    selectedOrdinal = value
                    schedule.ordinal = value
                }
                .background((selectedOrdinal == value || (selectedOrdinal == nil && value == nil)) ? Color.green.opacity(0.3) : Color.green.opacity(0.12))
                .foregroundColor(.primary)
                // Weekday column
                let day = col2[row]
                if !day.isEmpty {
                    let isSelected = day.isEmpty ? false : (weekdays.firstIndex(of: day).map { schedule.weekdays.contains(WeekdayOptions(rawValue: 1 << $0)) } ?? false)
                    KeypadButton(text: day) {
                        if let dayIdx = weekdays.firstIndex(of: day) {
                            let opt = WeekdayOptions(rawValue: 1 << dayIdx)
                            schedule.weekdays.toggle(opt)
                        }
                    }
                    .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                } else {
                    Spacer().frame(maxWidth: .infinity, minHeight: 44)
                }
                // Sat/Sun/Cancel column
                let col3Label = col3[row]
                if col3Label == "cancel" {
                    KeypadButton(systemSymbol: "xmark.circle") {
                        schedule.weekdays = []
                        selectedOrdinal = nil
                        schedule.ordinal = nil
                    }
                    .background(Color.red.opacity(0.12))
                    .foregroundColor(.red)
                } else if !col3Label.isEmpty {
                    let isSelected = weekdays.firstIndex(of: col3Label).map { schedule.weekdays.contains(WeekdayOptions(rawValue: 1 << $0)) } ?? false
                    KeypadButton(text: col3Label) {
                        if let dayIdx = weekdays.firstIndex(of: col3Label) {
                            let opt = WeekdayOptions(rawValue: 1 << dayIdx)
                            schedule.weekdays.toggle(opt)
                        }
                    }
                    .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                } else {
                    Spacer().frame(maxWidth: .infinity, minHeight: 44)
                }
            }
        }
        .frame(maxWidth: .infinity)
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
                schedule.weekdays.toggle(opt)
            }
        case .months:
            if let idx = months.firstIndex(of: key) {
                let opt = MonthOptions(rawValue: 1 << idx)
                schedule.months.toggle(opt)
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
    }
}

extension Button {
    init(systemSymbol: String, action: @escaping () -> Void) where Label == Image {
        self = Button(action: action) {
            Image(systemName: systemSymbol)
        }
    }
}

struct KeypadButton<Label: View>: View {
    let action: () -> Void
    let label: Label
    init(background: Color = Color.gray.opacity(0.2), foreground: Color = .primary, @ViewBuilder label: () -> Label, action: @escaping () -> Void) {
        self.label = label()
        self.action = action
    }
    var body: some View {
        Button(action: action) {
            label
                .frame(maxWidth: .infinity, minHeight: 44)
                .cornerRadius(8)
        }
    }
}

extension KeypadButton {
    
    init(text: String, action: @escaping () -> Void) where Label == Text {
        self.action = action
        self.label = Text(text)
    }
    
    init(systemSymbol: String, action: @escaping () -> Void) where Label == AnyView {
        self.action = action

        self.label = AnyView(
            Image(systemName: systemSymbol)
            .frame(maxWidth: .infinity, minHeight: 44)
            .cornerRadius(8))
    }

}

struct ScheduleKeyboardDemo: View {
    @State private var schedule = Schedule()
    
    var body: some View {
        VStack {
            Text("DSL: \(schedule.toDSL())")
                .font(.headline)
            Text(schedule.toHumanString())
                .font(.subheadline)
                .padding(.bottom, 8)
            ScheduleKeyboardView(schedule: $schedule)
                .frame(width: 280, height: 280)
        }
    }
}

#Preview {
    ScheduleKeyboardDemo()
        .padding()
}
