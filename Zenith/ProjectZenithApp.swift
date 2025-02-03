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
    
    var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView()
                    .tabItem {
                        Image(systemName: "chart.bar")
                        Text("Dashboard")
                    }
                    .tag(0)
                
                MainView()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Hoje")
                    }
                    .tag(1)
            }
            .background(backgroundColor)
        }
    }
}
