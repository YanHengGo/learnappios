import Foundation

/// Android の java.time.YearMonth 相当
public struct YearMonth: Equatable, Comparable {
    public let year: Int
    public let month: Int   // 1–12

    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    /// 今月（Android: YearMonth.now()）
    public static var now: YearMonth {
        let c = Calendar.current
        let d = Date()
        return YearMonth(
            year: c.component(.year, from: d),
            month: c.component(.month, from: d)
        )
    }

    /// 月初日を "yyyy-MM-dd" で返す（Android: yearMonth.atDay(1).toString()）
    public func firstDayString() -> String {
        String(format: "%04d-%02d-01", year, month)
    }

    /// 月末日を "yyyy-MM-dd" で返す（Android: yearMonth.atEndOfMonth().toString()）
    public func lastDayString() -> String {
        var components = DateComponents()
        components.year = year
        components.month = month + 1
        components.day = 0
        let lastDate = Calendar.current.date(from: components)!
        let day = Calendar.current.component(.day, from: lastDate)
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    /// 月を加算（Android: plusMonths / minusMonths）
    public func adding(months: Int) -> YearMonth {
        var m = month - 1 + months
        var y = year
        if m >= 0 {
            y += m / 12
            m = m % 12
        } else {
            let borrow = (-m + 11) / 12
            y -= borrow
            m = m + borrow * 12
        }
        return YearMonth(year: y, month: m + 1)
    }

    public static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        lhs.year != rhs.year ? lhs.year < rhs.year : lhs.month < rhs.month
    }
}
