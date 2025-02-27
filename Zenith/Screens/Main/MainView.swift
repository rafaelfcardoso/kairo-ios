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

// Add this enum after the ErrorView struct
enum TaskFilter: String, CaseIterable {
    case today = "Hoje"
    case upcoming = "Próximas"
    case inbox = "Entrada"
    case completed = "Concluídas"
    case focus = "Foco"
}

struct MainView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @State private var showingCreateTask = false
    @State private var isLoading = true
    @State private var hasError = false
    @State private var selectedTab = 0
    @Binding var showingSidebar: Bool
    @State private var navigationPath = NavigationPath()
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var focusSessionViewModel: FocusSessionViewModel
    @State private var selectedTaskFilter: TaskFilter = .today
    
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
            // Return tasks based on selected filter
            switch selectedTaskFilter {
            case .today:
                return viewModel.todayTasks
            case .upcoming:
                return viewModel.upcomingTasks
            case .inbox:
                return viewModel.inboxTasks
            case .completed:
                return viewModel.completedTasks
            case .focus:
                return viewModel.focusTasks
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
                
                VStack(spacing: 0) {
                    if isLoading {
                        ProgressView()
                    } else if hasError {
                        ErrorView(
                            secondaryTextColor: secondaryTextColor,
                            textColor: textColor,
                            retryAction: {
                                performTaskLoad()
                            }
                        )
                    } else {
                        // Extract to a separate view component
                        TaskContentView(
                            selectedProject: $selectedProject,
                            selectedTab: $selectedTab,
                            viewModel: viewModel,
                            showingCreateTask: $showingCreateTask,
                            secondaryTextColor: secondaryTextColor,
                            cardBackgroundColor: cardBackgroundColor,
                            displayedTasks: displayedTasks,
                            onLoadTasks: { @Sendable in
                                self.performTaskLoad()
                            }
                        )
                    }
                }
                
                // Focus button - positioned above tab bar and main content
                if !focusSessionViewModel.isActive {
                    FocusButtonView(viewModel: focusSessionViewModel, colorScheme: colorScheme, backgroundColor: backgroundColor)
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
                    .zIndex(30)
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
                performTaskLoad()
            }
            .sheet(isPresented: $showingCreateTask) {
                CreateTaskFormView(
                    viewModel: viewModel,
                    onTaskSaved: { @Sendable in
                        self.performTaskLoad()
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .interactiveDismissDisabled(false)
            }
            .onChange(of: selectedProject) { _, _ in
                performTaskLoad()
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
    }
    
    private var titleView: some View {
        VStack(spacing: 2) {
            if let selectedProject = selectedProject {
                Text(selectedProject.name)
                    .font(.headline)
                    .foregroundColor(textColor)
            } else {
                Text(selectedTaskFilter.rawValue.capitalized)
                    .font(.headline)
                    .foregroundColor(textColor)
            }
            
            if let selectedProject = selectedProject {
                Text("\(viewModel.getTasksForProject(projectId: selectedProject.id).count) tasks")
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
            } else {
                Text("\(displayedTasks.count) tasks")
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
            }
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
    private func performTaskLoad() {
        Task { @MainActor in
            isLoading = true
            
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
                print("Error loading tasks: \(error)")
            }
            
            isLoading = false
        }
    }
}

// MARK: - Focus Button View
struct FocusButtonView: View {
    @ObservedObject var viewModel: FocusSessionViewModel
    let colorScheme: ColorScheme
    let backgroundColor: Color
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Add background only to the button container, not the whole VStack
            HStack {
                Button {
                    viewModel.isExpanded = true
                } label: {
                    HStack {
                        Image(systemName: "timer")
                            .font(.headline)
                        Text("Iniciar Foco")
                            .font(.headline)
                    }
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(colorScheme == .dark ? Color(hex: "F1F2F4") : .black)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                // Opaque background
                Rectangle()
                    .fill(colorScheme == .dark ? Color(white: 0.1) : backgroundColor)
            )
        }
        .padding(.bottom, 50) // Additional padding to appear above tab bar
        .zIndex(25) // Above tab bar but below sidebar and toasts
    }
}

// Add this new view component after MainView
struct TaskContentView: View {
    @Binding var selectedProject: Project?
    @Binding var selectedTab: Int
    @ObservedObject var viewModel: TaskViewModel
    @Binding var showingCreateTask: Bool
    let secondaryTextColor: Color
    let cardBackgroundColor: Color
    let displayedTasks: [TodoTask]
    let onLoadTasks: @Sendable () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if selectedProject == nil && !viewModel.overdueTasks.isEmpty {
                TabView(selection: $selectedTab) {
                    // Overdue Section
                    TaskSectionView(
                        title: "Atrasadas",
                        tasks: viewModel.overdueTasks,
                        secondaryTextColor: secondaryTextColor,
                        cardBackgroundColor: cardBackgroundColor,
                        onTaskCreated: { @Sendable in
                            await handleTaskCreation()
                        },
                        viewModel: viewModel,
                        showingCreateTask: $showingCreateTask
                    )
                    .tag(0)
                    .refreshable {
                        await handleRefresh()
                    }
                    
                    // Today Section
                    TaskSectionView(
                        title: "Hoje",
                        tasks: viewModel.tasks,
                        secondaryTextColor: secondaryTextColor,
                        cardBackgroundColor: cardBackgroundColor,
                        onTaskCreated: { @Sendable in
                            await handleTaskCreation()
                        },
                        viewModel: viewModel,
                        showingCreateTask: $showingCreateTask
                    )
                    .tag(1)
                    .refreshable {
                        await handleRefresh()
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            } else {
                TaskSectionView(
                    title: selectedProject?.name ?? "Hoje",
                    tasks: displayedTasks,
                    secondaryTextColor: secondaryTextColor,
                    cardBackgroundColor: cardBackgroundColor,
                    onTaskCreated: { @Sendable in
                        await handleTaskCreation()
                    },
                    viewModel: viewModel,
                    showingCreateTask: $showingCreateTask
                )
                .refreshable {
                    await handleRefresh()
                }
            }
        }
    }
    
    // Helper functions to reduce repetitive code
    @Sendable
    private func handleTaskCreation() async {
        onLoadTasks()
    }
    
    @Sendable
    private func handleRefresh() async {
        onLoadTasks()
        // Adding a small delay to make the refresh indicator visible
        try? await Task.sleep(nanoseconds: 500_000_000)
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