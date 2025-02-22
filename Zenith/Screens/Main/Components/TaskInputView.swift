import SwiftUI

struct TaskInputView: View {
    @FocusState private var isFocused: Bool
    @State private var text: String = ""
    @State private var isLoading = false
    @Environment(\.colorScheme) private var colorScheme
    let onSubmit: (String) async -> Void
    let onDismiss: () -> Void
    
    var sheetBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.95)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TextField("Add a task or set a reminder...", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.shared.activeColor)
                    .submitLabel(.send)
                    .autocorrectionDisabled(false)
                    .textInputAutocapitalization(.sentences)
                    .focused($isFocused)
                    .onSubmit {
                        guard !text.isEmpty else { return }
                        submit()
                    }
                
                if isLoading {
                    ProgressView()
                        .padding(.leading, 8)
                } else if !text.isEmpty {
                    Button {
                        submit()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 24))
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Spacer(minLength: 0) // This will push content to the top
        }
        .background(sheetBackgroundColor) // Same background color for the whole sheet
        .onAppear {
            isFocused = true
        }
    }
    
    private func submit() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        
        Task { @MainActor in
            let textToSubmit = text
            isLoading = true
            generator.impactOccurred()
            await onSubmit(textToSubmit)
            text = ""
            isLoading = false
            onDismiss()
        }
    }
} 