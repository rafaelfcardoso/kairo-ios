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
        colorScheme == .dark ? .black : .white
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
        appearance.backgroundColor = UIColor(colorScheme == .dark ? .black : Color(hex: "F1F2F4"))
        
        // Normal state
        let normalColor = UIColor(AppTheme.shared.inactiveColor)
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        
        // Selected state
        let selectedColor = colorScheme == .dark ? UIColor.white : UIColor.black
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        
        // Apply appearance
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Main Navigation
enum Tab: Hashable {
    case dashboard
    case today
    case blocks
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .today: return "Hoje"
        case .blocks: return "Blocks"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "rectangle.stack.fill"
        case .today: return "filemenu.and.selection"
        case .blocks: return "rectangle.stack.badge.plus"
        }
    }
}

// MARK: - Main App
@main
struct ZenithApp: App {
    @State private var selectedTab: Tab = .today
    @Environment(\.colorScheme) var colorScheme
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(Tab.dashboard)
                    .tabItem {
                        Label(Tab.dashboard.title, systemImage: Tab.dashboard.icon)
                            .environment(\.symbolVariants, selectedTab == .dashboard ? .fill : .none)
                    }
                
                MainView()
                    .tag(Tab.today)
                    .tabItem {
                        Label(Tab.today.title, systemImage: Tab.today.icon)
                            .environment(\.symbolVariants, selectedTab == .today ? .fill : .none)
                    }
                
                BlocksView()
                    .tag(Tab.blocks)
                    .tabItem {
                        Label(Tab.blocks.title, systemImage: Tab.blocks.icon)
                            .environment(\.symbolVariants, selectedTab == .blocks ? .fill : .none)
                    }
            }
            .onChange(of: colorScheme) { _, newValue in
                AppTheme.shared.colorScheme = newValue
            }
            .modifier(CustomTabBarStyle())
            .tint(AppTheme.shared.activeColor)
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
        
        BlocksView()
            .tabItem {
                Label(Tab.blocks.title, systemImage: Tab.blocks.icon)
            }
    }
    .preferredColorScheme(.dark)
}
