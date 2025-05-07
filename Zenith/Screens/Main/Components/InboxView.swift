import SwiftUI

struct InboxView: View {
    @EnvironmentObject var taskViewModel: TaskViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var hasError = false
    @State private var inboxTasks: [TodoTask] = []
    @State private var showingCreateTask = false
    @State private var errorMessage: String?
    
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
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if hasError {
                ErrorView(
                    secondaryTextColor: secondaryTextColor,
                    textColor: textColor,
                    errorMessage: errorMessage ?? "Erro desconhecido. Tente novamente mais tarde.",
                    onRetry: loadInboxTasks
                )
            } else if inboxTasks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(secondaryTextColor)
                    
                    Text("Sua Entrada está vazia")
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    Text("Tarefas sem um projeto específico aparecem aqui")
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
                        ForEach(inboxTasks) { task in
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
                    loadInboxTasks()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                UnifiedToolbar(
                    title: "Entrada",
                    subtitle: DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
                    onSidebarTap: {}, // Optionally inject sidebar action if needed
                    trailing: AnyView(
                        Button(action: { showingCreateTask = true }) {
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundColor(textColor)
                        }
                    ),
                    textColor: colorScheme == .dark ? .white : .black,
                    backgroundColor: colorScheme == .dark ? .black : .white
                )
            }
        }
        .sheet(isPresented: $showingCreateTask) {
            CreateTaskFormView(
                viewModel: taskViewModel,
                onTaskSaved: {
                    loadInboxTasks()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            loadInboxTasks()
        }
    }
    
    private func loadInboxTasks() {
        isLoading = true
        hasError = false
        errorMessage = nil
        
        Task {
            do {
                // Fetch all tasks then filter for inbox
                try await taskViewModel.loadAllTasks()
                
                // Get inbox project tasks (not started)
                if let inboxProject = taskViewModel.getInboxProject() {
                    inboxTasks = taskViewModel.getTasksForProject(projectId: inboxProject.id)
                        .filter { $0.status == "NOT_STARTED" }
                } else {
                    inboxTasks = []
                }
                
                isLoading = false
            } catch {
                isLoading = false
                hasError = true
                errorMessage = error.localizedDescription
                print("Error loading inbox tasks: \(error)")
            }
        }
    }
}

// This is a simplified version, assuming TaskRowView already exists in your project
// If not, you'll need to implement it similar to how it's used in your TaskSectionView 