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
    let errorMessage: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(secondaryTextColor)
            
            Text("Não foi possível carregar as tarefas")
                .font(.headline)
                .foregroundColor(textColor)
            
            Text(errorMessage)
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onRetry) {
                Text("Tentar novamente")
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
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
    @Binding var selectedProject: Project?
    
    // Use app-level binding for selected project
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
                VStack(spacing: 0) {
                    UnifiedToolbar(
                        title: viewModel.greeting,
                        subtitle: viewModel.formattedDate,
                        onSidebarTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showingSidebar = true
                                HapticManager.shared.impact(style: .medium)
                            }
                        },
                        trailing: AnyView(
                            Button(action: { showingCreateTask = true }) {
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .foregroundColor(textColor)
                            }
                            .accessibilityLabel("Add task")
                            .accessibilityIdentifier("add-task-button")
                        ),
                        textColor: colorScheme == .dark ? .white : .black,
                        backgroundColor: colorScheme == .dark ? .black : .white
                    )
                    // Main content follows below
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 100)
                    } else if hasError && !viewModel.isOfflineMode {
                        ErrorView(
                            secondaryTextColor: secondaryTextColor,
                            textColor: textColor,
                            errorMessage: errorMessage ?? "Erro desconhecido. Tente novamente mais tarde.",
                            onRetry: { Task { await performTaskLoad() } }
                        )
                    } else {
                            TaskContentView(
                                selectedProject: $selectedProject,
                                selectedTab: $selectedTab,
                                viewModel: viewModel,
                                showingCreateTask: $showingCreateTask,
                                secondaryTextColor: secondaryTextColor,
                                cardBackgroundColor: cardBackgroundColor,
                                displayedTasks: displayedTasks,
                                onLoadTasks: { @Sendable in await self.performTaskLoad() }
                            )
                    }
                }
                .task { await performTaskLoad() }
        
                .sheet(isPresented: $showingCreateTask) {
                    CreateTaskFormView(
                        viewModel: viewModel,
                        onTaskSaved: { @Sendable in Task { await self.performTaskLoad() } }
                    )
                    .presentationDetents([.medium, .large])
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
                .onAppear {
                    viewModel.refreshAfterLogin()
                }
            }
            .background(Color.purple.opacity(0.3))
            
        }
    }
    
    


// MARK: - Toolbar Components
private extension MainView {
    var sidebarButton: some View {
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

    var titleView: some View {
        VStack(spacing: 2) {
            Text(viewModel.greeting)
                .font(.headline)
                .foregroundColor(textColor)
                .accessibilityIdentifier("TodayGreeting")
            Text(viewModel.formattedDate)
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
        }
    }

    var addButton: some View {
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
    func loadTasks() async throws {
        if selectedProject != nil {
            try await viewModel.loadAllTasks()
        } else {
            try await viewModel.loadAllTasks()
        }
    }

    @Sendable
    func performTaskLoad() async {
        isLoading = true
        errorMessage = nil
        do {
            if selectedProject != nil {
                try await viewModel.loadTasks()
            } else {
                try await viewModel.loadTasks()
            }
            hasError = false
        } catch {
            hasError = true
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
        MainView(showingSidebar: .constant(false), selectedProject: .constant(nil))
            .environmentObject(TaskViewModel())
            .environmentObject(FocusSessionViewModel())
            .environmentObject(ProjectViewModel())
    }
}
