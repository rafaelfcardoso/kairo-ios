import SwiftUI

struct ProjectTasksView: View {
    let project: Project
    @EnvironmentObject var taskViewModel: TaskViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var hasError = false
    @State private var projectTasks: [TodoTask] = []
    @State private var showingCreateTask = false
    
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
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                } else if hasError {
                    ErrorView(
                        secondaryTextColor: secondaryTextColor,
                        textColor: textColor,
                        retryAction: loadProjectTasks
                    )
                } else if projectTasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: project.color))
                        
                        Text("Nenhuma tarefa")
                            .font(.headline)
                            .foregroundColor(textColor)
                        
                        Text("Este projeto ainda não possui tarefas")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Button {
                            showingCreateTask = true
                        } label: {
                            Text("Criar tarefa")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(projectTasks) { task in
                                TaskRow(
                                    task: task,
                                    viewModel: taskViewModel,
                                    isOverdue: false
                                )
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        loadProjectTasks()
                    }
                }
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateTask = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(textColor)
                }
            }
        }
        .sheet(isPresented: $showingCreateTask) {
            CreateTaskFormView(
                viewModel: taskViewModel,
                onTaskSaved: {
                    loadProjectTasks()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            loadProjectTasks()
        }
    }
    
    private func loadProjectTasks() {
        isLoading = true
        hasError = false
        
        Task {
            do {
                // Fetch all tasks then filter for this project
                try await taskViewModel.loadAllTasks()
                
                // Get tasks for this project (not started)
                projectTasks = taskViewModel.getTasksForProject(projectId: project.id)
                    .filter { $0.status == "NOT_STARTED" }
                
                isLoading = false
            } catch {
                isLoading = false
                hasError = true
                print("Error loading project tasks: \(error)")
            }
        }
    }
}

// Assuming ErrorView is already defined elsewhere in your project
// If not, ensure it's implemented similar to the version from MainView 