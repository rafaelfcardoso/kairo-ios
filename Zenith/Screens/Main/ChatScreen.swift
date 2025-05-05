import SwiftUI

struct ChatScreen: View {
    @ObservedObject var sessionsViewModel: ChatSessionsViewModel
    @State private var inputText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with session title and date
            HStack {
                VStack(alignment: .leading) {
                    Text(sessionsViewModel.currentSession?.title ?? "New Chat")
                        .font(.headline)
                    if let date = sessionsViewModel.currentSession?.createdAt {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            
            Divider()
            
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(sessionsViewModel.currentSession?.messages ?? []) { message in
                            HStack {
                                if message.isUser { Spacer() }
                                Text(message.text)
                                    .padding(10)
                                    .background(message.isUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                                    .foregroundColor(message.isUser ? .blue : .primary)
                                    .cornerRadius(10)
                                if !message.isUser { Spacer() }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                }
                .onChange(of: sessionsViewModel.currentSession?.messages.count) { _ in
                    if let last = sessionsViewModel.currentSession?.messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }
            
            Divider()
            
            // Input bar
            HStack {
                TextField("Ask anything...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(inputText.isEmpty ? .gray : .blue)
                }
                .disabled(inputText.isEmpty)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty,
              let current = sessionsViewModel.currentSession else { return }
        let message = ChatMessage(text: inputText, isUser: true)
        sessionsViewModel.appendMessage(message)
        inputText = ""
        // TODO: Trigger AI response here if needed
    }
}
