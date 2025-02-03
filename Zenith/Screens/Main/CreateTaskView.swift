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
    @State private var showingTimePicker = false
    @State private var selectedTime: Date? = nil
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1F1F1F") : Color(white: 0.94)
    }
    
    private var quickSelections: [(String, Date)] {
        let calendar = Calendar.current
        let today = Date()
        
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let weekend = calendar.nextWeekend(startingAfter: today)?.start ?? today
        let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: today)!
        
        return [
            ("Hoje", today),
            ("Amanhã", tomorrow),
            ("Este final de Semana", weekend),
            ("Próxima Semana", nextWeek)
        ]
    }
    
    private var formattedTime: String {
        guard let time = selectedTime else { return "Nenhum" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    private func applyTimeToDate(_ date: Date) -> Date {
        guard let time = selectedTime else { return date }
        return Calendar.current.date(
            bySettingHour: Calendar.current.component(.hour, from: time),
            minute: Calendar.current.component(.minute, from: time),
            second: 59,
            of: date
        ) ?? date
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(quickSelections, id: \.0) { option in
                        Button {
                            selectedDate = applyTimeToDate(option.1)
                            dismiss()
                        } label: {
                            HStack {
                                Text(option.0)
                                    .foregroundColor(textColor)
                                Spacer()
                                Text(option.1.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundColor(secondaryTextColor)
                            }
                        }
                    }
                }
                
                Section {
                    DatePicker(
                        "Selecionar data",
                        selection: Binding(
                            get: { selectedDate ?? Date() },
                            set: { newDate in
                                selectedDate = applyTimeToDate(newDate)
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
                        if selectedTime == nil {
                            selectedTime = Calendar.current.date(
                                bySettingHour: 23,
                                minute: 59,
                                second: 59,
                                of: Date()
                            )
                        }
                        showingTimePicker = true
                    }
                }
            }
            .navigationTitle("Prazo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Concluir") {
                        if let date = selectedDate {
                            selectedDate = applyTimeToDate(date)
                        }
                        dismiss()
                    }
                    .bold()
                }
            }
            .sheet(isPresented: $showingTimePicker) {
                TimeSelectionView(selectedTime: Binding(
                    get: { selectedTime ?? Date() },
                    set: { selectedTime = $0 }
                ))
            }
        }
    }
}

struct CreateTaskView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var taskName: String = ""
    @State private var taskDescription: String = ""
    @State private var selectedPriority: Priority? = nil
    @State private var selectedDate: Date? = nil
    @State private var isLoading = false
    @State private var shouldSubmit = false
    @State private var showingDatePicker = false
    var onTaskCreated: @Sendable () async -> Void
    
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
                case .p1: return Color(hex: "FF6B6B") // Coral red for high priority
                case .p2: return Color(hex: "FFA94D") // Warm orange for medium priority
                case .p3: return Color(hex: "4D96FF") // Bright blue for low priority
                case .p4: return Color(hex: "868E96") // Gray for no priority
            }
        }
    }
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1F1F1F") : Color(white: 0.94)
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var formattedSelectedDate: String {
        guard let date = selectedDate else { return "Hoje" }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Hoje"
        } else if calendar.isDateInTomorrow(date) {
            return "Amanhã"
        } else if calendar.isDateInWeekend(date) {
            return "Sábado"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
    
    var dueDateColor: Color {
        guard let date = selectedDate else { return Color.green }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return Color.green
        } else if calendar.isDateInTomorrow(date) {
            return Color(hex: "FFA94D") // Orange
        } else if calendar.isDateInWeekend(date) {
            return Color(hex: "845EF7") // Purple
        } else {
            return Color.gray
        }
    }
    
    func createTask() async {
        guard !taskName.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        
        // Use selected date or default to tomorrow at end of day
        let dueDate = selectedDate ?? Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let dueDateString = dateFormatter.string(from: dueDate)
        
        let task = [
            "title": taskName,
            "description": taskDescription,
            "priority": selectedPriority?.rawValue ?? "none",
            "dueDate": dueDateString
        ]
        
        guard let url = URL(string: "http://localhost:3001/tasks"),
            let jsonData = try? JSONSerialization.data(withJSONObject: task) else {
            print("Error creating JSON data")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                return
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Server error: \(errorJson)")
                }
                return
            }
            
            await onTaskCreated()
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("Network error: \(error)")
        }
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                TextField("Nome da tarefa", text: $taskName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20, weight: .medium, design: .default))
                    .foregroundColor(textColor)
                    .submitLabel(.done)
                    .onSubmit {
                        shouldSubmit = true
                    }
                
                TextField("Descrição", text: $taskDescription)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17, weight: .regular, design: .default))
                    .foregroundColor(textColor)
                    .submitLabel(.done)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "tray")
                                Text("Entrada")
                                    .font(.system(size: 15, weight: .regular, design: .default))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(textColor)
                        }
                        
                        Button(action: {
                            showingDatePicker = true
                        }) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(dueDateColor)
                                Text(formattedSelectedDate)
                                    .font(.system(size: 15, weight: .regular, design: .default))
                                    .foregroundColor(dueDateColor)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                        .sheet(isPresented: $showingDatePicker) {
                            DateSelectionView(selectedDate: $selectedDate)
                        }
                        
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
                            HStack {
                                Image(systemName: "flag.fill")
                                    .foregroundColor(selectedPriority?.color ?? .gray)
                                Text(selectedPriority?.shortName ?? "Prioridade")
                                    .font(.system(size: 15, weight: .regular, design: .default))
                                    .foregroundColor(selectedPriority?.color ?? textColor)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(20)
            .opacity(isLoading ? 0.5 : 1)
            .task(id: shouldSubmit) {
                if shouldSubmit {
                    await createTask()
                    shouldSubmit = false
                }
            }
            
            if isLoading {
                ProgressView()
            }
        }
    }
}

struct CreateTaskView_Previews: PreviewProvider {
    static var previews: some View {
        CreateTaskView(onTaskCreated: { @Sendable in 
            // Preview only, no need to actually refresh tasks
        })
        .previewDisplayName("Create Task")
    }
} 