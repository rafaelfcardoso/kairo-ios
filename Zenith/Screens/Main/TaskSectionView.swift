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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .bold()
                .padding(.horizontal)
                .padding(.top)
            
            if tasks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(secondaryTextColor)
                    
                    Text("Nenhuma tarefa")
                        .font(.headline)
                        .foregroundColor(secondaryTextColor)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 40)
            } else {
                TaskListView(
                    showingCreateTask: $showingCreateTask,
                    tasks: tasks,
                    secondaryTextColor: secondaryTextColor,
                    cardBackgroundColor: cardBackgroundColor,
                    onTaskCreated: { @Sendable in
                        await onTaskCreated()
                    },
                    viewModel: viewModel
                )
            }
        }
    }
} 