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
        colorScheme == .dark ? .white : .black
    }
    
    var inactiveColor: Color {
        Color(hex: "7E7E7E")
    }
    
    private init() {}
}

// MARK: - Tab Bar Style
struct CustomTabBarStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                updateTabBarAppearance()
            }
            .onChange(of: colorScheme) { _, _ in
                updateTabBarAppearance()
            }
    }
    
    private func updateTabBarAppearance() {
        let appearance = UITabBarAppearance()
        
        // Background configuration
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        
        // Normal state
        let normalColor = UIColor(AppTheme.shared.inactiveColor)
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        
        // Selected state
        let selectedColor = colorScheme == .dark ? UIColor.white : UIColor.black
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        
        // Plus button (create tab) - always use the selected color
        let createTabAppearance = UITabBarItemAppearance()
        createTabAppearance.normal.iconColor = selectedColor
        createTabAppearance.selected.iconColor = selectedColor
        
        // Apply the special appearance to the middle tab (index 2)
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        
        // Add transparent background for the middle tab
        appearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 100) // Move title off screen
        appearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 100)
        
        // Apply appearance
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Main Navigation
enum Tab: Hashable {
    case dashboard
    case today
    case create
    case blocks
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .today: return "Hoje"
        case .create: return ""  // Empty title for the plus button
        case .blocks: return "Blocks"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "rectangle.stack.fill"
        case .today: return "filemenu.and.selection"
        case .create: return "plus.circle.fill"
        case .blocks: return "rectangle.stack.badge.plus"
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
}

// MARK: - Main App
@main
struct ZenithApp: App {
    @StateObject private var taskViewModel = TaskViewModel()
    @StateObject private var focusViewModel = FocusSessionViewModel()
    @State private var selectedTab: Tab = .today
    @State private var showingTaskInput = false
    @State private var showingFocusSession = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    DashboardView()
                        .environmentObject(taskViewModel)
                        .tag(Tab.dashboard)
                        .tabItem {
                            Label(Tab.dashboard.title, systemImage: Tab.dashboard.icon)
                        }
                        .safeAreaInset(edge: .bottom) {
                            if focusViewModel.isActive && focusViewModel.isMinimized {
                                Color.clear.frame(height: 64)
                            }
                        }
                    
                    MainView()
                        .environmentObject(taskViewModel)
                        .environmentObject(focusViewModel)
                        .tag(Tab.today)
                        .tabItem {
                            Label(Tab.today.title, systemImage: Tab.today.icon)
                        }
                        .safeAreaInset(edge: .bottom) {
                            if focusViewModel.isActive && focusViewModel.isMinimized {
                                Color.clear.frame(height: 64)
                            }
                        }
                    
                    Color.clear
                        .tag(Tab.create)
                        .tabItem {
                            Image(systemName: Tab.create.icon)
                                .font(.system(size: 22, weight: .semibold))
                        }
                    
                    BlocksView()
                        .tag(Tab.blocks)
                        .tabItem {
                            Label(Tab.blocks.title, systemImage: Tab.blocks.icon)
                        }
                        .safeAreaInset(edge: .bottom) {
                            if focusViewModel.isActive && focusViewModel.isMinimized {
                                Color.clear.frame(height: 64)
                            }
                        }
                }
                .onChange(of: selectedTab) { oldTab, newTab in
                    if newTab == .create {
                        showingTaskInput = true
                        withAnimation(.none) {
                            selectedTab = oldTab
                        }
                    }
                }
                .onChange(of: colorScheme) { _, newValue in
                    AppTheme.shared.colorScheme = newValue
                }
                .modifier(CustomTabBarStyle())
                .tint(AppTheme.shared.activeColor)
                
                // Minimized Focus Session
                if focusViewModel.isActive && focusViewModel.isMinimized {
                    MinimizedFocusSession(
                        taskTitle: focusViewModel.selectedTask?.title ?? "Sessão de Foco",
                        progress: focusViewModel.progress,
                        remainingTime: focusViewModel.remainingTime,
                        blockDistractions: focusViewModel.blockDistractions,
                        onExpand: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                focusViewModel.isMinimized = false
                                showingFocusSession = true
                            }
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $showingFocusSession) {
                FocusSessionView()
                    .environmentObject(taskViewModel)
                    .environmentObject(focusViewModel)
            }
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
        }
    }
}

// MARK: - Preview Provider
#Preview("Light Mode") {
    TabView {
        DashboardView()
            .tabItem {
                Label(Tab.dashboard.title, systemImage: Tab.dashboard.icon)
            }
        
        MainView()
            .tabItem {
                Label(Tab.today.title, systemImage: Tab.today.icon)
            }
        
        Color.clear
            .tabItem {
                Image(systemName: Tab.create.icon)
                    .font(.system(size: 22, weight: .semibold))
            }
        
        BlocksView()
            .tabItem {
                Label(Tab.blocks.title, systemImage: Tab.blocks.icon)
            }
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    TabView {
        DashboardView()
            .tabItem {
                Label(Tab.dashboard.title, systemImage: Tab.dashboard.icon)
            }
        
        MainView()
            .tabItem {
                Label(Tab.today.title, systemImage: Tab.today.icon)
            }
        
        Color.clear
            .tabItem {
                Image(systemName: Tab.create.icon)
                    .font(.system(size: 22, weight: .semibold))
            }
        
        BlocksView()
            .tabItem {
                Label(Tab.blocks.title, systemImage: Tab.blocks.icon)
            }
    }
    .preferredColorScheme(.dark)
}
