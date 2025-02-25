//
//  MainView.swift
//  Zenith
//
//  Created by Rafael Cardoso on 02/01/25.
//

import SwiftUI
import _Concurrency
import Foundation

// Error View Component
struct ErrorView: View {
    let secondaryTextColor: Color
    let textColor: Color
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundColor(secondaryTextColor)
            
            Text("Não foi possível carregar as tarefas")
                .font(.headline)
                .foregroundColor(textColor)
            
            Text("Verifique sua conexão e tente novamente")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
                .multilineTextAlignment(.center)
            
            Button(action: retryAction) {
                Text("Tentar novamente")
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
        }
        .padding()
    }
}

struct MainView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @State private var showingCreateTask = false
    @State private var isLoading = true
    @State private var hasError = false
    @State private var selectedTab = 0
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var focusSessionViewModel: FocusSessionViewModel
    
    var backgroundColor: Color {
        colorScheme == .dark ? .black : Color(hex: "F1F2F4")
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : Color(hex: "7E7E7E")
    }
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : .white
    }
    
    var highlightColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var inactiveColor: Color {
        colorScheme == .dark ? .gray : Color(hex: "7E7E7E")
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if isLoading {
                        ProgressView()
                    } else if hasError {
                        ErrorView(
                            secondaryTextColor: secondaryTextColor,
                            textColor: textColor,
                            retryAction: {
                                Task {
                                    isLoading = true
                                    hasError = false
                                    do {
                                        try await viewModel.loadAllTasks()
                                        isLoading = false
                                    } catch {
                                        isLoading = false
                                        hasError = true
                                    }
                                }
                            }
                        )
                    } else {
                        // Main content
                        VStack(spacing: 0) {
                            if !viewModel.overdueTasks.isEmpty {
                                TabView(selection: $selectedTab) {
                                    // Overdue Section
                                    TaskSectionView(
                                        title: "Atrasadas",
                                        tasks: viewModel.overdueTasks,
                                        secondaryTextColor: secondaryTextColor,
                                        cardBackgroundColor: cardBackgroundColor,
                                        onTaskCreated: {
                                            do {
                                                try await viewModel.loadAllTasks()
                                            } catch {
                                                print("Error refreshing tasks: \(error)")
                                            }
                                        },
                                        viewModel: viewModel,
                                        showingCreateTask: $showingCreateTask
                                    )
                                    .tag(0)
                                    .refreshable {
                                        do {
                                            try await viewModel.loadAllTasks()
                                        } catch {
                                            print("Error refreshing tasks: \(error)")
                                        }
                                    }
                                    
                                    // Today Section
                                    TaskSectionView(
                                        title: "Hoje",
                                        tasks: viewModel.tasks,
                                        secondaryTextColor: secondaryTextColor,
                                        cardBackgroundColor: cardBackgroundColor,
                                        onTaskCreated: {
                                            do {
                                                try await viewModel.loadAllTasks()
                                            } catch {
                                                print("Error refreshing tasks: \(error)")
                                            }
                                        },
                                        viewModel: viewModel,
                                        showingCreateTask: $showingCreateTask
                                    )
                                    .tag(1)
                                    .refreshable {
                                        do {
                                            try await viewModel.loadAllTasks()
                                        } catch {
                                            print("Error refreshing tasks: \(error)")
                                        }
                                    }
                                }
                                .tabViewStyle(.page)
                                .indexViewStyle(.page(backgroundDisplayMode: .always))
                            } else {
                                TaskSectionView(
                                    title: "Hoje",
                                    tasks: viewModel.tasks,
                                    secondaryTextColor: secondaryTextColor,
                                    cardBackgroundColor: cardBackgroundColor,
                                    onTaskCreated: {
                                        do {
                                            try await viewModel.loadAllTasks()
                                        } catch {
                                            print("Error refreshing tasks: \(error)")
                                        }
                                    },
                                    viewModel: viewModel,
                                    showingCreateTask: $showingCreateTask
                                )
                                .refreshable {
                                    do {
                                        try await viewModel.loadAllTasks()
                                    } catch {
                                        print("Error refreshing tasks: \(error)")
                                    }
                                }
                            }
                            
                            // Update the Start Focus Button
                            if !focusSessionViewModel.isActive {
                                Button {
                                    focusSessionViewModel.isExpanded = true
                                } label: {
                                    HStack {
                                        Image(systemName: "timer")
                                            .font(.headline)
                                        Text("Iniciar Foco")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }
                    }
                }
                
                if viewModel.showingUndoToast {
                    UndoToastView(
                        message: "\"\(viewModel.lastCompletedTaskTitle)\" concluída",
                        action: {
                            do {
                                try await viewModel.undoLastCompletion()
                                withAnimation {
                                    viewModel.showingUndoToast = false
                                }
                            } catch {
                                print("Error undoing task completion: \(error)")
                            }
                        },
                        isPresented: $viewModel.showingUndoToast
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(viewModel.greeting)
                            .font(.headline)
                            .foregroundColor(textColor)
                        
                        Text(viewModel.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                    }
                }
            }
            .task {
                do {
                    isLoading = true
                    try await viewModel.loadAllTasks()
                    isLoading = false
                } catch {
                    isLoading = false
                    hasError = true
                }
            }
            .sheet(isPresented: $showingCreateTask) {
                CreateTaskFormView(
                    viewModel: viewModel,
                    onTaskSaved: {
                        Task {
                            do {
                                try await viewModel.loadAllTasks()
                            } catch {
                                print("Error refreshing tasks: \(error)")
                            }
                        }
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .interactiveDismissDisabled(false)
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "rectangle.stack")
                    Text("Dashboard")
                }
            
            MainView()
                .tabItem {
                    Image(systemName: "filemenu.and.selection")
                    Text("Hoje")
                }
        }
        .onAppear {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithTransparentBackground()
            tabBarAppearance.backgroundColor = .systemBackground.withAlphaComponent(0.8)
            
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            UITabBar.appearance().standardAppearance = tabBarAppearance
        }
    }
} 