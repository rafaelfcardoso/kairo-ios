import SwiftUI
import Combine
import UIKit

class KeyboardObserver: ObservableObject {
    @Published var isVisible = false
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        isVisible = true
    }
    
    @objc func keyboardWillHide() {
        isVisible = false
    }
}

// Simple page indicator with dots
struct PageControl: View {
    let numberOfPages: Int
    @Binding var currentPage: Int
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? 
                          (colorScheme == .dark ? Color.white : Color.black) : 
                          Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: currentPage)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(UIColor.systemBackground).opacity(0.9))
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct TaskContentView: View {
    @Binding var selectedProject: Project?
    @Binding var selectedTab: Int
    @ObservedObject var viewModel: TaskViewModel
    @Binding var showingCreateTask: Bool
    let secondaryTextColor: Color
    let cardBackgroundColor: Color
    let displayedTasks: [TodoTask]
    let onLoadTasks: @Sendable () async -> Void
    @StateObject private var keyboardObserver = KeyboardObserver()
    
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
                .tabViewStyle(.page(indexDisplayMode: .never))
                .padding(.top, 12)
                .contentMargins(.horizontal, 16, for: .scrollContent)
                // Add this to create a fixed bottom indicator area
                .safeAreaInset(edge: .bottom) {
                    // This creates a fixed space at the bottom
                    VStack {
                        Spacer()
                            .frame(height: shouldShowPageIndicator ? 40 : 0)
                    }
                    .animation(.none, value: keyboardObserver.isVisible)
                }
                .overlay(alignment: .bottom) {
                    // The page indicator is ALWAYS here at exactly the same position,
                    // only its opacity changes
                    PageControl(numberOfPages: 2, currentPage: $selectedTab)
                        .padding(.bottom, 60)
                        .opacity(shouldShowPageIndicator ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: keyboardObserver.isVisible)
                }
                .ignoresSafeArea(.keyboard)
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
                .padding(.top, 12)
                .contentMargins(.horizontal, 16, for: .scrollContent)
            }
        }
    }
    
    // Computed property to check if we should show the page indicator
    private var shouldShowPageIndicator: Bool {
        return selectedProject == nil && !viewModel.overdueTasks.isEmpty && !keyboardObserver.isVisible
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