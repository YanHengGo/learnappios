import SwiftUI
import CoreUI

struct DateNavigationBar: View {
    let date: String
    let weekday: String
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(Color.appPrimary)
                    .padding(8)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(date)
                    .font(.appTitle)
                    .fontWeight(.bold)
                if !weekday.isEmpty {
                    Text(weekday)
                        .font(.appCaption)
                        .foregroundStyle(Color.appSecondaryText)
                }
            }

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(Color.appPrimary)
                    .padding(8)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}
