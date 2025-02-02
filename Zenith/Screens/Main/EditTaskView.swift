import SwiftUI

struct EditTaskView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: TaskViewModel
    @State private var task: TodoTask
    @State private var showingProjectPicker = false
    @State private var isLoading = false
    @State private var error: Error?
    
    init(task: TodoTask, viewModel: TaskViewModel) {
        _task = State(initialValue: task)
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var backgroundColor: Color {
        Color(hex: "1F1F1F")
    }
    
    var textColor: Color {
        .white
    }
    
    var secondaryTextColor: Color {
        .gray
    }
    
    var cardBackgroundColor: Color {
        Color(hex: "1F1F1F")
    }
    
    var circleColor: Color {
        switch task.priority.lowercased() {
        case "high":
            return Color(hex: "FF6B6B")
        case "medium":
            return Color(hex: "FFA94D")
        case "low":
            return Color(hex: "4D96FF")
        default:
            return secondaryTextColor
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Task Title
                    taskField(
                        icon: nil,
                        circleColor: circleColor,
                        title: task.title,
                        subtitle: "Título"
                    )
                    
                    Divider()
                        .background(Color(white: 0.2))
                    
                    // Parameter Buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Description
                            if task.description == nil {
                                parameterButton(
                                    icon: "text.justify",
                                    title: "Descrição"
                                ) {
                                    // TODO: Handle description tap
                                }
                            }
                            
                            // Due Date
                            if task.dueDate == nil {
                                parameterButton(
                                    icon: "calendar",
                                    title: "Vencimento"
                                ) {
                                    // TODO: Handle due date tap
                                }
                            }
                            
                            // Project
                            if task.project == nil {
                                parameterButton(
                                    icon: "folder",
                                    title: "Projeto"
                                ) {
                                    showingProjectPicker = true
                                }
                            }
                            
                            // Priority - only show if it's "none" or not set
                            if task.priority.lowercased() == "none" {
                                parameterButton(
                                    icon: "flag",
                                    title: "Prioridade"
                                ) {
                                    // TODO: Handle priority tap
                                }
                            }
                            
                            // Tags - only show if empty
                            if task.tags.isEmpty {
                                parameterButton(
                                    icon: "tag",
                                    title: "Tags"
                                ) {
                                    // TODO: Handle tags tap
                                }
                            }
                            
                            // Estimate - only show if 0 or not set
                            if task.estimatedMinutes == 0 {
                                parameterButton(
                                    icon: "clock",
                                    title: "Estimativa"
                                ) {
                                    // TODO: Handle estimate tap
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Show more actions menu
                    }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                    }
                    .disabled(isLoading)
                }
            }
        }
    }
    
    @ViewBuilder
    private func taskField(icon: String? = nil, circleColor: Color? = nil, title: String, subtitle: String, isPlaceholder: Bool = false) -> some View {
        HStack(spacing: 16) {
            if let circleColor = circleColor {
                Circle()
                    .strokeBorder(circleColor, lineWidth: 1.5)
                    .frame(width: 24, height: 20)
            } else if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(secondaryTextColor)
                    .frame(width: 24)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(isPlaceholder ? secondaryTextColor : textColor)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(secondaryTextColor)
                .font(.system(size: 14))
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            // TODO: Handle field tap
        }
    }
    
    @ViewBuilder
    private func parameterButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 14))
            }
            .foregroundColor(secondaryTextColor)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(Color(white: 0.15))
            .cornerRadius(8)
        }
    }
}

struct EditTaskView_Previews: PreviewProvider {
    static var previews: some View {
        EditTaskView(
            task: TodoTask(
                id: "1",
                title: "Estudar Algoritmos",
                description: nil,
                status: "pending",
                priority: "high",
                dueDate: nil,
                estimatedMinutes: 0,
                isArchived: false,
                createdAt: "",
                updatedAt: "",
                project: nil,
                tags: [],
                focusSessions: []
            ),
            viewModel: TaskViewModel()
        )
    }
} 