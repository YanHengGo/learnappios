import SwiftUI
import CoreModel
import CoreCommon
import CoreUI

private let dayOfWeekLabels = ["日", "月", "火", "水", "木", "金", "土"]
private let sundayColor = Color(red: 0.898, green: 0.224, blue: 0.208)
private let saturdayColor = Color(red: 0.118, green: 0.533, blue: 0.898)
private let greenBg  = Color(red: 0.784, green: 0.902, blue: 0.788)
private let yellowBg = Color(red: 1.0,   green: 0.976, blue: 0.769)
private let redBg    = Color(red: 1.0,   green: 0.804, blue: 0.824)

struct CalendarGrid: View {
    let yearMonth: YearMonth
    let dayMap: [String: CalendarDay]
    let onDayTap: (String) -> Void

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let todayString: String = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }()

    var body: some View {
        VStack(spacing: 4) {
            // 曜日ヘッダー
            HStack(spacing: 0) {
                ForEach(Array(dayOfWeekLabels.enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(.appCaption)
                        .foregroundStyle(headerColor(for: index))
                        .frame(maxWidth: .infinity)
                }
            }

            // 日付グリッド
            let firstDayStr = yearMonth.firstDayString()
            let firstDate = Self.dateFormatter.date(from: firstDayStr)!
            let startOffset = Calendar.current.component(.weekday, from: firstDate) - 1
            let daysInMonth = Calendar.current.range(of: .day, in: .month, for: firstDate)!.count
            let totalCells = startOffset + daysInMonth
            let rows = (totalCells + 6) / 7

            ForEach(0 ..< rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0 ..< 7, id: \.self) { col in
                        let cellIndex = row * 7 + col
                        let dayNum = cellIndex - startOffset + 1
                        if dayNum < 1 || dayNum > daysInMonth {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        } else {
                            let dateStr = String(format: "%04d-%02d-%02d",
                                                yearMonth.year, yearMonth.month, dayNum)
                            DayCell(
                                dayNum: dayNum,
                                dateStr: dateStr,
                                calendarDay: dayMap[dateStr],
                                dayOfWeekIndex: col,
                                isToday: dateStr == Self.todayString,
                                onTap: { onDayTap(dateStr) }
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
    }

    private func headerColor(for index: Int) -> Color {
        switch index {
        case 0: return sundayColor
        case 6: return saturdayColor
        default: return Color.primary
        }
    }
}

private struct DayCell: View {
    let dayNum: Int
    let dateStr: String
    let calendarDay: CalendarDay?
    let dayOfWeekIndex: Int
    let isToday: Bool
    let onTap: () -> Void

    private var bgColor: Color {
        switch calendarDay?.status {
        case .green:  return greenBg
        case .yellow: return yellowBg
        case .red:    return redBg
        default:      return Color.clear
        }
    }

    private var textColor: Color {
        switch dayOfWeekIndex {
        case 0: return sundayColor
        case 6: return saturdayColor
        default: return Color.primary
        }
    }

    var body: some View {
        ZStack {
            bgColor
                .clipShape(Circle())

            if isToday {
                Circle()
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 28, height: 28)
            }

            Text("\(dayNum)")
                .font(.appCaption)
                .foregroundStyle(textColor)
                .fontWeight(isToday ? .bold : .regular)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding(2)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }
}

// MARK: - LegendRow

struct LegendRow: View {
    var body: some View {
        HStack(spacing: 12) {
            LegendItem(color: greenBg,  label: "全完了")
            LegendItem(color: yellowBg, label: "一部完了")
            LegendItem(color: redBg,    label: "未完了")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.appCaption)
        }
    }
}
