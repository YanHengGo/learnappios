import SwiftUI
import CoreUI

struct DailyTaskRowView: View {
    let row: DailyTaskRow
    let onToggle: () -> Void
    let onMinutesChange: (String) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Toggle(isOn: Binding(
                get: { row.isDone },
                set: { _ in onToggle() }
            )) {
                EmptyView()
            }
            .labelsHidden()

            VStack(alignment: .leading, spacing: 2) {
                Text(row.name)
                    .font(.appBody)
                    .fontWeight(.medium)
                    .strikethrough(row.isDone)
                    .foregroundStyle(row.isDone ? Color.appSecondaryText : Color.primary)
                Text("\(row.subject)  ・  標準\(row.defaultMinutes)分")
                    .font(.appCaption)
                    .foregroundStyle(Color.appSecondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            TextField("0", text: Binding(
                get: { row.minutes },
                set: { onMinutesChange($0) }
            ))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 48)
            .disabled(!row.isDone)

            Text("分")
                .font(.appCaption)
                .foregroundStyle(Color.appSecondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(row.isDone ? Color.appPrimary.opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
