//
//  ZenithApp.swift
//  Zenith
//
//  Created by Rafael Cardoso on 18/12/24.
//

import SwiftUI

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
    var onCreateTapped: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            // Left tab
            tabButton(for: .today)
            
            // Center create button
            createButton
            
            // Right tab
            tabButton(for: .blocks)
        }
        .frame(height: 50)
        .background(
            // Change from translucent material to opaque color
            Rectangle()
                .fill(colorScheme == .dark ? Color(white: 0.1) : AppTheme.shared.backgroundColor)
                .edgesIgnoringSafeArea(.bottom)
                //.shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -5)
        )
        .onAppear {
            // Update AppTheme when the tab bar appears
            AppTheme.shared.updateColorScheme(colorScheme)
        }
        .onChange(of: colorScheme) { _, newValue in
            // Keep AppTheme in sync with color scheme changes
            AppTheme.shared.updateColorScheme(newValue)
        }
    }
    
    private var createButton: some View {
        Button(action: {
            HapticManager.shared.impact(style: .light)
            onCreateTapped()
        }) {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark ? Color(hex: "F1F2F4") : .black)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .black : .white)
            }
        }
        .offset(y: -8) // Reduced offset to better align with tab icons
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
    @State private var selectedTab: Tab = .today
    @State private var showingTaskInput = false
    @Environment(\.colorScheme) var colorScheme
    @State private var showingSidebar = false
    @State private var selectedProject: Project?
    
    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottom) {
                // Main content area
                ZStack {
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
                    Color.clear.frame(height: 50) // Reserve space for tab bar
                }
                .zIndex(0) // Base content z-index

                // Minimized Focus Session that sits above content but below sidebar
                if focusViewModel.isActive && focusViewModel.isMinimized {
                    VStack {
                        Spacer()
                        
                        // Add background directly to the session view
                        MinimizedFocusSession(
                            taskTitle: focusViewModel.selectedTask?.title,
                            progress: focusViewModel.progress,
                            remainingTime: focusViewModel.remainingTime,
                            blockDistractions: focusViewModel.blockDistractions,
                            onExpand: focusViewModel.expandSession
                        )
                        .background(
                            // Replace translucent material with opaque background
                            Rectangle()
                                .fill(colorScheme == .dark ? Color(white: 0.1) : .white)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
                        )
                        .transition(.move(edge: .bottom))
                    }
                    .padding(.bottom, 50) // Match tab bar height
                    .zIndex(10) // Above content, below sidebar and tab bar
                }
                
                // Custom tab bar - sits above normal content and minimized focus
                CustomTabBar(selectedTab: $selectedTab, onCreateTapped: {
                    showingTaskInput = true
                })
                .zIndex(20) // Higher than content and minimized focus
            }
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
            
            // Full-screen focus session overlay
            .overlay {
                if focusViewModel.isExpanded {
                    FocusSessionView()
                        .environmentObject(taskViewModel)
                        .environmentObject(focusViewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                        .zIndex(50) // High priority for focus
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.9), value: focusViewModel.isExpanded)
            
            // Sidebar overlay at app level (highest z-index)
            .overlay {
                if showingSidebar {
                    SidebarMenu(
                        taskViewModel: taskViewModel,
                        isShowingSidebar: $showingSidebar,
                        selectedProject: $selectedProject
                    )
                    .environmentObject(projectViewModel)
                    .transition(.move(edge: .leading))
                    .zIndex(100) // Highest z-index to be above everything
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingSidebar)
            
            // Task input sheet
            .sheet(isPresented: $showingTaskInput) {
                TaskInputView(
                    onSubmit: { taskText in
                        do {
                            try await taskViewModel.createTaskFromNaturalLanguage(taskText)
                        } catch {
                            print("Error creating task: \(error)")
                        }
                    },
                    onDismiss: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingTaskInput = false
                        }
                    }
                )
                .presentationDetents([.height(80)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(16)
                .presentationBackground(AppTheme.shared.backgroundColor)
            }
            .task {
                // Preload projects when app starts
                await preloadData()
            }
        }
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
            CustomTabBar(selectedTab: .constant(.today), onCreateTapped: {})
        }
    }
}
