//
//  ProjectZenithApp.swift
//  ProjectZenith
//
//  Created by Rafael Cardoso on 18/12/24.
//

import SwiftUI

@main
struct ProjectZenithApp: App {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab: Tab = .today
    
    enum Tab {
        case dashboard
        case today
    }
    
    var backgroundColor: Color {
        colorScheme == .dark ? .black : Color(hex: "F1F2F4")
    }
    
    var activeColor: Color {
        colorScheme == .dark ? Color(hex: "F1F2F4") : .black
    }
    
    var inactiveColor: Color {
        Color(hex: "7E7E7E")
    }
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "rectangle.stack.fill")
                            .environment(\.symbolVariants, selectedTab == .dashboard ? .fill : .none)
                    }
                    .tag(Tab.dashboard)
                
                MainView()
                    .tabItem {
                        Label("Hoje", systemImage: "filemenu.and.selection")
                            .environment(\.symbolVariants, selectedTab == .today ? .fill : .none)
                    }
                    .tag(Tab.today)
            }
            .accentColor(activeColor)
            .background(backgroundColor)
            .onAppear {
                // Customize unselected tab item color
                UITabBar.appearance().unselectedItemTintColor = UIColor(named: "7E7E7E")
            }
        }
    }
}

struct ProjectZenithApp_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "rectangle.stack.fill")
                    }
                
                MainView()
                    .tabItem {
                        Label("Hoje", systemImage: "filemenu.and.selection")
                    }
            }
            .accentColor(.white)
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
            
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "rectangle.stack.fill")
                    }
                
                MainView()
                    .tabItem {
                        Label("Hoje", systemImage: "filemenu.and.selection")
                    }
            }
            .accentColor(.black)
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
        }
    }
}
