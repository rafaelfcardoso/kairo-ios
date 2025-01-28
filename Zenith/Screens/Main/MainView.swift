//
//  MainView.swift
//  Zenith
//
//  Created by Rafael Cardoso on 02/01/25.
//

import SwiftUI

// Error View Component
struct ErrorView: View {
    let secondaryTextColor: Color
    let textColor: Color
    let retryAction: () -> Void
    @State private var shouldRetry = false
    
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
            
            Button(action: {
                shouldRetry = true
                retryAction()
            }) {
                Text("Tentar novamente")
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
        }
        .padding()
    }
}

// Task List Component
struct TaskListView: View {
    @Binding var showingCreateTask: Bool
    let tasks: [Task]
    let secondaryTextColor: Color
    let cardBackgroundColor: Color
    let onTaskCreated: @Sendable () async -> Void
    @State private var shouldRefresh = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(tasks) { task in
                    TaskRow(task: task)
                }
                
                Button(action: {
                    showingCreateTask = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Adicionar tarefa")
                    }
                    .foregroundColor(secondaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(cardBackgroundColor)
                    .cornerRadius(12)
                }
                .sheet(isPresented: $showingCreateTask) {
                    CreateTaskView(onTaskCreated: {
                        await MainActor.run {
                            shouldRefresh = true
                        }
                        await onTaskCreated()
                        await MainActor.run {
                            shouldRefresh = false
                        }
                    })
                    .presentationDetents([.height(250)])
                    .presentationDragIndicator(.visible)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct MainView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var showingCreateTask = false
    @State private var isLoading = true
    @State private var hasError = false
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : Color(white: 0.95)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    ProgressView()
                } else if hasError {
                    ErrorView(
                        secondaryTextColor: secondaryTextColor,
                        textColor: textColor,
                        retryAction: {
                            isLoading = true
                            hasError = false
                        }
                    )
                    .task {
                        do {
                            try await viewModel.loadTasks()
                        } catch {
                            hasError = true
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        // Header section
                        VStack(alignment: .leading) {
                            Text("Domingo - 5 Jan")
                                .font(.subheadline)
                                .foregroundColor(secondaryTextColor)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        
                        TaskListView(
                            showingCreateTask: $showingCreateTask,
                            tasks: viewModel.tasks,
                            secondaryTextColor: secondaryTextColor,
                            cardBackgroundColor: cardBackgroundColor,
                            onTaskCreated: {
                                await viewModel.refreshTasks()
                            }
                        )
                        
                        Spacer()
                        
                        // Start focus button
                        Button(action: {
                            print("Focus Session Started")
                        }) {
                            Text("Iniciar Foco")
                                .foregroundColor(backgroundColor)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(textColor)
                                .font(.system(size: 16, weight: .semibold))
                                .cornerRadius(25)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Text("Energia Mental")
                        .foregroundColor(secondaryTextColor)
                        .font(.subheadline)
                }
            }
            .task {
                do {
                    isLoading = true
                    try await viewModel.loadTasks()
                    isLoading = false
                } catch {
                    isLoading = false
                    hasError = true
                }
            }
            .refreshable {
                do {
                    hasError = false
                    try await viewModel.loadTasks(isRefreshing: true)
                } catch {
                    hasError = true
                }
            }
            .navigationTitle("Hoje")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Task row component
struct TaskRow: View {
    let task: Task
    @Environment(\.colorScheme) var colorScheme
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : Color(white: 0.95)
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var circleColor: Color {
        switch task.priority.lowercased() {
        case "high":
            return .red
        case "medium":
            return .yellow
        case "low":
            return .blue
        default:
            return secondaryTextColor
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Circle()
                .strokeBorder(circleColor, lineWidth: 1.5)
                .frame(width: 24, height: 20)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .foregroundColor(textColor)
                
                if let description = task.description {
                    Text(description)
                        .foregroundColor(secondaryTextColor)
                        .font(.subheadline)
                }
                
                HStack(spacing: 8) {
                    if let project = task.project {
                        Text(project.name)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: project.color).opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .previewDisplayName("Main View")
    }
} 
