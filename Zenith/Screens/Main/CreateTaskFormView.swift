import SwiftUI

struct CreateTaskFormView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var projectViewModel = ProjectViewModel()
    @StateObject private var viewModel: TaskViewModel
    @State private var taskTitle: String = ""
    @State private var taskDescription: String = ""
    @State private var selectedPriority: Priority?
    @State private var selectedDate: Date?
    @State private var selectedTime: Date?
    @State private var selectedProject: Project?
    @State private var isLoading = false
    @State private var isLoadingProjects = true
    @State private var showingDatePicker = false
    @State private var error: Error?
    
    private let inboxProjectId = "569c363f-1934-4e69-b324-6c2fad28bc59"
    var onTaskSaved: @Sendable () async -> Void
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1F1F1F") : Color(hex: "F1F2F4")
    }
    
    var secondaryBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : .white
    }
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : .white
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : Color(hex: "7E7E7E")
    }
    
    var circleColor: Color {
        selectedPriority?.color ?? secondaryTextColor
    }
    
    var dateButtonColor: Color {
        if let selectedDate = selectedDate {
            return selectedDate < Calendar.current.startOfDay(for: Date()) ? .red : .green
        }
        return .green
    }
    
    enum Priority: String, CaseIterable {
        case p1 = "high"
        case p2 = "medium"
        case p3 = "low"
        case p4 = "none"
        
        var displayName: String {
            switch self {
                case .p1: return "Alta"
                case .p2: return "Média"
                case .p3: return "Baixa"
                case .p4: return "Sem prioridade"
            }
        }
        
        var shortName: String {
            switch self {
                case .p1: return "Alta"
                case .p2: return "Média"
                case .p3: return "Baixa"
                case .p4: return "Prioridade"
            }
        }
        
        var color: Color {
            switch self {
                case .p1: return Color(hex: "FF6B6B")
                case .p2: return Color(hex: "FFA94D")
                case .p3: return Color(hex: "4D96FF")
                case .p4: return Color(hex: "868E96")
            }
        }
    }
    
    init(viewModel: TaskViewModel, onTaskSaved: @escaping @Sendable () async -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onTaskSaved = onTaskSaved
    }
    
    private var formattedDate: String {
        guard let date = selectedDate else { return "Data" }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Hoje"
        } else if calendar.isDateInTomorrow(date) {
            return "Amanhã"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "pt_BR")
        dateFormatter.dateFormat = "d MMM"
        let fullDate = dateFormatter.string(from: date)
        return fullDate.replacingOccurrences(of: " de ", with: " ")
            .replacingOccurrences(of: ". ", with: " ")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: " ([a-zA-Z])", with: " $1".uppercased(), options: .regularExpression)
    }
    
    private func saveTask() async {
        guard !taskTitle.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        print("🕒 [Timezone] Starting saveTask")
        
        var taskData: [String: Any] = [
            "title": taskTitle,
            "description": taskDescription,
            "priority": selectedPriority?.rawValue ?? "none",
            "projectId": selectedProject?.id ?? inboxProjectId,
            "isRecurring": false,
            "needsReminder": false
        ]
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)!
        
        if let selectedDate = selectedDate {
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            
            let dueDate: Date
            if let selectedTime = selectedTime {
                let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
                dueDate = calendar.date(
                    bySettingHour: timeComponents.hour ?? 0,
                    minute: timeComponents.minute ?? 0,
                    second: 0,
                    of: selectedDate
                ) ?? selectedDate
                taskData["hasTime"] = true
            } else {
                dueDate = calendar.startOfDay(for: selectedDate)
                taskData["hasTime"] = false
            }
            
            let utcDate = dueDate.addingTimeInterval(Double(-TimeZone.current.secondsFromGMT()))
            taskData["dueDate"] = dateFormatter.string(from: utcDate)
        }
        
        do {
            let url = URL(string: "\(APIConfig.baseURL)\(APIConfig.apiPath)/tasks")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "accept")
            APIConfig.addAuthHeaders(to: &request)
            
            let jsonData = try JSONSerialization.data(withJSONObject: taskData)
            request.httpBody = jsonData
            
            // For debugging - check if body is valid JSON without assigning to unused variable
            _ = String(data: jsonData, encoding: .utf8) != nil
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            // Removed excessive logging
            
            // Check if response is valid string without assigning to unused variable
            _ = String(data: data, encoding: .utf8) != nil
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            await onTaskSaved()
            dismiss()
        } catch {
            print("Network error: \(error)")
            self.error = error
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Task Title
                    HStack(spacing: 16) {
                        Circle()
                            .strokeBorder(circleColor, lineWidth: 1.5)
                            .frame(width: 24, height: 20)
                        
                        TextField("Nova tarefa", text: $taskTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(textColor)
                    }
                    .padding()
                    .background(backgroundColor)
                    
                    // Description
                    HStack(spacing: 16) {
                        Image(systemName: "text.justify")
                            .foregroundColor(secondaryTextColor)
                            .frame(width: 24)
                            .font(.system(size: 16))
                        
                        TextField("Descrição", text: $taskDescription)
                            .textFieldStyle(.plain)
                            .font(.system(size: 17))
                            .foregroundColor(textColor)
                    }
                    .padding()
                    .background(backgroundColor)
                    
                    // Parameter Buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Project Selector
                            Menu {
                                if let inbox = projectViewModel.projects.first(where: { $0.isSystem }) {
                                    Button {
                                        selectedProject = inbox
                                    } label: {
                                        HStack {
                                            Image(systemName: "tray")
                                                .frame(width: 24, alignment: .leading)
                                            Text("Entrada")
                                            Spacer()
                                            if selectedProject?.id == inbox.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                    }
                                    .accessibilityIdentifier("inbox-option")
                                    
                                    Divider()
                                }
                                
                                ForEach(projectViewModel.projects.filter { !$0.isArchived && !$0.isSystem }, id: \.id) { project in
                                    Button {
                                        selectedProject = project
                                    } label: {
                                        HStack {
                                            Image(systemName: "folder.fill")
                                                .foregroundColor(Color(hex: project.color))
                                                .frame(width: 24, alignment: .leading)
                                            Text(project.name)
                                            Spacer()
                                            if selectedProject?.id == project.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                    }
                                    .accessibilityIdentifier("project-option-\(project.id)")
                                }
                            } label: {
                                let isInbox = selectedProject?.isSystem ?? true
                                parameterButton(
                                    icon: isInbox ? "tray" : "folder",
                                    title: isInbox ? "Entrada" : (selectedProject?.name ?? "Entrada"),
                                    color: isInbox ? nil : (selectedProject.map { Color(hex: $0.color) })
                                )
                            }
                            .accessibilityIdentifier("project-selector")
                            
                            // Due Date
                            Button(action: {
                                showingDatePicker = true
                            }) {
                                parameterButton(
                                    icon: "calendar",
                                    title: formattedDate,
                                    color: dateButtonColor
                                )
                            }
                            .sheet(isPresented: $showingDatePicker) {
                                DateSelectionView(
                                    selectedDate: $selectedDate,
                                    selectedTime: $selectedTime,
                                    onDismiss: {}
                                )
                            }
                            
                            // Priority
                            Menu {
                                ForEach(Priority.allCases, id: \.self) { priority in
                                    Button {
                                        selectedPriority = priority
                                    } label: {
                                        Text(priority.displayName)
                                            .foregroundColor(textColor)
                                    }
                                }
                            } label: {
                                parameterButton(
                                    icon: "flag.fill",
                                    title: selectedPriority?.shortName ?? "Prioridade",
                                    color: selectedPriority?.color
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(backgroundColor)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(textColor)
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Concluir") {
                        Task {
                            await saveTask()
                        }
                    }
                    .bold()
                    .foregroundColor(textColor)
                    .disabled(taskTitle.isEmpty || isLoading)
                }
            }
            .task {
                do {
                    try await projectViewModel.loadProjects()
                    if selectedProject == nil {
                        selectedProject = projectViewModel.projects.first(where: { $0.isSystem })
                    }
                    isLoadingProjects = false
                } catch {
                    print("Error loading projects: \(error)")
                    isLoadingProjects = false
                }
            }
            
            if isLoading {
                ProgressView()
            }
        }
        .background(backgroundColor)
    }
    
    @ViewBuilder
    private func parameterButton(icon: String, title: String, color: Color? = nil) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color ?? secondaryTextColor)
            Text(title)
                .foregroundColor(color ?? secondaryTextColor)
        }
        .font(.system(size: 14))
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(cardBackgroundColor)
        .cornerRadius(8)
    }
}

struct CreateTaskFormView_Previews: PreviewProvider {
    static var previews: some View {
        CreateTaskFormView(viewModel: TaskViewModel()) {
            // Preview only
        }
    }
} 