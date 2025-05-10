import SwiftUI

struct NewChatScreen: View {
    @Binding var showingSidebar: Bool
    @Binding var showingNewChatOverlay: Bool
    @ObservedObject var chatSessionsViewModel: ChatSessionsViewModel
    @ObservedObject var chatViewModel: GlobalChatViewModel
    @Environment(\.colorScheme) var colorScheme

    @StateObject private var keyboardHandler = KeyboardHeightHandler()
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
                        ForEach(chatSessionsViewModel.currentSession?.messages ?? []) { message in
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
                .onChange(of: chatSessionsViewModel.currentSession?.messages.count) { _, _ in
                    if let last = chatSessionsViewModel.currentSession?.messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }
            Divider()
            GlobalChatInput(viewModel: chatViewModel, onSend: { text in
                    chatViewModel.sendMessageToCurrentSession(text)
                })
                .padding(.bottom, max(keyboardHandler.keyboardHeight, UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.safeAreaInsets.bottom ?? 0))
                .animation(.easeOut(duration: 0.25), value: keyboardHandler.keyboardHeight)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .dismissKeyboardOnTap()
        .onAppear {
            print("[NewChatScreen] chatSessionsViewModel: \(Unmanaged.passUnretained(chatSessionsViewModel).toOpaque())")
            print("[NewChatScreen] onAppear called. Current session: \(String(describing: chatSessionsViewModel.currentSession))")
            if chatSessionsViewModel.currentSession == nil {
                chatSessionsViewModel.startNewSession()
                print("[NewChatScreen] Started new session: \(String(describing: chatSessionsViewModel.currentSession))")
            }
        }
    }
}
