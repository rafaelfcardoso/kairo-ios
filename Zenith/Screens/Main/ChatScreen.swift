import SwiftUI

struct ChatScreen: View {
    @ObservedObject var sessionsViewModel: ChatSessionsViewModel
    @Binding var showingSidebar: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var inputText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            UnifiedToolbar(
                title: sessionsViewModel.currentSession?.title ?? "Novo Chat",
                subtitle: {
                    if let date = sessionsViewModel.currentSession?.createdAt {
                        return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
                    } else {
                        return nil
                    }
                }(),
                onSidebarTap: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingSidebar = true
                        HapticManager.shared.impact(style: .medium)
                    }
                },
                trailing: nil,
                textColor: colorScheme == .dark ? .white : .black,
                backgroundColor: colorScheme == .dark ? .black : .white
            )
            .background((colorScheme == .dark ? Color.black : Color.white).ignoresSafeArea(edges: .top))
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
                .onChange(of: sessionsViewModel.currentSession?.messages.count) { _, _ in
                    if let last = sessionsViewModel.currentSession?.messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }
            
            Divider()
            
            // Input bar
            ChatInputField(text: $inputText, onSend: sendMessage)
                .padding(.bottom, 4)

        }

    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty,
              sessionsViewModel.currentSession != nil else { return }
        let message = ChatMessage(text: inputText, isUser: true)
        sessionsViewModel.appendMessage(message)
        inputText = ""
        // TODO: Trigger AI response here if needed
    }
}
