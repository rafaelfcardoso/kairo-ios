import SwiftUI
import Combine

struct AppMainView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var focusViewModel: FocusSessionViewModel
    @ObservedObject var projectViewModel: ProjectViewModel
    @StateObject var keyboardHandler = KeyboardHeightHandler()
    @ObservedObject var chatViewModel: GlobalChatViewModel
    @StateObject var chatSessionsViewModel = ChatSessionsViewModel()
    @Binding var showingSidebar: Bool
    @Binding var selectedProject: Project?
    @Binding var selectedTab: Tab
    @Binding var isAuthenticated: Bool
    @State private var activeChatSession: ChatSession? = nil
    @State private var showingNewChatOverlay: Bool = false
    @StateObject private var newChatViewModel = GlobalChatViewModel()
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // --- SIDEBAR + MAIN CONTENT LAYOUT (robust, fixed sidebar) ---
                ZStack(alignment: .leading) {
                    // Sidebar: absolutely positioned, always at the left edge when open
                    if showingSidebar {
                        SidebarMenu(
                            taskViewModel: taskViewModel,
                            isShowingSidebar: $showingSidebar,
                            selectedProject: $selectedProject,
                            chatSessionsViewModel: chatSessionsViewModel,
                            onSelectChatSession: { session in
                                activeChatSession = session
                            },
                            onNewChat: {
                                showingNewChatOverlay = true
                                newChatViewModel.inputText = ""
                            }
                        )
                        .environmentObject(projectViewModel)
                        .frame(width: min(geometry.size.width * 0.8, 320))
                        .ignoresSafeArea(.container, edges: .vertical)
                        .transition(.move(edge: .leading))
                        .zIndex(4)
                    }

                    // Main content (offset right when sidebar is open)
                    ZStack {
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .disabled(showingSidebar)
                    }
                    .offset(x: showingSidebar ? min(geometry.size.width * 0.8, 320) : 0)
                    .animation(.easeInOut, value: showingSidebar)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(1)

                    // Overlay: absolutely positioned, covers only the main content area
                    if showingSidebar {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture {
                                HapticManager.shared.impact(style: .medium)
                                withAnimation { showingSidebar = false }
                            }
                            .frame(width: geometry.size.width - min(geometry.size.width * 0.8, 320))
                            .offset(x: min(geometry.size.width * 0.8, 320))
                            .zIndex(3)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut, value: showingSidebar)

                // New Chat Overlay (ChatGPT-style)
                if showingNewChatOverlay {
                    NewChatScreen(showingSidebar: $showingSidebar, showingNewChatOverlay: $showingNewChatOverlay, chatSessionsViewModel: chatSessionsViewModel, chatViewModel: newChatViewModel)
                        .background(
                            Color(.systemBackground)
                                .opacity(0.98)
                                .ignoresSafeArea()
                        )
                        .transition(.move(edge: .trailing))
                        .zIndex(3)
                        .allowsHitTesting(!showingSidebar)
                }

                // Global Chat Input (always at the bottom, slides in/out with main view)
                if activeChatSession == nil && !focusViewModel.isExpanded {
                    GlobalChatInput(viewModel: chatViewModel)
                        .padding(
                            .bottom,
                            keyboardHandler.keyboardHeight > 0 ? keyboardHandler.keyboardHeight : geometry.safeAreaInsets.bottom
                        )
                        .offset(x: showingSidebar ? min(geometry.size.width * 0.8, 320) : 0)
                        .opacity(showingSidebar ? 0 : 1)
                        .animation(.easeInOut, value: showingSidebar)
                        .animation(Animation.easeOut(duration: 0.25), value: keyboardHandler.keyboardHeight)
                        .allowsHitTesting(!showingSidebar)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .bottom)
            // --- AUTH MODAL ---

            .fullScreenCover(isPresented: $authViewModel.requiresLogin, content: {
                LoginView()
                    .environmentObject(authViewModel)
            })
        }
        .onAppear {
            print("[AppMainView] chatSessionsViewModel: \(Unmanaged.passUnretained(chatSessionsViewModel).toOpaque())")
            print("[AppMainView] Rendered with GeometryReader-rooted overlay")
            NotificationCenter.default.addObserver(forName: .userDidLogout, object: nil, queue: .main) { _ in
                isAuthenticated = false
            }
        }
    }
}
