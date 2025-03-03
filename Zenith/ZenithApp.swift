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
            
            // Add 1 point to avoid tiny gap
            self.keyboardHeight = keyboardFrame.height + 1
            self.animationDuration = duration
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        if let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            self.keyboardHeight = 0
            self.animationDuration = duration
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
    case blocks = 1
    
    var title: String {
        switch self {
        case .today: return "Início"
        case .blocks: return "Blocks"
        }
    }
    
    var icon: String {
        switch self {
        case .today: return "house"
        case .blocks: return "rectangle.stack.badge.plus"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .today: return "house.fill"
        case .blocks: return "rectangle.stack.badge.plus.fill"
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @ObservedObject var focusViewModel: FocusSessionViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        // If focus session is active, use a simpler 2-item layout
        if focusViewModel.isActive {
            // Two-tab layout when focus session is active
            HStack(spacing: 0) {
                // Evenly spaced buttons
                Spacer()
                tabButton(for: .today)
                Spacer()
                tabButton(for: .blocks)
                Spacer()
            }
            .frame(height: 51)
            .background(
                Rectangle()
                    .fill(colorScheme == .dark ? Color.black : Color(.systemGray6))
            )
            .onAppear {
                AppTheme.shared.updateColorScheme(colorScheme)
            }
            .onChange(of: colorScheme) { _, newValue in
                AppTheme.shared.updateColorScheme(newValue)
            }
        } else {
            // Standard 3-item layout with focus button in middle
            HStack(spacing: 0) {
                // Left tab
                tabButton(for: .today)
                
                // Center create button
                focusButton
                
                // Right tab
                tabButton(for: .blocks)
            }
            .frame(height: 51)
            .background(
                Rectangle()
                    .fill(colorScheme == .dark ? Color.black : Color(.systemGray6))
            )
            .edgesIgnoringSafeArea(.bottom)
            .onAppear {
                AppTheme.shared.updateColorScheme(colorScheme)
            }
            .onChange(of: colorScheme) { _, newValue in
                AppTheme.shared.updateColorScheme(newValue)
            }
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
                
                Image(systemName: "play.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .black : .white)
            }
        }
        .offset(y: -2) // Smaller offset since the button is smaller
        .accessibilityLabel("Start focus session")
    }
    
    private func tabButton(for tab: Tab) -> some View {
        Button {
            if selectedTab != tab {
                HapticManager.shared.selectionChanged()
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = tab
                }
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20))
                
                Text(tab.title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(selectedTab == tab ? 
                             AppTheme.shared.activeColor : // Use AppTheme's colors
                             AppTheme.shared.inactiveColor)
            .frame(maxWidth: .infinity)
        }
        .accessibilityLabel(tab.title)
    }
}

// MARK: - Main App
@main
struct ZenithApp: App {
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var focusViewModel = FocusSessionViewModel()
    @StateObject private var projectViewModel = ProjectViewModel()
    @StateObject private var keyboardHandler = KeyboardHeightHandler() // Track keyboard
    @State private var selectedTab: Tab = .today
    @Environment(\.colorScheme) var colorScheme
    @State private var showingSidebar = false
    @State private var selectedProject: Project?
    @State private var chatInputRef: GlobalChatInput? = nil
    
    var body: some Scene {
        WindowGroup {
            GeometryReader { geometry in
                ZStack {
                    // Background tap recognizer to dismiss keyboard
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            hideKeyboard()
                        }
                        .ignoresSafeArea()
                    
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
                        case .blocks:
                            NavigationStack {
                                BlocksView(showingSidebar: $showingSidebar)
                                    .environmentObject(projectViewModel)
                                    .environmentObject(focusViewModel)
                            }
                            .transition(.opacity)
                            .onAppear {
                                // Clear selected project when switching to Blocks tab
                                selectedProject = nil
                            }
                        }
                    }
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 51) // Reserve space for tab bar
                    }
                    .zIndex(0) // Base layer
                    
                    // Bottom bar layers in z-order
                    
                    // Tab bar - always stays at bottom
                    VStack(spacing: 0) {
                        Spacer()
                        CustomTabBar(selectedTab: $selectedTab, focusViewModel: focusViewModel)
                            .frame(height: 51)
                            .background(
                                Rectangle()
                                    .fill(colorScheme == .dark ? Color.black : Color(.systemGray6))
                            )
                    }
                    .zIndex(10) // Always on top of content
                    .ignoresSafeArea(.keyboard, edges: .bottom) // Stay fixed at bottom
                    
                    // Chat input - positioned directly above tab bar
                    if !focusViewModel.isActive && !focusViewModel.isExpanded {
                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            GlobalChatInput(taskViewModel: taskViewModel)
                                .padding(.bottom, keyboardHandler.keyboardHeight > 0 ? 0 : 51)
                                .offset(y: keyboardHandler.keyboardHeight > 0 ? geometry.size.height - keyboardHandler.keyboardHeight - 124 : 0)
                                .animation(
                                    .interpolatingSpring(
                                        mass: 0.8,  // Reduced mass for faster response
                                        stiffness: 120,  // Increased stiffness
                                        damping: 14.0,  // Slightly reduced damping
                                        initialVelocity: 0.5  // Added initial velocity
                                    ),
                                    value: keyboardHandler.keyboardHeight
                                )
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(20) // Above tab bar
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
                            .padding(.bottom, 51) // Space for tab bar
                        }
                        .zIndex(30) // Above chat input
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
                            .padding(.bottom, 71) // Position above tab bar
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(40) // Above minimized focus
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
                            .zIndex(50) // Above toast
                    }
                    
                    // Sidebar overlay
                    if showingSidebar {
                        // Background dim overlay (without move transition)
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showingSidebar = false
                                    HapticManager.shared.impact(style: .light)
                                }
                            }
                            .transition(.opacity)
                            .zIndex(60)
                        
                        // Sidebar content (with move transition)
                        ZStack(alignment: .leading) {
                            SidebarMenu(
                                taskViewModel: taskViewModel,
                                isShowingSidebar: $showingSidebar,
                                selectedProject: $selectedProject
                            )
                            .environmentObject(projectViewModel)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.move(edge: .leading))
                        .zIndex(61) // Slightly higher than the background
                    }
                }
                // Add tap gesture to dismiss keyboard at ZStack level for better coverage
                .simultaneousGesture(
                    TapGesture()
                        .onEnded { _ in
                            // Only dismiss keyboard if it's shown (performance optimization)
                            if keyboardHandler.keyboardHeight > 0 {
                                hideKeyboard()
                            }
                        }
                )
                .onChange(of: colorScheme) { _, newValue in
                    // Update AppTheme at the app level as well
                    AppTheme.shared.updateColorScheme(newValue)
                }
                .onChange(of: showingSidebar) { _, newValue in
                    // Add haptic feedback when sidebar state changes
                    if newValue {
                        // Sidebar is being opened
                        HapticManager.shared.impact(style: .medium)
                    }
                }
                .onChange(of: selectedTab) { _, newValue in
                    // Clear selected project when switching to Blocks tab
                    if newValue == .blocks {
                        selectedProject = nil
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.9), value: focusViewModel.isExpanded)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingSidebar)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: taskViewModel.showingUndoToast)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: focusViewModel.isActive)
            }
            .task {
                // Preload projects when app starts
                await preloadData()
            }
        }
    }
    
    // Method to dismiss keyboard
    private func hideKeyboard() {
        UIApplication.shared.endEditing()
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
}

// MARK: - Preview Provider
struct ZenithApp_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            CustomTabBar(selectedTab: .constant(.today), focusViewModel: FocusSessionViewModel())
        }
    }
}
