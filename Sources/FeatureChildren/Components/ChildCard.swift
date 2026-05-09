import SwiftUI
import CoreModel
import CoreUI

struct ChildCard: View {
    let child: Child
    let onClick: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(child.name)
                        .font(.appTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.primary)
                    if let grade = child.grade {
                        Text(grade)
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

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(Color.red)
                        .padding(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(child.isActive ? Color.appPrimary.opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
