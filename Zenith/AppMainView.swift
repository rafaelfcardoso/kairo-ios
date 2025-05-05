import SwiftUI
import Combine

struct AppMainView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var focusViewModel: FocusSessionViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    @ObservedObject var keyboardHandler: KeyboardHeightHandler
    @ObservedObject var chatViewModel: GlobalChatViewModel
    @StateObject var chatSessionsViewModel = ChatSessionsViewModel()
    @Binding var showingSidebar: Bool
    @Binding var selectedProject: Project?
    @Binding var selectedTab: Tab
    @Binding var isAuthenticated: Bool
    @State private var activeChatSession: ChatSession? = nil
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Tap to dismiss keyboard
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { hideKeyboard() }
                    .ignoresSafeArea()

                ZStack {
                    // Main content area
                    Group {
                        switch selectedTab {
                        case .today:
                            MainView(
                                showingSidebar: $showingSidebar,
                                selectedProject: $selectedProject
                            )
                            .environmentObject(taskViewModel)
                            .environmentObject(focusViewModel)
                            .environmentObject(projectViewModel)
                            .environmentObject(keyboardHandler)
                            .onAppear { taskViewModel.refreshAfterLogin() }
                        case .blocks:
                            NavigationStack {
                                // ... (existing blocks view code) ...
                            }
                        }
                    }
                    .zIndex(0)

                    // Sidebar
                    if showingSidebar {
                        SidebarMenu(
                            taskViewModel: taskViewModel,
                            isShowingSidebar: $showingSidebar,
                            selectedProject: $selectedProject,
                            chatSessionsViewModel: chatSessionsViewModel,
                            onSelectChatSession: { session in
                                activeChatSession = session
                                selectedTab = .today // Or a dedicated .chat tab if you prefer
                            }
                        )
                        .environmentObject(projectViewModel)
                        .zIndex(2)
                    }

                    // Chat screen as first-class screen (not overlay)
                    if let session = activeChatSession {
                        NavigationStack {
                            ChatScreen(sessionsViewModel: chatSessionsViewModel)
                        }
                        .zIndex(1)
                    }
                }
                .onAppear {
                    print("[GeometryReader] size.height: \(geometry.size.height), safeAreaInsets.bottom: \(geometry.safeAreaInsets.bottom)")
                }

                // Global Chat Input (always at the bottom)
                if activeChatSession == nil && !focusViewModel.isExpanded && !showingSidebar {
                    GlobalChatInput(viewModel: chatViewModel)
                        .background(Color.red.opacity(0.3))
                        .padding(
                            .bottom,
                            keyboardHandler.keyboardHeight > 0 ? keyboardHandler.keyboardHeight : geometry.safeAreaInsets.bottom
                        )
                        .animation(Animation.easeOut(duration: 0.25), value: keyboardHandler.keyboardHeight)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .bottom)
        }
        .onAppear {
            print("[AppMainView] Rendered with GeometryReader-rooted overlay")
            NotificationCenter.default.addObserver(forName: .userDidLogout, object: nil, queue: .main) { _ in
                isAuthenticated = false
            }
        }
    }

    private func hideKeyboard() {
        // Removed UIApplication.endEditing call
    }
}
