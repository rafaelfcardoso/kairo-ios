import SwiftUI

struct ChatInputField: View {
    @Binding var text: String
    var onSend: () -> Void
    var placeholder: String = "Ask anything..."
    var disabled: Bool = false
    
    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(disabled)
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(text.isEmpty ? .gray : .blue)
            }
            .disabled(text.isEmpty || disabled)
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.95))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}
