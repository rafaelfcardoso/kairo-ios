import SwiftUI
// If needed, import the shared ChatMessage model location here

struct NewChatScreen: View {
    @Binding var showingSidebar: Bool
    @Binding var showingNewChatOverlay: Bool
    @ObservedObject var chatViewModel: GlobalChatViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            UnifiedToolbar(
    title: "Novo Chat",
    subtitle: nil,
    onSidebarTap: {
        print("[NewChatScreen] Hamburger tapped, setting showingSidebar = true and dismissing overlay")
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showingSidebar = true
            showingNewChatOverlay = false
            HapticManager.shared.impact(style: .medium)
        }
    },
    trailing: nil,
    textColor: colorScheme == .dark ? .white : .black,
    backgroundColor: colorScheme == .dark ? .black : .white,
    showDivider: true
)
            
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(chatViewModel.messages) { message in
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
                .onChange(of: chatViewModel.messages.count) { _, _ in
    if let last = chatViewModel.messages.last?.id {
        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
    }
}
            }
            Divider()
            GlobalChatInput(viewModel: chatViewModel)
                .padding(.bottom, 4)
                .padding(.bottom, (UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.safeAreaInsets.bottom ?? 0))
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}

// Preview
#Preview {
    NewChatScreen(showingSidebar: .constant(false), showingNewChatOverlay: .constant(false), chatViewModel: GlobalChatViewModel())
}
