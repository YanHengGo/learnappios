import SwiftUI
import CoreModel
import CoreUI

struct SummaryStats: View {
    let summary: Summary

    var body: some View {
        VStack(spacing: 16) {
            totalCard
            if !summary.bySubject.isEmpty { subjectCard }
            if !summary.byTask.isEmpty { taskCard }
        }
        .padding(.horizontal, 16)
    }

    private var totalCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("期間合計")
                .font(.appCaption)
                .foregroundStyle(Color.appSecondaryText)
            Text(formatMinutes(summary.totalMinutes))
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var subjectCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("教科別")
                .font(.appTitle)
                .fontWeight(.bold)
            ForEach(summary.bySubject.sorted(by: { $0.minutes > $1.minutes }), id: \.subject) { item in
                HStack {
                    Text(item.subject)
                        .font(.appBody)
                    Spacer()
                    Text(formatMinutes(item.minutes))
                        .font(.appBody)
                        .fontWeight(.medium)
                }
                Divider()
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var taskCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("タスク別")
                .font(.appTitle)
                .fontWeight(.bold)
            ForEach(summary.byTask.sorted(by: { $0.minutes > $1.minutes }), id: \.taskId) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.appBody)
                        Text(item.subject)
                            .font(.appCaption)
                            .foregroundStyle(Color.appSecondaryText)
                    }
                    Spacer()
                    Text(formatMinutes(item.minutes))
                        .font(.appBody)
                        .fontWeight(.medium)
                }
                Divider()
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private func formatMinutes(_ minutes: Int) -> String {
    let h = minutes / 60
    let m = minutes % 60
    return h > 0 ? "\(h)時間\(m)分" : "\(m)分"
}
