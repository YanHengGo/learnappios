import SwiftUI
import CoreUI

public struct DailyView: View {
    @State private var viewModel: DailyViewModel

    public init(viewModel: DailyViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            Color.clear

            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.taskRows.isEmpty {
                Text("この日のタスクはありません")
                    .font(.appBody)
                    .foregroundStyle(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(32)
            } else {
                VStack(spacing: 0) {
                    taskList
                    totalRow
                    saveButton
                }
            }
        }
        .safeAreaInset(edge: .top) {
            DateNavigationBar(
                date: viewModel.date,
                weekday: viewModel.weekday,
                onPrevious: { viewModel.onPreviousDate() },
                onNext: { viewModel.onNextDate() }
            )
            .background(Color(UIColor.systemBackground))
        }
        .overlay(alignment: .bottom) {
            notificationToast
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
        .animation(.easeInOut(duration: 0.3), value: viewModel.saveSuccess)
        .task {
            viewModel.loadDailyView()
        }
        .navigationTitle("日々の記録")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.taskRows) { row in
                    DailyTaskRowView(
                        row: row,
                        onToggle: { viewModel.onToggleDone(taskId: row.taskId) },
                        onMinutesChange: { viewModel.onMinutesChange(taskId: row.taskId, value: $0) }
                    )
                }
            }
            .padding(16)
        }
    }

    private var totalRow: some View {
        let total = viewModel.taskRows
            .filter { $0.isDone }
            .reduce(0) { $0 + (Int($1.minutes) ?? $1.defaultMinutes) }
        return HStack {
            Spacer()
            Text("合計: \(total)分")
                .font(.appTitle)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private var saveButton: some View {
        Button {
            viewModel.onSave()
        } label: {
            if viewModel.isSaving {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text("保存する")
                    .font(.appTitle)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isSaving)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var notificationToast: some View {
        if let message = viewModel.errorMessage {
            DailyToastView(message: message, isError: true) {
                viewModel.onErrorDismiss()
            }
        } else if viewModel.saveSuccess {
            DailyToastView(message: "保存しました", isError: false) {
                viewModel.onSaveSuccessDismiss()
            }
        }
    }
}

private struct DailyToastView: View {
    let message: String
    let isError: Bool
    let onDismiss: () -> Void

    var body: some View {
        Text(message)
            .font(.appCaption)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isError ? Color.red.opacity(0.85) : Color.black.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.bottom, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onTapGesture { onDismiss() }
            .task {
                try? await Swift.Task.sleep(for: .seconds(3))
                onDismiss()
            }
    }
}
