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
    let tasks: [TodoTask]
    let secondaryTextColor: Color
    let cardBackgroundColor: Color
    let onTaskCreated: @Sendable () async -> Void
    let viewModel: TaskViewModel
    @State private var shouldRefresh = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(tasks) { task in
                    TaskRow(task: task, viewModel: viewModel)
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
        .task(id: shouldRefresh) {
            if shouldRefresh {
                await onTaskCreated()
                await MainActor.run {
                    shouldRefresh = false
                }
            }
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
                            },
                            viewModel: viewModel
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
    let task: TodoTask
    let viewModel: TaskViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var isCompleting = false
    
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
            return Color(hex: "FF6B6B")
        case "medium":
            return Color(hex: "FFA94D")
        case "low":
            return Color(hex: "4D96FF")
        default:
            return secondaryTextColor
        }
    }
    
    private var formattedTime: String? {
        guard let dueDateString = task.dueDate else {
            print("Debug: No due date string available")
            return nil
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let dueDate = formatter.date(from: dueDateString) else {
            print("Debug: Could not parse date from string: \(dueDateString)")
            return nil
        }
        
        // Check if the time component is not midnight (00:00)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: dueDate)
        let minute = calendar.component(.minute, from: dueDate)
        
        if hour == 0 && minute == 0 {
            print("Debug: Time is midnight (00:00), not showing time")
            return nil
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .none
        let formattedResult = timeFormatter.string(from: dueDate)
        print("Debug: Formatted time: \(formattedResult)")
        return formattedResult
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isCompleting = true
                }
            }) {
                ZStack {
                    Circle()
                        .strokeBorder(circleColor, lineWidth: 1.5)
                        .frame(width: 24, height: 20)
                    
                    if isCompleting {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(circleColor)
                            .font(.system(size: 20))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .task(id: isCompleting) {
                if isCompleting {
                    do {
                        try await Task.sleep(nanoseconds: 200_000_000)
                        try await viewModel.completeTask(task)
                    } catch {
                        print("Error completing task: \(error)")
                        isCompleting = false
                    }
                }
            }
            .padding(.top, 4)
            .disabled(isCompleting)
            
            VStack(alignment: .leading, spacing: task.description == nil ? 0 : 4) {
                Text(task.title)
                    .foregroundColor(textColor)
                    .opacity(isCompleting ? 0.5 : 1)
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .foregroundColor(secondaryTextColor)
                        .font(.subheadline)
                        .opacity(isCompleting ? 0.5 : 1)
                }
                
                HStack(spacing: 8) {
                    if let time = formattedTime {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                            Text(time)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                        .foregroundColor(.green)
                    }
                    if task.project == nil {
                        HStack(spacing: 4) {
                            Image(systemName: "tray")
                                .font(.system(size: 12))
                            Text("Entrada")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundColor(secondaryTextColor)
                    } else if let project = task.project {
                        Text(project.name)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: project.color).opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                .opacity(isCompleting ? 0.5 : 1)
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
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "rectangle.stack")
                    Text("Dashboard")
                }
            
            MainView()
                .tabItem {
                    Image(systemName: "calendar.day.timeline.left")
                    Text("Hoje")
                }
        }
    }
} 
