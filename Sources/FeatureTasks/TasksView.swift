import SwiftUI
import CoreModel
import CoreUI

public struct TasksView: View {
    @State private var viewModel: TasksViewModel

    public init(viewModel: TasksViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            Color.clear

            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.tasks.isEmpty {
                Text("タスクが登録されていません\n右下のボタンから追加してください")
                    .font(.appBody)
                    .foregroundStyle(Color.appSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(32)
            } else {
                List {
                    ForEach(viewModel.tasks) { task in
                        TaskCard(
                            task: task,
                            onEdit: { viewModel.onShowEditDialog(task) },
                            onArchive: { viewModel.onArchiveTask(task) }
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    .onMove { indices, newOffset in
                        guard let from = indices.first else { return }
                        let to = newOffset > from ? newOffset - 1 : newOffset
                        viewModel.onMove(from: from, to: to)
                    }
                }
                .listStyle(.plain)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                viewModel.onShowAddDialog()
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.appPrimary)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(24)
        }
        .overlay(alignment: .bottom) {
            taskErrorToast
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.errorMessage)
        .navigationTitle("タスク管理")
        .task {
            viewModel.loadTasks()
        }
        .sheet(isPresented: $viewModel.showDialog, onDismiss: viewModel.onDismissDialog) {
            TaskDialog(
                viewModel: viewModel,
                onConfirm: { viewModel.onSaveTask() },
                onDismiss: { viewModel.showDialog = false }
            )
        }
    }

    @ViewBuilder
    private var taskErrorToast: some View {
        if let message = viewModel.errorMessage {
            TasksToastView(message: message, onDismiss: viewModel.onErrorDismiss)
        }
    }
}

private struct TasksToastView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        Text(message)
            .font(.appCaption)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.bottom, 80)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onTapGesture { onDismiss() }
            .task {
                try? await Swift.Task.sleep(for: .seconds(3))
                onDismiss()
            }
    }
}
