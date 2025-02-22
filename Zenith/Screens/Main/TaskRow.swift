import SwiftUI

// Add models and dependencies
struct TaskRow: View {
    let task: TodoTask
    let viewModel: TaskViewModel
    let isOverdue: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var isCompleting = false
    @State private var showingEditTask = false
    @State private var showingUndoToast = false
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : .white
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var timeColor: Color {
        isOverdue ? .red : .green
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
    
    private var formattedTime: String? {
        guard task.hasTime,
              let dueDateString = task.dueDate else {
            return nil
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(identifier: "UTC")!
        
        guard let utcDate = formatter.date(from: dueDateString) else {
            return nil
        }
        
        let localDate = utcDate.addingTimeInterval(Double(TimeZone.current.secondsFromGMT()))
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .none
        timeFormatter.timeZone = TimeZone.current
        timeFormatter.locale = Locale.current
        
        return timeFormatter.string(from: localDate)
    }
    
    private var formattedDate: String? {
        guard let dueDateString = task.dueDate else {
            return nil
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(identifier: "UTC")!
        
        guard let utcDate = formatter.date(from: dueDateString) else {
            return nil
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale(identifier: "pt_BR")
        dateFormatter.dateFormat = "d MMM"
        
        let fullDate = dateFormatter.string(from: utcDate)
        return fullDate.replacingOccurrences(of: " de ", with: " ")
            .replacingOccurrences(of: ". ", with: " ")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: " ([a-zA-Z])", with: " $1".uppercased(), options: .regularExpression)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isCompleting = true
                }
            }) {
                ZStack {
                    Circle()
                        .strokeBorder(circleColor, lineWidth: 1.5)
                        .frame(width: 24, height: 20)
                    
                    if isCompleting {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(circleColor)
                            .font(.system(size: 20))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .task(id: isCompleting) {
                if isCompleting {
                    do {
                        try await Task.sleep(nanoseconds: 200_000_000)
                        try await viewModel.completeTask(task)
                    } catch {
                        print("Error completing task: \(error)")
                        withAnimation {
                            isCompleting = false
                        }
                    }
                }
            }
            .onChange(of: task.id) { _ in
                // Reset completing state when task changes (e.g., after undo)
                withAnimation {
                    isCompleting = false
                }
            }
            .padding(.top, 4)
            .disabled(isCompleting)
            
            VStack(alignment: .leading, spacing: task.description == nil ? 0 : 4) {
                Text(task.title)
                    .foregroundColor(textColor)
                    .opacity(isCompleting ? 0.5 : 1)
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .foregroundColor(secondaryTextColor)
                        .font(.subheadline)
                        .opacity(isCompleting ? 0.5 : 1)
                }
                
                HStack(spacing: 8) {
                    if isOverdue, let date = formattedDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                            Text(date)
                                .font(.caption)
                            if let time = formattedTime {
                                Text(time)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                        .foregroundColor(timeColor)
                    } else if let time = formattedTime {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                            Text(time)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                        .foregroundColor(timeColor)
                    }
                    
                    if task.project == nil {
                        HStack(spacing: 4) {
                            Image(systemName: "tray")
                                .font(.system(size: 12))
                            Text("Entrada")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundColor(secondaryTextColor)
                    } else if let project = task.project {
                        Text(project.name)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: project.color).opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                .opacity(isCompleting ? 0.5 : 1)
            }
            
            Spacer()
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditTask = true
        }
        .sheet(isPresented: $showingEditTask) {
            TaskFormView(
                task: task,
                viewModel: viewModel,
                onTaskSaved: { @MainActor in
                    try? await viewModel.loadAllTasks()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .interactiveDismissDisabled(false)
        }
    }
} 