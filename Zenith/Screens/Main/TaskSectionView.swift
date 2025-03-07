import SwiftUI
import _Concurrency

struct TaskSectionView: View {
    let title: String
    let tasks: [TodoTask]
    let secondaryTextColor: Color
    let cardBackgroundColor: Color
    let onTaskCreated: @Sendable () async -> Void
    @StateObject var viewModel: TaskViewModel
    @Binding var showingCreateTask: Bool
    var selectedFilterName: String? = nil
    
    var body: some View {
        if tasks.isEmpty {
            // Empty state - take up full space and center content
            VStack(spacing: 16) {
                Spacer()
                
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 60))
                    .foregroundColor(secondaryTextColor)
                
                Text("Nenhuma tarefa")
                    .font(.headline)
                    .foregroundColor(secondaryTextColor)
                    
                Text("Você está em dia com suas tarefas")
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Button {
                    showingCreateTask = true
                } label: {
                    Text("Adicionar tarefa")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.top, 16)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Regular content with tasks
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(tasks.count == 1 ? "1 tarefa" : "\(tasks.count) tarefas")
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                
                TaskListView(
                    showingCreateTask: $showingCreateTask,
                    tasks: tasks,
                    secondaryTextColor: secondaryTextColor,
                    cardBackgroundColor: cardBackgroundColor,
                    onTaskCreated: { @Sendable in
                        await onTaskCreated()
                    },
                    viewModel: viewModel,
                    isOverdueSection: selectedFilterName == "Atrasadas"
                )
            }
        }
    }
} 