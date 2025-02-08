import SwiftUI

struct ProjectTasksView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var showingCreateTask = false
    @State private var isLoading = true
    @State private var hasError = false
    @Environment(\.colorScheme) var colorScheme
    
    let project: Project
    
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
                        try await viewModel.loadTasks(projectId: project.id)
                    } catch {
                        hasError = true
                    }
                }
            } else {
                TaskListView(
                    showingCreateTask: $showingCreateTask,
                    tasks: viewModel.tasks,
                    secondaryTextColor: secondaryTextColor,
                    cardBackgroundColor: cardBackgroundColor,
                    onTaskCreated: {
                        await viewModel.refreshTasks(projectId: project.id)
                    },
                    viewModel: viewModel
                )
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Circle()
                    .fill(Color(hex: project.color))
                    .frame(width: 12, height: 12)
            }
        }
        .task {
            do {
                isLoading = true
                try await viewModel.loadTasks(projectId: project.id)
                isLoading = false
            } catch {
                isLoading = false
                hasError = true
            }
        }
        .refreshable {
            do {
                hasError = false
                try await viewModel.loadTasks(projectId: project.id, isRefreshing: true)
            } catch {
                hasError = true
            }
        }
    }
} 