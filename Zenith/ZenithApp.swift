//
//  ZenithApp.swift
//  Zenith
//
//  Created by Rafael Cardoso on 18/12/24.
//

import SwiftUI
import Combine
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
                
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
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
    @State private var isAuthenticated: Bool
    @StateObject private var authViewModel = AuthViewModel()
    init() {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-reset-auth") {
            APIConfig.authToken = nil
        }
#endif
        // Initialize AFTER clearing token
        _isAuthenticated = State(initialValue: APIConfig.authToken != nil)
        _chatViewModel = StateObject(wrappedValue: GlobalChatViewModel())
    }
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var focusViewModel = FocusSessionViewModel()
    @StateObject private var projectViewModel = ProjectViewModel()
    @StateObject private var keyboardHandler = KeyboardHeightHandler() // Track keyboard
    @StateObject private var chatViewModel: GlobalChatViewModel
    @State private var selectedTab: Tab = .today
    @Environment(\.colorScheme) var colorScheme
    @State private var showingSidebar = false
    @State private var selectedProject: Project?
    @State private var chatInputRef: GlobalChatInput? = nil
    
    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                AppMainView(
                    taskViewModel: taskViewModel,
                    focusViewModel: focusViewModel,
                    projectViewModel: projectViewModel,
                    keyboardHandler: keyboardHandler,
                    chatViewModel: chatViewModel,
                    showingSidebar: $showingSidebar,
                    selectedProject: $selectedProject,
                    selectedTab: $selectedTab,
                    isAuthenticated: $isAuthenticated
                )
                .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
                    .onChange(of: APIConfig.authToken) { _, newValue in
                        if newValue != nil {
                            isAuthenticated = true
                        }
                    }
                    .onChange(of: authViewModel.userName) { _, _ in
                        // No-op, ensures view updates
                    }
            }
        }

    }
    
    // Method to dismiss keyboard
    private func hideKeyboard() {
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
