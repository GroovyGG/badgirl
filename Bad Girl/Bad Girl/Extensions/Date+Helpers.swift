import Foundation

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: components) ?? self
    }

    var endOfMonth: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? self
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    var shortWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: self)
    }

    var dayNumber: Int {
        Calendar.current.component(.day, from: self)
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: self)
    }

    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: self)
    }
}

extension Calendar {
    func daysInMonth(for date: Date) -> [Date?] {
        guard let range = self.range(of: .day, in: .month, for: date),
              let firstDay = self.date(from: self.dateComponents([.year, .month], from: date))
        else { return [] }

        let firstWeekday = self.component(.weekday, from: firstDay)
        // Adjust for Monday-first week (1=Sun in Calendar, shift to Mon-first)
        let offset = (firstWeekday + 5) % 7

        var days: [Date?] = Array(repeating: nil, count: offset)
        for day in range {
            if let d = self.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(d)
            }
        }
        return days
    }
}
