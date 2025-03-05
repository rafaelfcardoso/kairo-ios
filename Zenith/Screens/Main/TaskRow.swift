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
        
        // NOTE: We're using the DateFormatter's timeZone property to convert from UTC to local time.
        // Do NOT manually adjust the date with addingTimeInterval as this would cause a double timezone adjustment.
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .none
        timeFormatter.timeZone = TimeZone.current  // This handles the UTC to local time conversion
        timeFormatter.locale = Locale.current
        
        return timeFormatter.string(from: utcDate)
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
        dateFormatter.timeZone = TimeZone.current  // This handles the UTC to local time conversion
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
                        await MainActor.run {
                            withAnimation {
                                isCompleting = false
                            }
                        }
                    }
                }
            }
            .onAppear {
                // Ensure the completing state is reset when the view appears
                isCompleting = false
            }
            .onChange(of: task.id, initial: true) { oldId, newId in
                // Reset completing state when task changes or when view initializes
                if oldId != newId {
                    withAnimation {
                        isCompleting = false
                    }
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
                    // First row of metadata with flexible wrapping
                    VStack(alignment: .leading, spacing: 4) {
                        // First display deadline/time
                        if isOverdue, let date = formattedDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12))
                                Text("\(date) \(formattedTime ?? "")")
                                    .font(.caption)
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
                        
                        // Second row with wrapping HStack for remaining metadata
                        HStack(spacing: 8) {
                            // Display recurrence icon if task is recurring
                            if let isRecurring = task.isRecurring, isRecurring {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 12))
                                        .foregroundColor(secondaryTextColor)
                                }
                                .padding(.vertical, 4)
                            }
                            
                            // Display reminder icon if task needs reminder
                            if let needsReminder = task.needsReminder, needsReminder {
                                HStack(spacing: 4) {
                                    Image(systemName: "alarm")
                                        .font(.system(size: 12))
                                        .foregroundColor(secondaryTextColor)
                                }
                                .padding(.vertical, 4)
                            }
                            
                            // Display tags if any
                            if !task.tags.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "tag")
                                        .font(.system(size: 12))
                                        .foregroundColor(secondaryTextColor)
                                }
                                .padding(.vertical, 4)
                            }
                            
                            // Display project last
                            if task.project == nil {
                                HStack(spacing: 4) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 12))
                                        .foregroundColor(secondaryTextColor)
                                    Text("Entrada")
                                        .font(.caption)
                                        .foregroundColor(textColor)
                                }
                                .padding(.vertical, 4)
                            } else if let project = task.project {
                                HStack(spacing: 4) {
                                    // Use tray icon for Inbox project, folder.fill for others
                                    Image(systemName: project.isSystem ? "tray" : "folder.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(project.isSystem ? secondaryTextColor : Color(hex: project.color))
                                    Text(project.name)
                                        .font(.caption)
                                        .foregroundColor(textColor)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding(.top, 4)
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