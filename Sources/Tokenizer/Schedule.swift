//
//  Schedule.swift
//  NewRules
//
//  Created by Jason Jobe on 7/28/25.
//


import Foundation

// MARK: - OptionSets for Months and Weekdays
struct MonthOptions: OptionSet {
    let rawValue: UInt16
    static let january   = MonthOptions(rawValue: 1 << 0)
    static let february  = MonthOptions(rawValue: 1 << 1)
    static let march     = MonthOptions(rawValue: 1 << 2)
    static let april     = MonthOptions(rawValue: 1 << 3)
    static let may       = MonthOptions(rawValue: 1 << 4)
    static let june      = MonthOptions(rawValue: 1 << 5)
    static let july      = MonthOptions(rawValue: 1 << 6)
    static let august    = MonthOptions(rawValue: 1 << 7)
    static let september = MonthOptions(rawValue: 1 << 8)
    static let october   = MonthOptions(rawValue: 1 << 9)
    static let november  = MonthOptions(rawValue: 1 << 10)
    static let december  = MonthOptions(rawValue: 1 << 11)
    static let all: MonthOptions = [
        .january, .february, .march, .april, .may, .june, .july, .august, .september, .october, .november, .december
    ]
}

struct WeekdayOptions: OptionSet {
    let rawValue: UInt8
    static let sunday    = WeekdayOptions(rawValue: 1 << 0)
    static let monday    = WeekdayOptions(rawValue: 1 << 1)
    static let tuesday   = WeekdayOptions(rawValue: 1 << 2)
    static let wednesday = WeekdayOptions(rawValue: 1 << 3)
    static let thursday  = WeekdayOptions(rawValue: 1 << 4)
    static let friday    = WeekdayOptions(rawValue: 1 << 5)
    static let saturday  = WeekdayOptions(rawValue: 1 << 6)
    static let all: WeekdayOptions = [
        .sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday
    ]
}

// MARK: - Bit Array for Days of Month
struct DayOfMonth {
    private var bits: UInt32 = 0
    static let allDays: DayOfMonth = {
        var dom = DayOfMonth()
        dom.bits = 0x7FFFFFFF // 31 bits set
        return dom
    }()
    
    init() {}
    init(bits: UInt32) { self.bits = bits }
    
    func contains(_ day: Int) -> Bool {
        guard (1...31).contains(day) else { return false }
        return (bits & (1 << (day - 1))) != 0
    }
    
    mutating func insert(_ day: Int) {
        guard (1...31).contains(day) else { return }
        bits |= (1 << (day - 1))
    }
    
    mutating func remove(_ day: Int) {
        guard (1...31).contains(day) else { return }
        bits &= ~(1 << (day - 1))
    }
    
    var selectedDays: [Int] {
        (1...31).filter { contains($0) }
    }
    
    static func from(_ days: [Int]) -> DayOfMonth {
        var dom = DayOfMonth()
        for d in days { dom.insert(d) }
        return dom
    }
}

// MARK: - Refactored Schedule
struct Schedule {
    var year: Int? = nil
    var months: MonthOptions = []
    var days: DayOfMonth = DayOfMonth()
    var weekdays: WeekdayOptions = []
    var ordinal: Int? = nil // 1 = first, -1 = last
    var time: String? = nil // Will refactor to DateComponents later
}

enum ScheduleParseError: Error {
    case invalidFormat(String)
}

struct ScheduleParser {
    static func parse(_ input: String) throws -> Schedule {
        var schedule = Schedule()
        var scanner = Scanner(string: input)
        scanner.charactersToBeSkipped = nil
        
        // YEAR (first 4 digits)
        if let yearStr = scanner.scanCharacters(from: .decimalDigits), yearStr.count == 4 {
            schedule.year = Int(yearStr)
        }
        
        // MONTH pattern
        if scanner.scanString("m") != nil {
            let pattern = scanPattern(&scanner)
            schedule.months = parseMonthPattern(pattern)
        }
        // DAY pattern
        if scanner.scanString("d") != nil {
            let pattern = scanPattern(&scanner)
            schedule.days = parseDayPattern(pattern)
        }
        // WEEKDAY + ORDINAL
        if scanner.scanString("[") != nil {
            let content = scanner.scanUpToString("]") ?? ""
            scanner.scanString("]")
            let parts = content.split(separator: ":")
            schedule.weekdays = parseWeekdayPattern(String(parts[0]))
            if parts.count > 1, let ord = Int(parts[1]) {
                schedule.ordinal = ord
            }
        }
        // TIME
        schedule.time = scanner.scanUpToCharacters(from: .whitespacesAndNewlines)
        return schedule
    }
    
    private static func scanPattern(_ scanner: inout Scanner) -> String {
        return scanner.scanCharacters(from: CharacterSet(charactersIn: "*/-0123456789")) ?? "*"
    }
    
    private static func parseMonthPattern(_ pattern: String) -> MonthOptions {
        if pattern == "*" { return .all }
        var result: MonthOptions = []
        let comps = pattern.split(separator: "/").first?.split(separator: "-") ?? []
        if comps.count == 2, let start = Int(comps[0]), let end = Int(comps[1]) {
            for m in start...end { result.insert(MonthOptions(rawValue: 1 << (m-1))) }
        } else if let m = Int(pattern) {
            result.insert(MonthOptions(rawValue: 1 << (m-1)))
        }
        return result
    }
    private static func parseDayPattern(_ pattern: String) -> DayOfMonth {
        if pattern == "*" { return .allDays }
        let days = pattern.split(separator: ",").compactMap { Int($0) }
        return DayOfMonth.from(days)
    }
    private static func parseWeekdayPattern(_ pattern: String) -> WeekdayOptions {
        if pattern == "*" { return .all }
        let map: [String: WeekdayOptions] = [
            "Sun": .sunday, "Mon": .monday, "Tue": .tuesday, "Wed": .wednesday,
            "Thu": .thursday, "Fri": .friday, "Sat": .saturday
        ]
        var result: WeekdayOptions = []
        let parts = pattern.split(separator: "-")
        if parts.count == 2, let start = map[String(parts[0])], let end = map[String(parts[1])] {
            let all = [WeekdayOptions.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
            if let s = all.firstIndex(of: start), let e = all.firstIndex(of: end) {
                for i in s...e { result.insert(all[i]) }
            }
        } else if let w = map[pattern] {
            result.insert(w)
        }
        return result
    }
}

extension Schedule {
    func toDSL() -> String {
        var dsl = ""
        if let y = year { dsl += "\(y)" }
        if !months.isEmpty { dsl += "m" + monthsToPattern(months) }
        if !days.selectedDays.isEmpty { dsl += "d" + daysToPattern(days) }
        if !weekdays.isEmpty {
            dsl += "[" + weekdaysToPattern(weekdays)
            if let ord = ordinal { dsl += ":\(ord)" }
            dsl += "]"
        }
        if let t = time { dsl += "@\(t)" }
        return dsl.isEmpty ? "*" : dsl
    }
    func toHumanString(locale: Locale = .current) -> String {
        var parts: [String] = []
        let monthsString = monthsToHumanString(months, locale: locale)
        let daysString = daysToHumanString(days)
        let weekdaysString = weekdaysToHumanString(weekdays, locale: locale)

        if let y = year {
            parts.append("in \(y)")
        }
        if !days.selectedDays.isEmpty {
            if !months.isEmpty {
                parts.append("\(daysString) of \(monthsString)")
            } else {
                parts.append(daysString)
            }
        } else if !months.isEmpty {
            parts.append(monthsString)
        }
        if !weekdays.isEmpty {
            if let ord = ordinal {
                parts.append("\(ordinalWord(ord)) \(weekdaysString)")
            } else {
                parts.append("every \(weekdaysString)")
            }
        }
        if let t = time {
            parts.append("at \(t)")
        }
        return parts.isEmpty ? "every day" : parts.joined(separator: ", ")
    }
}
// MARK: - Pattern helpers
private func monthsToPattern(_ months: MonthOptions) -> String {
    if months == .all { return "*" }
    let all = Array(1...12)
    let selected = all.filter { months.contains(MonthOptions(rawValue: 1 << ($0 - 1))) }
    return rangePattern(from: selected)
}

private func daysToPattern(_ days: DayOfMonth) -> String {
    let selected = days.selectedDays
    if selected.count == 31 { return "*" }
    return rangePattern(from: selected)
}

private func weekdaysToPattern(_ weekdays: WeekdayOptions) -> String {
    if weekdays == .all { return "*" }
    let all: [(String, Int)] = [("Sun", 0), ("Mon", 1), ("Tue", 2), ("Wed", 3), ("Thu", 4), ("Fri", 5), ("Sat", 6)]
    let selected = all.compactMap { weekdays.contains(WeekdayOptions(rawValue: 1 << $0.1)) ? $0.0 : nil }
    // Convert to indices for range detection
    let indices = all.compactMap { weekdays.contains(WeekdayOptions(rawValue: 1 << $0.1)) ? $0.1 : nil }
    let pattern = rangePattern(from: indices).replacingOccurrences(of: "-", with: "-", options: [], range: nil)
    // Map back to weekday names for ranges
    if pattern.contains("-") {
        let parts = pattern.split(separator: ",").map { String($0) }
        return parts.map { part in
            if let dash = part.firstIndex(of: "-") {
                let startIdx = Int(String(part[..<dash])) ?? 0
                let endIdx = Int(String(part[part.index(after: dash)...])) ?? 0
                return "\(all[startIdx].0)-\(all[endIdx].0)"
            } else if let idx = Int(part) {
                return all[idx].0
            } else {
                return part
            }
        }.joined(separator: ",")
    } else {
        return selected.joined(separator: ",")
    }
}

private func rangePattern(from values: [Int]) -> String {
    guard !values.isEmpty else { return "" }
    var result: [String] = []
    var start = values[0]
    var prev = values[0]
    for (i, val) in values.enumerated().dropFirst() {
        if val == prev + 1 {
            prev = val
        } else {
            if start == prev {
                result.append("\(start)")
            } else {
                result.append("\(start)-\(prev)")
            }
            start = val
            prev = val
        }
        if i == values.count - 1 {
            if start == prev {
                result.append("\(start)")
            } else {
                result.append("\(start)-\(prev)")
            }
        }
    }
    if result.isEmpty {
        result.append("\(start)")
    }
    return result.joined(separator: ",")
}
private func ordinalWord(_ ord: Int) -> String {
    switch ord {
    case 1: return "first"
    case 2: return "second"
    case 3: return "third"
    case -1: return "last"
    default: return "#\(ord)"
    }
}

// MARK: Helper functions
extension Calendar {
    var shortWeekdaySymbolsLocalized: [String] {
        self.shortWeekdaySymbols
    }
    
    var shortMonthSymbolsLocalized: [String] {
        self.shortMonthSymbols
    }
}

var mondayFirstWeekdays: [String] {
    var days = Calendar.current.shortWeekdaySymbols
    let sunday = days.removeFirst()
    days.append(sunday)
    return days
}

private func localizedWeekday(_ code: String, locale: Locale) -> String {
    let calendar = Calendar(identifier: .gregorian)
    let symbols = calendar.shortWeekdaySymbols
    // Normalize code like "Mon" or "Mon-Fri"
    if code.contains("-") {
        let parts = code.split(separator: "-").map { String($0) }
        let localized = parts.compactMap { mapToLocalizedWeekday($0, symbols: symbols) }
        return localized.joined(separator: "–")
    }
    return mapToLocalizedWeekday(code, symbols: symbols) ?? code
}

private func mapToLocalizedWeekday(_ code: String, symbols: [String]) -> String? {
    let english = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    if let idx = english.firstIndex(of: code) {
        return symbols[idx]
    }
    return nil
}

private func describeMonthPattern(_ months: MonthOptions, locale: Locale) -> String {
    if months == .all { return "every" } // All months selected
    let calendar = Calendar(identifier: .gregorian)
    let monthSymbols = calendar.shortMonthSymbols
    var selectedMonths: [String] = []
    if months.contains(.january) { selectedMonths.append(monthSymbols[0]) }
    if months.contains(.february) { selectedMonths.append(monthSymbols[1]) }
    if months.contains(.march) { selectedMonths.append(monthSymbols[2]) }
    if months.contains(.april) { selectedMonths.append(monthSymbols[3]) }
    if months.contains(.may) { selectedMonths.append(monthSymbols[4]) }
    if months.contains(.june) { selectedMonths.append(monthSymbols[5]) }
    if months.contains(.july) { selectedMonths.append(monthSymbols[6]) }
    if months.contains(.august) { selectedMonths.append(monthSymbols[7]) }
    if months.contains(.september) { selectedMonths.append(monthSymbols[8]) }
    if months.contains(.october) { selectedMonths.append(monthSymbols[9]) }
    if months.contains(.november) { selectedMonths.append(monthSymbols[10]) }
    if months.contains(.december) { selectedMonths.append(monthSymbols[11]) }
    if selectedMonths.count == 1 { return selectedMonths[0] }
    if selectedMonths.count == 2 { return selectedMonths.joined(separator: " and ") }
    return selectedMonths.joined(separator: ", ")
}
// MARK: - Quick Tests
func testSchedules() {
    let examples = [
        "2025m1",          // First of month in 2025
        "ym[Mon]",         // Every Monday
        "ym[Mon:1]",       // First Monday each month
        "2025[Mon:1]",     // First Monday in 2025
        "ym[Fri:-1]",      // Last Friday each month
        "[Mon-Fri]@09:00", // Weekdays at 9
        "m1-6/2d*/2",      // Month range + step, every 2 days
        "m*/3"             // Every 3 months
    ]
    
    for ex in examples {
        do {
            let sched = try ScheduleParser.parse(ex)
            print("Original DSL: \(ex)")
            print("Human: \(sched.toHumanString())")
            print("Round-Trip DSL: \(sched.toDSL())")
            print("-----")
        } catch {
            print("Failed to parse \(ex): \(error)")
        }
    }
}

private func monthsToHumanString(_ months: MonthOptions, locale: Locale) -> String {
    if months == .all { return "every month" }
    let calendar = Calendar(identifier: .gregorian)
    var calendarWithLocale = calendar
    calendarWithLocale.locale = locale
    let monthSymbols = calendarWithLocale.shortMonthSymbols
    let all = Array(1...12)
    let selected = all.filter { months.contains(MonthOptions(rawValue: 1 << ($0 - 1))) }
    let ranges = contiguousRanges(selected)
    let abbrevs = ranges.map { range -> String in
        if range.count == 1 {
            return monthSymbols[range.lowerBound - 1]
        } else {
            return "\(monthSymbols[range.lowerBound - 1])-\(monthSymbols[range.upperBound - 1])"
        }
    }
    return abbrevs.joined(separator: ",")
}

private func daysToHumanString(_ days: DayOfMonth) -> String {
    let selected = days.selectedDays
    if selected.count == 31 { return "every day" }
    let ordinals = selected.map { ordinalDay($0) }
    let ranges = contiguousRanges(selected)
    let ordRange = ranges.map { range -> String in
        if range.count == 1 {
            return ordinalDay(range.lowerBound)
        } else {
            return "\(ordinalDay(range.lowerBound))-\(ordinalDay(range.upperBound))"
        }
    }
    return ordRange.joined(separator: ",")
}

private func weekdaysToHumanString(_ weekdays: WeekdayOptions, locale: Locale) -> String {
    if weekdays == .all { return "every day" }
    let all: [(String, Int)] = [("Sun", 0), ("Mon", 1), ("Tue", 2), ("Wed", 3), ("Thu", 4), ("Fri", 5), ("Sat", 6)]
    let selected = all.compactMap { weekdays.contains(WeekdayOptions(rawValue: 1 << $0.1)) ? $0.0 : nil }
    let indices = all.compactMap { weekdays.contains(WeekdayOptions(rawValue: 1 << $0.1)) ? $0.1 : nil }
    let ranges = contiguousRanges(indices)
    let abbrevs = ranges.map { range -> String in
        if range.count == 1 {
            return all[range.lowerBound].0
        } else {
            return "\(all[range.lowerBound].0)-\(all[range.upperBound].0)"
        }
    }
    return abbrevs.joined(separator: ",")
}

private func ordinalDay(_ n: Int) -> String {
    let suffix: String
    let ones = n % 10
    let tens = (n / 10) % 10
    if tens == 1 {
        suffix = "th"
    } else {
        switch ones {
        case 1: suffix = "st"
        case 2: suffix = "nd"
        case 3: suffix = "rd"
        default: suffix = "th"
        }
    }
    return "\(n)\(suffix)"
}

private func contiguousRanges(_ values: [Int]) -> [ClosedRange<Int>] {
    guard !values.isEmpty else { return [] }
    var result: [ClosedRange<Int>] = []
    var start = values[0]
    var prev = values[0]
    for val in values.dropFirst() {
        if val == prev + 1 {
            prev = val
        } else {
            result.append(start...prev)
            start = val
            prev = val
        }
    }
    result.append(start...prev)
    return result
}

