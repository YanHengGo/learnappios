import SwiftUI
import CoreModel
import CoreUI

struct TaskDialog: View {
    @Bindable var viewModel: TasksViewModel
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    private var isValid: Bool {
        !viewModel.dialogName.trimmingCharacters(in: .whitespaces).isEmpty
            && !viewModel.dialogSubject.trimmingCharacters(in: .whitespaces).isEmpty
            && (Int(viewModel.dialogMinutes) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("タスク名", text: $viewModel.dialogName)
                        .disabled(viewModel.isSaving)
                    TextField("教科", text: $viewModel.dialogSubject)
                        .disabled(viewModel.isSaving)
                    TextField("標準時間（分）", text: $viewModel.dialogMinutes)
                        .keyboardType(.numberPad)
                        .disabled(viewModel.isSaving)
                    TextField("メモ（任意）", text: $viewModel.dialogDescription)
                        .disabled(viewModel.isSaving)
                }

                Section("曜日") {
                    HStack(spacing: 6) {
                        ForEach(Array(dayLabels.enumerated()), id: \.offset) { index, label in
                            let selected = viewModel.dialogDaysMask.hasDayBit(index)
                            Button(label) {
                                viewModel.onDayToggle(index)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 36, height: 36)
                            .background(selected ? Color.appPrimary : Color(UIColor.tertiarySystemGroupedBackground))
                            .foregroundStyle(selected ? Color.white : Color.primary)
                            .clipShape(Circle())
                            .disabled(viewModel.isSaving)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("期間（任意）") {
                    TextField("開始日 yyyy-MM-dd", text: $viewModel.dialogStartDate)
                        .keyboardType(.numbersAndPunctuation)
                        .disabled(viewModel.isSaving)
                    TextField("終了日 yyyy-MM-dd", text: $viewModel.dialogEndDate)
                        .keyboardType(.numbersAndPunctuation)
                        .disabled(viewModel.isSaving)
                }
            }
            .navigationTitle(viewModel.editingTask != nil ? "タスクを編集" : "タスクを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", action: onDismiss)
                        .disabled(viewModel.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("保存", action: onConfirm)
                            .disabled(!isValid)
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}
