import SwiftUI

struct InboxView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var showingCreateTask = false
    @State private var isLoading = true
    @State private var hasError = false
    @Environment(\.colorScheme) var colorScheme
    
    private let inboxProjectId = "569c363f-1934-4e69-b324-6c2fad28bc59"
    
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
                        try await viewModel.loadTasks(projectId: inboxProjectId)
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
                        await viewModel.refreshTasks(projectId: inboxProjectId)
                    },
                    viewModel: viewModel
                )
            }
        }
        .navigationTitle("Entrada")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            do {
                isLoading = true
                try await viewModel.loadTasks(projectId: inboxProjectId)
                isLoading = false
            } catch {
                isLoading = false
                hasError = true
            }
        }
        .refreshable {
            do {
                hasError = false
                try await viewModel.loadTasks(projectId: inboxProjectId, isRefreshing: true)
            } catch {
                hasError = true
            }
        }
    }
} 