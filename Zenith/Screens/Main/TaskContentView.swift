import SwiftUI

struct TaskContentView: View {
    @Binding var selectedProject: Project?
    @Binding var selectedTab: Int
    @ObservedObject var viewModel: TaskViewModel
    @Binding var showingCreateTask: Bool
    let secondaryTextColor: Color
    let cardBackgroundColor: Color
    let displayedTasks: [TodoTask]
    let onLoadTasks: @Sendable () async -> Void
    
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
                        showingCreateTask: $showingCreateTask,
                        selectedFilterName: "Atrasadas"
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
                        showingCreateTask: $showingCreateTask,
                        selectedFilterName: "Hoje"
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
                    title: selectedProject?.name ?? getFilterTitle(),
                    tasks: displayedTasks,
                    secondaryTextColor: secondaryTextColor,
                    cardBackgroundColor: cardBackgroundColor,
                    onTaskCreated: { @Sendable in
                        await handleTaskCreation()
                    },
                    viewModel: viewModel,
                    showingCreateTask: $showingCreateTask,
                    selectedFilterName: getFilterTitle()
                )
                .refreshable {
                    await handleRefresh()
                }
            }
        }
    }
    
    // Helper function to get the title based on the current filter
    private func getFilterTitle() -> String {
        if let project = selectedProject {
            return project.name
        } else {
            // Instead of comparing arrays directly, check if the displayedTasks are from a specific filter
            // by comparing them with the viewModel's filtered tasks
            if displayedTasks.isEmpty {
                return "Tarefas"
            }
            
            // Check if the first few tasks match those in a specific filter
            // This is a heuristic approach that avoids direct array comparison
            let sampleSize = min(3, displayedTasks.count)
            let sampleTasks = Array(displayedTasks.prefix(sampleSize))
            
            // Check today tasks
            let todaySample = Array(viewModel.todayTasks.prefix(sampleSize))
            if sampleTasks.count == todaySample.count && !todaySample.isEmpty {
                if sampleTasks.allSatisfy({ task in todaySample.contains(where: { $0.id == task.id }) }) {
                    return "Hoje"
                }
            }
            
            // Check upcoming tasks
            let upcomingSample = Array(viewModel.upcomingTasks.prefix(sampleSize))
            if sampleTasks.count == upcomingSample.count && !upcomingSample.isEmpty {
                if sampleTasks.allSatisfy({ task in upcomingSample.contains(where: { $0.id == task.id }) }) {
                    return "Próximas"
                }
            }
            
            // Check inbox tasks
            let inboxSample = Array(viewModel.inboxTasks.prefix(sampleSize))
            if sampleTasks.count == inboxSample.count && !inboxSample.isEmpty {
                if sampleTasks.allSatisfy({ task in inboxSample.contains(where: { $0.id == task.id }) }) {
                    return "Entrada"
                }
            }
            
            // Check completed tasks
            let completedSample = Array(viewModel.completedTasks.prefix(sampleSize))
            if sampleTasks.count == completedSample.count && !completedSample.isEmpty {
                if sampleTasks.allSatisfy({ task in completedSample.contains(where: { $0.id == task.id }) }) {
                    return "Concluídas"
                }
            }
            
            // Check focus tasks
            let focusSample = Array(viewModel.focusTasks.prefix(sampleSize))
            if sampleTasks.count == focusSample.count && !focusSample.isEmpty {
                if sampleTasks.allSatisfy({ task in focusSample.contains(where: { $0.id == task.id }) }) {
                    return "Foco"
                }
            }
            
            // Default fallback
            return "Tarefas"
        }
    }
    
    // Helper functions to reduce repetitive code
    @Sendable
    private func handleTaskCreation() async {
        await onLoadTasks()
    }
    
    @Sendable
    private func handleRefresh() async {
        await onLoadTasks()
        // Adding a small delay to make the refresh indicator visible
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
} 