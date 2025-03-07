//
//  ZenithApp.swift
//  Zenith
//
//  Created by Rafael Cardoso on 18/12/24.
//

import SwiftUI
import AVFoundation

// MARK: - Theme
@Observable final class AppTheme {
    static let shared = AppTheme()
    
    var colorScheme: ColorScheme = .light
    
    var backgroundColor: Color {
        colorScheme == .dark ? .black : Color(hex: "F1F2F4")
    }
    
    var activeColor: Color {
        colorScheme == .dark ? .white : .black // Ensure white is used in dark mode
    }
    
    var inactiveColor: Color {
        Color(hex: "7E7E7E")
    }
    
    // Update color scheme from current environment
    func updateColorScheme(_ newScheme: ColorScheme) {
        self.colorScheme = newScheme
        print("AppTheme updated to \(newScheme == .dark ? "dark" : "light") mode")
    }
    
    private init() {
        // Get the initial color scheme from the system
        if UITraitCollection.current.userInterfaceStyle == .dark {
            colorScheme = .dark
            print("AppTheme initialized in dark mode")
        } else {
            print("AppTheme initialized in light mode")
        }
    }
}

// MARK: - Keyboard Height Handler
class KeyboardHeightHandler: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    @Published var animationDuration: Double = 0.25
    
    init() {
        // Register for keyboard notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
           let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            
            // Ensure UI updates happen on the main thread with high priority
            DispatchQueue.main.async {
                // Add 1 point to avoid tiny gap
                self.keyboardHeight = keyboardFrame.height + 1
                self.animationDuration = duration
            }
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        if let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            // Ensure UI updates happen on the main thread with high priority
            DispatchQueue.main.async {
                self.keyboardHeight = 0
                self.animationDuration = duration
            }
        }
    }
}

// MARK: - Haptic Feedback
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Main Navigation
enum Tab: Int, CaseIterable, Hashable {
    case today = 0
    case statistics = 1
    
    var title: String {
        switch self {
        case .today: return "Início"
        case .statistics: return "Estatísticas"
        }
    }
    
    var icon: String {
        switch self {
        case .today: return "house"
        case .statistics: return "chart.bar"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .today: return "house.fill"
        case .statistics: return "chart.bar.fill"
        }
    }
}

// MARK: - Sidebar Navigation
enum SidebarSelection: Equatable {
    case today
    case inbox(Project)
    case blocks
    case project(Project)
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @ObservedObject var focusViewModel: FocusSessionViewModel
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var appState: AppState
    
    // Standard tab bar height per Apple HIG
    private let tabBarHeight: CGFloat = 49
    
    var body: some View {
        ZStack {
            // Background of the tab bar
            Rectangle()
                .fill(colorScheme == .dark ? Color.black : Color(.systemGray6))
                .frame(height: tabBarHeight)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
            
            // Tab items
            HStack(spacing: 0) {
                if focusViewModel.isActive {
                    // Two-tab layout when focus session is active
                    Spacer()
                    tabButton(for: .today)
                    Spacer()
                    tabButton(for: .statistics)
                    Spacer()
                } else {
                    // Three-column layout with space for focus button
                    tabButton(for: .today)
                        .frame(maxWidth: .infinity)
                    
                    // Empty center space for focus button
                    Spacer()
                        .frame(width: 80)
                    
                    tabButton(for: .statistics)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Focus button - positioned at the top of the container
            if !focusViewModel.isActive {
                focusButton
                    .frame(maxWidth: .infinity, alignment: .center)
                    .offset(y: 0) // Centered with the tab bar (changed from -22)
                    .zIndex(1) // Ensure it's above the tab bar
            }
        }
        .onAppear {
            AppTheme.shared.updateColorScheme(colorScheme)
        }
        .onChange(of: colorScheme) { _, newValue in
            AppTheme.shared.updateColorScheme(newValue)
        }
    }
    
    private var focusButton: some View {
        Button(action: {
            HapticManager.shared.impact(style: .light)
            focusViewModel.isExpanded = true
        }) {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? Color(hex: "F1F2F4") : .black)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .black : .white)
            }
        }
        .accessibilityLabel("Start focus session")
    }
    
    private func tabButton(for tab: Tab) -> some View {
        Button {
            if selectedTab != tab {
                HapticManager.shared.selectionChanged()
                
                // If switching to Statistics tab, close sidebar if open
                if tab == .statistics && appState.showingSidebar {
                    appState.showingSidebar = false
                }
                
                // Simple direct tab change
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 22, weight: .regular))
                
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(selectedTab == tab ? 
                            AppTheme.shared.activeColor : // Use AppTheme's colors
                            AppTheme.shared.inactiveColor)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(tab.title)
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var selectedTab: Tab = .today
    @Published var sidebarSelection: SidebarSelection = .today
    @Published var selectedProject: Project?
    @Published var showingSidebar = false
    
    // Method to navigate directly to Statistics tab
    func navigateToStatistics() {
        print("AppState: Direct navigation to Statistics tab requested")
        
        // Close sidebar if open
        if showingSidebar {
            showingSidebar = false
        }
        
        // Direct tab change
        selectedTab = .statistics
    }
}

// MARK: - Main App
@main
struct ZenithApp: App {
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var focusViewModel = FocusSessionViewModel()
    @StateObject private var projectViewModel = ProjectViewModel()
    @StateObject private var keyboardHandler = KeyboardHeightHandler() // Track keyboard
    @StateObject private var appState = AppState()
    @Environment(\.colorScheme) var colorScheme
    @State private var chatInputRef: GlobalChatInput? = nil
    
    init() {
        // Configure navigation bar appearance with opaque background that matches app theme
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Set background color to match app background using UITraitCollection instead of SwiftUI Environment
        let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        appearance.backgroundColor = isDarkMode ? .black : UIColor(Color(hex: "F1F2F4"))
        
        // Apply to all navigation bars in the app
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            GeometryReader { geometry in
                ZStack {
                    // Apply background color to the entire screen including safe areas
                    Color(colorScheme == .dark ? .black : Color(hex: "F1F2F4"))
                        .ignoresSafeArea()
                    
                    // Background tap recognizer to dismiss keyboard - improved to capture taps reliably
                    if keyboardHandler.keyboardHeight > 0 {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                hideKeyboard()
                            }
                            .ignoresSafeArea()
                            .zIndex(5) // Place it above content but below the keyboard/chat input
                    }
                    
                    // Main content area with tab bar
                    ZStack {
                        // Main content - each tab gets its own NavigationStack
                        TabView(selection: $appState.selectedTab) {
                            // Today tab with all its possible views
                            NavigationStack {
                                ZStack {
                                    // Background color should extend to edges
                                    Color(colorScheme == .dark ? .black : Color(hex: "F1F2F4"))
                                        .ignoresSafeArea()
                                        
                                    switch appState.sidebarSelection {
                                    case .today:
                                        MainView(
                                            showingSidebar: $appState.showingSidebar,
                                            selectedProject: $appState.selectedProject
                                        )
                                            .environmentObject(taskViewModel)
                                            .environmentObject(focusViewModel)
                                            .environmentObject(projectViewModel)
                                            .environmentObject(appState)
                                    case .inbox(_):
                                        MainView(
                                            showingSidebar: $appState.showingSidebar,
                                            selectedProject: $appState.selectedProject
                                        )
                                            .environmentObject(taskViewModel)
                                            .environmentObject(focusViewModel)
                                            .environmentObject(projectViewModel)
                                            .environmentObject(appState)
                                    case .blocks:
                                        BlocksView(showingSidebar: $appState.showingSidebar)
                                            .environmentObject(projectViewModel)
                                            .environmentObject(focusViewModel)
                                            .environmentObject(appState)
                                    case .project(_):
                                        MainView(
                                            showingSidebar: $appState.showingSidebar,
                                            selectedProject: $appState.selectedProject
                                        )
                                            .environmentObject(taskViewModel)
                                            .environmentObject(focusViewModel)
                                            .environmentObject(projectViewModel)
                                            .environmentObject(appState)
                                    }
                                }
                            }
                            .tag(Tab.today)
                            .tabItem { EmptyView() } // Use our custom tab bar instead
                            
                            // Statistics tab - separate NavigationStack
                            NavigationStack {
                                StatisticsView(showingSidebar: $appState.showingSidebar)
                                    .environmentObject(projectViewModel)
                                    .environmentObject(focusViewModel)
                                    .environmentObject(appState)
                            }
                            .tag(Tab.statistics)
                            .tabItem { EmptyView() } // Use our custom tab bar instead
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never)) // Hide default tab UI
                        .animation(.easeInOut, value: appState.selectedTab)
                        // Add safe area inset for the tab bar - this properly handles the home indicator
                        .safeAreaInset(edge: .bottom) {
                            CustomTabBar(selectedTab: $appState.selectedTab, focusViewModel: focusViewModel)
                                .environmentObject(appState)
                        }
                    } // End of main ZStack for tab content and tab bar
                    
                    // Chat input - positioned directly above tab bar
                    if !focusViewModel.isActive && !focusViewModel.isExpanded {
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            GlobalChatInput(taskViewModel: taskViewModel)
                                .padding(.bottom, keyboardHandler.keyboardHeight > 0 ? 0 : 49) // Exact tab height with no gap
                                .offset(y: keyboardHandler.keyboardHeight > 0 ? geometry.size.height - keyboardHandler.keyboardHeight - 124 : 0)
                                .animation(
                                    .interpolatingSpring(
                                        mass: 0.6,
                                        stiffness: 140,
                                        damping: 12.0,
                                        initialVelocity: 0
                                    ),
                                    value: keyboardHandler.keyboardHeight
                                )
                        }
                        .zIndex(appState.showingSidebar ? 1 : 10) // Lower z-index when sidebar is open
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // Minimized Focus Session 
                    if focusViewModel.isActive && focusViewModel.isMinimized {
                        VStack {
                            Spacer()
                            MinimizedFocusSession(
                                taskTitle: focusViewModel.selectedTask?.title,
                                progress: focusViewModel.progress,
                                remainingTime: focusViewModel.remainingTime,
                                blockDistractions: focusViewModel.blockDistractions,
                                onExpand: focusViewModel.expandSession
                            )
                            .background(
                                Rectangle()
                                    .fill(colorScheme == .dark ? Color.black : Color(.systemGray6))
                            )
                            .padding(.bottom, 49) // Standard tab height
                        }
                    }
                    
                    // Undo toast
                    if taskViewModel.showingUndoToast {
                        VStack {
                            Spacer()
                            UndoToastView(
                                message: "\"\(taskViewModel.lastCompletedTaskTitle)\" concluída",
                                action: {
                                    do {
                                        try await taskViewModel.undoLastCompletion()
                                        withAnimation {
                                            taskViewModel.showingUndoToast = false
                                        }
                                    } catch {
                                        print("Error undoing task completion: \(error)")
                                    }
                                },
                                isPresented: $taskViewModel.showingUndoToast
                            )
                            .padding(.bottom, 60) // Just above the tab bar
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // Full-screen focus session overlay
                    if focusViewModel.isExpanded {
                        FocusSessionView()
                            .environmentObject(taskViewModel)
                            .environmentObject(focusViewModel)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                    }
                    
                    // Sidebar overlay
                    if appState.showingSidebar {
                        // Background dim overlay (without move transition)
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    appState.showingSidebar = false
                                    HapticManager.shared.impact(style: .light)
                                }
                            }
                            .transition(.opacity)
                            .zIndex(20) // Higher z-index for sidebar background
                        
                        // Sidebar content (with move transition)
                        ZStack(alignment: .leading) {
                            SidebarMenu(
                                taskViewModel: taskViewModel,
                                isShowingSidebar: $appState.showingSidebar,
                                selectedProject: $appState.selectedProject,
                                sidebarSelection: $appState.sidebarSelection
                            )
                            .environmentObject(projectViewModel)
                            .environmentObject(appState)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.move(edge: .leading))
                        .zIndex(25) // Highest z-index for sidebar content
                    }
                } // End of outer ZStack for all UI elements
                .onChange(of: colorScheme) { _, newValue in
                    // Update AppTheme at the app level as well
                    AppTheme.shared.updateColorScheme(newValue)
                }
                .onChange(of: appState.showingSidebar) { _, newValue in
                    // Add haptic feedback when sidebar state changes
                    if newValue {
                        // Sidebar is being opened
                        HapticManager.shared.impact(style: .medium)
                    }
                    
                    // Explicitly animate sidebar transitions
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        // This empty block ensures the animation is applied
                    }
                }
                .onChange(of: appState.selectedTab) { oldValue, newValue in
                    print("Tab changed from \(oldValue) to \(newValue)")
                    
                    // Simple operations to ensure clean state when needed
                    if newValue == .statistics && appState.showingSidebar {
                        appState.showingSidebar = false
                    }
                }
                .onChange(of: appState.sidebarSelection) { oldValue, newValue in
                    print("Sidebar selection changed from \(oldValue) to \(newValue)")
                    
                    // Update selectedProject based on sidebarSelection
                    switch newValue {
                    case .today:
                        appState.selectedProject = nil
                    case .inbox(let project):
                        appState.selectedProject = project
                    case .blocks:
                        appState.selectedProject = nil
                    case .project(let project):
                        appState.selectedProject = project
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.9), value: focusViewModel.isExpanded)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: appState.showingSidebar)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: taskViewModel.showingUndoToast)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: focusViewModel.isActive)
            } // End of GeometryReader
            .task {
                // Preload projects when app starts
                await preloadData()
            }
        } // End of WindowGroup
    } // End of var body
    
    // Method to dismiss keyboard
    private func hideKeyboard() {
        print("Dismissing keyboard")
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Preload data when app starts to ensure it's available when needed
    private func preloadData() async {
        // Load projects in the background
        Task {
            do {
                try await projectViewModel.loadProjects()
                print("📱 [App] Preloaded projects successfully")
            } catch {
                print("📱 [App] Error preloading projects: \(error)")
            }
        }
    }
    
    // Project selection preference key
    struct ProjectSelectionKey: PreferenceKey {
        static var defaultValue: Project? = nil
        static func reduce(value: inout Project?, nextValue: () -> Project?) {
            value = nextValue()
        }
    }
} // End of ZenithApp

// MARK: - Preview Provider
struct ZenithApp_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            CustomTabBar(selectedTab: .constant(.today), focusViewModel: FocusSessionViewModel())
                .environmentObject(AppState())
        }
    }
}

