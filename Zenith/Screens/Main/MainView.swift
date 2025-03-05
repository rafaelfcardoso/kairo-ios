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
    var errorMessage: String? = nil
    var isOfflineMode: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isOfflineMode ? "wifi.slash" : "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(secondaryTextColor)
            
            Text(isOfflineMode ? "Modo Offline" : "Não foi possível carregar as tarefas")
                .font(.headline)
                .foregroundColor(textColor)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text(isOfflineMode ? 
                     "Você está trabalhando offline. Algumas funcionalidades podem estar limitadas." : 
                     "Verifique sua conexão e tente novamente")
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: retryAction) {
                Text("Tentar novamente")
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
            
            if isOfflineMode {
                Text("Última atualização: \(formattedLastUpdate)")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
    
    private var formattedLastUpdate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

struct MainView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @State private var showingCreateTask = false
    @State private var isLoading = true
    @State private var hasError = false
    @State private var errorMessage: String? = nil
    @State private var selectedTab = 0
    @Binding var showingSidebar: Bool
    @State private var navigationPath = NavigationPath()
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var focusSessionViewModel: FocusSessionViewModel
    @State private var selectedFilterName: String = "Hoje"
    
    // Use app-level binding for selected project
    @Binding var selectedProject: Project?
    
    init(showingSidebar: Binding<Bool>) {
        self._showingSidebar = showingSidebar
        // Create a default empty binding for selectedProject
        self._selectedProject = .constant(nil)
    }
    
    // Constructor that accepts both bindings
    init(showingSidebar: Binding<Bool>, selectedProject: Binding<Project?>) {
        self._showingSidebar = showingSidebar
        self._selectedProject = selectedProject
    }
    
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
    
    var displayedTasks: [TodoTask] {
        if let project = selectedProject {
            return viewModel.getTasksForProject(projectId: project.id)
        } else {
            // Return tasks based on selected filter name
            switch selectedFilterName {
            case "Hoje":
                return viewModel.todayTasks
            case "Próximas":
                return viewModel.upcomingTasks
            case "Entrada":
                return viewModel.inboxTasks
            case "Concluídas":
                return viewModel.completedTasks
            case "Foco":
                return viewModel.focusTasks
            default:
                return viewModel.todayTasks
            }
        }
    }
    
    var screenTitle: String {
        if let project = selectedProject {
            return project.name
        } else {
            return "Início"
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottom) {
                backgroundColor
                    .ignoresSafeArea()
                
                VStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 100)
                    } else if hasError && !viewModel.isOfflineMode {
                        ErrorView(
                            secondaryTextColor: secondaryTextColor,
                            textColor: textColor,
                            retryAction: {
                                Task {
                                    await performTaskLoad()
                                }
                            },
                            errorMessage: errorMessage
                        )
                    } else if viewModel.isOfflineMode {
                        VStack {
                            // Offline banner
                            HStack {
                                Image(systemName: "wifi.slash")
                                    .foregroundColor(secondaryTextColor)
                                Text("Modo Offline")
                                    .font(.subheadline)
                                    .foregroundColor(secondaryTextColor)
                                Spacer()
                                Button("Reconectar") {
                                    Task {
                                        await performTaskLoad()
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .padding(.top)
                            
                            // Show cached content
                            TaskContentView(
                                selectedProject: $selectedProject,
                                selectedTab: $selectedTab,
                                viewModel: viewModel,
                                showingCreateTask: $showingCreateTask,
                                secondaryTextColor: secondaryTextColor,
                                cardBackgroundColor: cardBackgroundColor,
                                displayedTasks: displayedTasks,
                                onLoadTasks: { @Sendable in
                                    await self.performTaskLoad()
                                }
                            )
                        }
                    } else {
                        TaskContentView(
                            selectedProject: $selectedProject,
                            selectedTab: $selectedTab,
                            viewModel: viewModel,
                            showingCreateTask: $showingCreateTask,
                            secondaryTextColor: secondaryTextColor,
                            cardBackgroundColor: cardBackgroundColor,
                            displayedTasks: displayedTasks,
                            onLoadTasks: { @Sendable in
                                await self.performTaskLoad()
                            }
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    sidebarButton
                }
                
                ToolbarItem(placement: .principal) {
                    titleView
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            .task {
                await performTaskLoad()
            }
            .sheet(isPresented: $showingCreateTask) {
                CreateTaskFormView(
                    viewModel: viewModel,
                    onTaskSaved: { @Sendable in
                        Task {
                            await self.performTaskLoad()
                        }
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .interactiveDismissDisabled(false)
            }
            .onChange(of: selectedProject) { _, _ in
                Task {
                    await performTaskLoad()
                }
            }
            .navigationDestination(for: Project.self) { project in
                if project.isSystem {
                    InboxView()
                        .environmentObject(viewModel)
                } else {
                    ProjectTasksView(project: project)
                        .environmentObject(viewModel)
                }
            }
        }
    }
    
    // MARK: - Toolbar Components
    
    private var sidebarButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showingSidebar = true
                HapticManager.shared.impact(style: .medium)
            }
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.title3)
                .foregroundColor(textColor)
        }
        .accessibilityLabel("Open sidebar")
    }
    
    private var titleView: some View {
        VStack(spacing: 2) {
            Text(viewModel.greeting)
                .font(.headline)
                .foregroundColor(textColor)
            
            Text(viewModel.formattedDate)
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
        }
    }
    
    private var addButton: some View {
        Button {
            showingCreateTask = true
        } label: {
            Image(systemName: "plus")
                .font(.title3)
                .foregroundColor(textColor)
        }
        .accessibilityLabel("Add task")
        .accessibilityIdentifier("add-task-button")
    }
    
    // MARK: - Data Loading
    
    private func loadTasks() async throws {
        if selectedProject != nil {
            // Load tasks for the specific project
            try await viewModel.loadAllTasks() // Load all tasks then filter in displayedTasks
        } else {
            // Load normal tasks (today + overdue)
            try await viewModel.loadAllTasks()
        }
    }
    
    // Add a simplified handler for loading tasks that automatically handles errors
    @Sendable
    private func performTaskLoad() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if selectedProject != nil {
                // If a project is selected, load tasks for that project
                try await viewModel.loadTasks()
            } else {
                // Otherwise, load tasks based on the selected filter
                try await viewModel.loadTasks()
            }
            
            hasError = false
        } catch {
            hasError = true
            
            // Extract a user-friendly error message
            if let apiError = error as? APIError {
                switch apiError {
                case .decodingError:
                    errorMessage = "Erro ao processar a resposta do servidor. Tente novamente mais tarde."
                case .clientError(let code, _):
                    errorMessage = "Erro de cliente (\(code)). Verifique sua conexão e tente novamente."
                case .serverError(let code, _):
                    errorMessage = "Erro no servidor (\(code)). Tente novamente mais tarde."
                case .networkError:
                    errorMessage = "Erro de conexão. Verifique sua internet e tente novamente."
                case .unauthorized, .authenticationFailed:
                    errorMessage = "Erro de autenticação. Tente fazer login novamente."
                default:
                    errorMessage = "Erro desconhecido. Tente novamente mais tarde."
                }
            } else {
                errorMessage = "Erro ao carregar tarefas: \(error.localizedDescription)"
            }
            
            print("Error loading tasks: \(error)")
        }
        
        isLoading = false
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(showingSidebar: .constant(false))
            .environmentObject(TaskViewModel())
            .environmentObject(FocusSessionViewModel())
            .environmentObject(ProjectViewModel())
    }
} 