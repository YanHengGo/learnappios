import SwiftUI
import CoreCommon
import CoreUI

struct MonthNavigationBar: View {
    let yearMonth: YearMonth
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

            Text("\(yearMonth.year)年\(yearMonth.month)月")
                .font(.appTitle)
                .fontWeight(.bold)

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
