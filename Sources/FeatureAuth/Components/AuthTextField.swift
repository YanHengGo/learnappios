import SwiftUI

struct AuthTextField: View {
    let label: String
    @Binding var text: String
    var isPassword: Bool = false
    var isEnabled: Bool = true
    var onSubmit: (() -> Void)? = nil

    @State private var isPasswordVisible = false

    var body: some View {
        Group {
            if isPassword && !isPasswordVisible {
                SecureField(label, text: $text)
            } else {
                TextField(label, text: $text)
                    .keyboardType(isPassword ? .default : .emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .overlay(alignment: .trailing) {
            if isPassword {
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .padding(.trailing, 8)
            }
        }
        .textFieldStyle(.roundedBorder)
        .disabled(!isEnabled)
        .onSubmit { onSubmit?() }
    }
}
