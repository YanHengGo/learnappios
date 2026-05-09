import SwiftUI
import CoreModel
import CoreUI

struct TaskCard: View {
    let task: Task
    let onEdit: () -> Void
    let onArchive: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.appTitle)
                    .fontWeight(.bold)
                Text("\(task.subject)  ・  \(task.defaultMinutes)分  ・  \(daysLabel(task.daysMask))")
                    .font(.appCaption)
                    .foregroundStyle(Color.appSecondaryText)
                if task.startDate != nil || task.endDate != nil {
                    Text([task.startDate, task.endDate].compactMap { $0 }.joined(separator: " 〜 "))
                        .font(.appCaption)
                        .foregroundStyle(Color.appSecondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundStyle(Color.appPrimary)
                    .padding(8)
            }

            Button(action: onArchive) {
                Image(systemName: "archivebox")
                    .foregroundStyle(Color.appSecondaryText)
                    .padding(8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private func daysLabel(_ mask: Int) -> String {
    dayLabels.indices.filter { mask.hasDayBit($0) }.map { dayLabels[$0] }.joined()
}
