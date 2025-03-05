import SwiftUI

struct TimeSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTime: Date
    
    var body: some View {
        NavigationView {
            DatePicker(
                "Selecionar hora",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .navigationTitle("Hora")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Concluir") {
                        dismiss()
                    }
                    .bold()
                }
            }
        }
    }
}

struct DateSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Binding var selectedDate: Date?
    @Binding var selectedTime: Date?
    @State private var showingTimePicker = false
    @State private var tempTime: Date? = nil
    let onDismiss: () -> Void
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var formattedTime: String {
        guard let time = selectedTime else { return "Nenhum" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: time)
    }
    
    private func applyTimeToDate(_ date: Date) -> Date {
        guard let time = selectedTime else { return date }
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        print("Debug: Applying time components - Hour: \(timeComponents.hour ?? 0), Minute: \(timeComponents.minute ?? 0)")
        return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                           minute: timeComponents.minute ?? 0,
                           second: 0,
                           of: date) ?? date
    }
    
    private func handleDismiss() {
        if selectedDate == nil {
            // If "Hoje" was selected, set it to today's date
            selectedDate = Calendar.current.startOfDay(for: Date())
        } else if let date = selectedDate {
            // Always apply the time if it's set, even for initial task creation
            selectedDate = applyTimeToDate(date)
        }
        print("Debug: Final selected date with time: \(selectedDate?.description ?? "nil")")
        onDismiss()
        dismiss()
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Hoje")
                        Spacer()
                        if Calendar.current.isDateInToday(selectedDate ?? Date()) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDate = Calendar.current.startOfDay(for: Date())
                        selectedTime = nil
                    }
                    
                    HStack {
                        Text("Amanhã")
                        Spacer()
                        if let date = selectedDate,
                            Calendar.current.isDateInTomorrow(date) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                        selectedTime = nil
                    }
                }
                
                Section {
                    DatePicker(
                        "Selecionar data",
                        selection: Binding(
                            get: { selectedDate ?? Date() },
                            set: { newDate in
                                selectedDate = newDate
                                if selectedTime == nil {
                                    selectedTime = nil
                                }
                            }
                        ),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                }
                
                Section(header: Text("Horário (Opcional)")) {
                    HStack {
                        Text("Hora")
                        Spacer()
                        Text(formattedTime)
                            .foregroundColor(selectedTime == nil ? secondaryTextColor : .blue)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tempTime = selectedTime ?? Date()
                        showingTimePicker = true
                    }
                }
            }
            .navigationTitle("Prazo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        handleDismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Concluir") {
                        handleDismiss()
                    }
                    .bold()
                }
            }
            .sheet(isPresented: $showingTimePicker) {
                TimeSelectionView(selectedTime: Binding(
                    get: { tempTime ?? Date() },
                    set: { 
                        tempTime = $0
                        selectedTime = $0
                        print("Debug: Time selected: \($0.description)")
                    }
                ))
            }
        }
    }
}

struct TaskFormView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var projectViewModel = ProjectViewModel()
    @StateObject private var viewModel: TaskViewModel
    @State private var taskTitle: String
    @State private var taskDescription: String
    @State private var selectedPriority: Priority?
    @State private var selectedDate: Date?
    @State private var selectedTime: Date?
    @State private var selectedProject: Project?
    @State private var isLoading = false
    @State private var isLoadingProjects = true
    @State private var showingDatePicker = false
    @State private var error: Error?
    
    private let inboxProjectId = "569c363f-1934-4e69-b324-6c2fad28bc59"
    let existingTask: TodoTask?
    var onTaskSaved: @Sendable () async -> Void
    
    var isOverdue: Bool {
        guard let task = existingTask,
                let dueDateString = task.dueDate,
                let dueDate = ISO8601DateFormatter().date(from: dueDateString) else {
            return false
        }
        return dueDate < Date()
    }
    
    var dateColor: Color {
        isOverdue ? .red : .green
    }
    
    private func formattedDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "pt_BR")
        dateFormatter.dateFormat = "d MMM"
        let fullDate = dateFormatter.string(from: date)
        return fullDate.replacingOccurrences(of: " de ", with: " ")
            .replacingOccurrences(of: ". ", with: " ")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: " ([a-zA-Z])", with: " $1".uppercased(), options: .regularExpression)
    }
    
    var formattedSelectedDate: String {
        guard let date = selectedDate else { return "Data" }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Hoje"
        } else if calendar.isDateInTomorrow(date) {
            return "Amanhã"
        }
        return formattedDate(date)
    }
    
    var dateButtonColor: Color {
        if let selectedDate = selectedDate {
            // Check if the selected date is in the past
            return selectedDate < Calendar.current.startOfDay(for: Date()) ? .red : .green
        }
        return .green
    }
    
    init(task: TodoTask? = nil, viewModel: TaskViewModel, onTaskSaved: @escaping @Sendable () async -> Void) {
        self.existingTask = task
        self.onTaskSaved = onTaskSaved
        _viewModel = StateObject(wrappedValue: viewModel)
        
        print("🕒 [Timezone] Current timezone: \(TimeZone.current.identifier) (GMT\(TimeZone.current.secondsFromGMT()/3600 >= 0 ? "+" : "")\(TimeZone.current.secondsFromGMT()/3600))")
        
        // Initialize state with existing task data or defaults
        _taskTitle = State(initialValue: task?.title ?? "")
        _taskDescription = State(initialValue: task?.description ?? "")
        
        // Fix priority initialization
        let priority: Priority?
        if let taskPriority = task?.priority {
            priority = Priority(rawValue: taskPriority)
        } else {
            priority = nil
        }
        _selectedPriority = State(initialValue: priority)
        
        if let dueDateString = task?.dueDate {
            print("🕒 [Timezone] Received dueDate from API: \(dueDateString)")
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let utcDate = formatter.date(from: dueDateString) {
                print("🕒 [Timezone] Parsed UTC date: \(utcDate)")
                
                // Convert UTC to local time
                let localDate = utcDate.addingTimeInterval(Double(TimeZone.current.secondsFromGMT()))
                print("🕒 [Timezone] Converted to local date: \(localDate)")
                print("🕒 [Timezone] Time difference applied: \(TimeZone.current.secondsFromGMT()/3600) hours")
                
                _selectedDate = State(initialValue: localDate)
                // If task has time set, use the same local date for selectedTime
                _selectedTime = State(initialValue: task?.hasTime == true ? localDate : nil)
                
                if task?.hasTime == true {
                    let timeFormatter = DateFormatter()
                    timeFormatter.timeStyle = .short
                    timeFormatter.dateStyle = .none
                    print("🕒 [Timezone] Task has time set. Local time: \(timeFormatter.string(from: localDate))")
                }
            } else {
                print("🕒 [Timezone] Failed to parse date: \(dueDateString)")
                _selectedDate = State(initialValue: nil)
                _selectedTime = State(initialValue: nil)
            }
        } else {
            _selectedDate = State(initialValue: nil)
            _selectedTime = State(initialValue: nil)
        }
        
        _selectedProject = State(initialValue: task?.project)
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
    
    var highlightColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var inactiveColor: Color {
        colorScheme == .dark ? .gray : Color(hex: "7E7E7E")
    }
    
    var circleColor: Color {
        selectedPriority?.color ?? secondaryTextColor
    }
    
    private func applyTimeToDate(_ date: Date) -> Date {
        guard let time = selectedTime else { return date }
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        print("Debug: Applying time components - Hour: \(timeComponents.hour ?? 0), Minute: \(timeComponents.minute ?? 0)")
        return calendar.date(bySettingHour: timeComponents.hour ?? 0,
                           minute: timeComponents.minute ?? 0,
                           second: 0,
                           of: date) ?? date
    }
    
    private enum UpdateField {
        case title
        case description
        case priority
        case project
        case dueDate
        case all
    }

    private func saveTask(field: UpdateField = .all) async {
        guard !taskTitle.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        print("🕒 [Timezone] Starting saveTask for field: \(field)")
        
        // Prepare the task data based on which field is being updated
        var taskData: [String: Any] = [:]
        
        switch field {
        case .title:
            taskData["title"] = taskTitle
        case .description:
            taskData["description"] = taskDescription
        case .priority:
            taskData["priority"] = selectedPriority?.rawValue ?? "none"
        case .project:
            taskData["projectId"] = selectedProject?.id ?? inboxProjectId
        case .dueDate:
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)!
            
            var calendar = Calendar.current
            calendar.timeZone = TimeZone.current
            
            if let selectedDate = selectedDate {
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
            } else {
                taskData["dueDate"] = nil
                taskData["hasTime"] = false
            }
        case .all:
            // Only used for creating new tasks
            guard existingTask == nil else {
                print("Warning: Attempted to update all fields for existing task")
                return
            }
            
            taskData = [
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
        }
        
        do {
            let url: URL
            var request: URLRequest
            
            if let existingTask = existingTask {
                url = URL(string: "\(APIConfig.baseURL)\(APIConfig.apiPath)/tasks/\(existingTask.id)")!
                request = URLRequest(url: url)
                request.httpMethod = "PUT"
            } else {
                url = URL(string: "\(APIConfig.baseURL)\(APIConfig.apiPath)/tasks")!
                request = URLRequest(url: url)
                request.httpMethod = "POST"
            }
            
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "accept")
            APIConfig.addAuthHeaders(to: &request)
            
            let jsonData = try JSONSerialization.data(withJSONObject: taskData)
            request.httpBody = jsonData
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            // Immediately update the task lists after any change
            await MainActor.run {
                // First invalidate all caches
                viewModel.invalidateCache()
                
                Task {
                    do {
                        // Then force a fresh reload of all tasks
                        try await viewModel.loadAllTasks()
                        // Finally notify any listeners that a task was saved
                        await onTaskSaved()
                    } catch {
                        print("Error refreshing tasks: \(error)")
                    }
                }
            }
            
        } catch {
            print("Network error: \(error)")
            self.error = error
        }
    }
    
    private func handleDismiss() {
        dismiss()
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
                        
                        TextField(existingTask == nil ? "Nova tarefa" : "Título", text: $taskTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(textColor)
                            .submitLabel(.done)
                            .onSubmit {
                                if taskTitle.isEmpty { return }
                                Task {
                                    await saveTask(field: .title)
                                }
                            }
                    }
                    .padding()
                    .background(backgroundColor)
                    
                    // Description
                    if !taskDescription.isEmpty || existingTask == nil {
                        HStack(spacing: 16) {
                            Image(systemName: "text.justify")
                                .foregroundColor(secondaryTextColor)
                                .frame(width: 24)
                                .font(.system(size: 16))
                            
                            TextField("Descrição", text: $taskDescription)
                                .textFieldStyle(.plain)
                                .font(.system(size: 17))
                                .foregroundColor(textColor)
                                .submitLabel(.done)
                                .onSubmit {
                                    if taskTitle.isEmpty { return }
                                    Task {
                                        await saveTask(field: .description)
                                    }
                                }
                        }
                        .padding()
                        .background(backgroundColor)
                    }
                    
                    // Parameter Buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Project Selector
                            Menu {
                                if let inbox = projectViewModel.projects.first(where: { $0.isSystem }) {
                                    Button {
                                        selectedProject = inbox
                                        if existingTask != nil {
                                            Task {
                                                await saveTask(field: .project)
                                            }
                                        }
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
                                        if existingTask != nil {
                                            Task {
                                                await saveTask(field: .project)
                                            }
                                        }
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
                                let isInbox = selectedProject?.isSystem ?? true // Default to true for inbox
                                parameterButton(
                                    icon: isInbox ? "tray" : "folder",
                                    title: isInbox ? "Entrada" : (selectedProject?.name ?? "Entrada"),
                                    color: isInbox ? nil : (selectedProject.map { Color(hex: $0.color) })
                                )
                            }
                            .accessibilityIdentifier("project-selector")
                            .accessibilityLabel(selectedProject?.isSystem == true ? "Entrada" : (selectedProject?.name ?? "Entrada"))
                            
                            // Due Date
                            Button(action: {
                                showingDatePicker = true
                            }) {
                                parameterButton(
                                    icon: "calendar",
                                    title: formattedSelectedDate,
                                    color: dateButtonColor
                                )
                            }
                            .sheet(isPresented: $showingDatePicker) {
                                DateSelectionView(
                                    selectedDate: Binding(
                                        get: { selectedDate },
                                        set: { newDate in
                                            selectedDate = newDate
                                        }
                                    ),
                                    selectedTime: Binding(
                                        get: { selectedTime },
                                        set: { newTime in
                                            selectedTime = newTime
                                        }
                                    ),
                                    onDismiss: {
                                        if existingTask != nil {
                                            Task {
                                                await saveTask(field: .dueDate)
                                            }
                                        }
                                    }
                                )
                            }
                            
                            // Priority
                            Menu {
                                ForEach(Priority.allCases, id: \.self) { priority in
                                    Button {
                                        selectedPriority = priority
                                        if existingTask != nil {
                                            Task {
                                                await saveTask(field: .priority)
                                            }
                                        }
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
                        handleDismiss()
                    }
                    .foregroundColor(textColor)
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if existingTask == nil {
                        Button("Concluir") {
                            Task {
                                await saveTask(field: .all)
                                dismiss()
                            }
                        }
                        .bold()
                        .foregroundColor(textColor)
                        .disabled(taskTitle.isEmpty || isLoading)
                    } else {
                        Button(action: {
                            // TODO: Show more actions menu
                        }) {
                            Image(systemName: "ellipsis")
                                .foregroundColor(textColor)
                        }
                        .disabled(isLoading)
                    }
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

struct TaskFormView_Previews: PreviewProvider {
    static var previews: some View {
        TaskFormView(
            task: TodoTask(
                id: "1",
                title: "Estudar Algoritmos",
                description: nil,
                status: "pending",
                priority: "high",
                dueDate: nil,
                hasTime: false,
                estimatedMinutes: 0,
                isArchived: false,
                createdAt: "",
                updatedAt: "",
                project: nil,
                tags: [],
                focusSessions: [],
                isRecurring: false,
                needsReminder: false
            ),
            viewModel: TaskViewModel()
        ) {
            // Preview only
        }
    }
} 