import SwiftUI

struct TaskSectionView: View {
    let title: String
    let tasks: [TodoTask]
    let secondaryTextColor: Color
    let cardBackgroundColor: Color
    let onTaskCreated: @Sendable () async -> Void
    let viewModel: TaskViewModel
    @Binding var showingCreateTask: Bool
    @State private var shouldRefresh = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Section Title
            Text(title)
                .font(.headline)
                .foregroundColor(secondaryTextColor)
                .padding(.horizontal)
            
            // Tasks List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(tasks) { task in
                        TaskRow(
                            task: task,
                            viewModel: viewModel,
                            isOverdue: title == "Atrasadas"
                        )
                    }
                    
                    if title == "Hoje" {
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
                        .accessibilityIdentifier("add-task-button")
                        .sheet(isPresented: $showingCreateTask) {
                            TaskFormView(
                                viewModel: viewModel,
                                onTaskSaved: {
                                    await MainActor.run {
                                        shouldRefresh = true
                                    }
                                    await onTaskCreated()
                                    await MainActor.run {
                                        shouldRefresh = false
                                    }
                                }
                            )
                            .presentationDetents([.medium, .large])
                            .presentationDragIndicator(.visible)
                            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                            .interactiveDismissDisabled(false)
                        }
                    }
                }
                .padding(.horizontal)
            }
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