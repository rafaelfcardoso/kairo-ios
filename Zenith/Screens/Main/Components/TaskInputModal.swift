import SwiftUI

struct TaskInputModal: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    @State private var text: String = ""
    @State private var isLoading = false
    let onSubmit: (String) async -> Void
    
    var inputBackgroundColor: Color {
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
                } else if !text.isEmpty {
                    Button {
                        submit()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 24))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(inputBackgroundColor)
            .cornerRadius(12)
            //.padding(.horizontal, 16)
            //.padding(.vertical, 8)
        }
        .onAppear {
            isFocused = true
        }
        .presentationBackground(inputBackgroundColor)
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
            dismiss()
        }
    }
} 