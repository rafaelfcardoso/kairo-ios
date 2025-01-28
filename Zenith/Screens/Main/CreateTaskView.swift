import SwiftUI

struct CreateTaskView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var taskName: String = ""
    @State private var taskDescription: String = ""
    @State private var selectedPriority: Priority? = nil
    @State private var isLoading = false
    @State private var shouldSubmit = false
    var onTaskCreated: @Sendable () async -> Void
    
    enum Priority: String, CaseIterable {
        case p1 = "high"
        case p2 = "medium"
        case p3 = "low"
        case p4 = "none"
        
        var displayName: String {
            switch self {
                case .p1: return "Prioridade 1"
                case .p2: return "Prioridade 2"
                case .p3: return "Prioridade 3"
                case .p4: return "Prioridade 4"
            }
        }
        
        var color: Color {
            switch self {
                case .p1: return .red
                case .p2: return .orange
                case .p3: return .blue
                case .p4: return .gray
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
    
    func createTask() async {
        guard !taskName.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        let dateFormatter = ISO8601DateFormatter()
        let dueDate = dateFormatter.string(from: Date().addingTimeInterval(24 * 60 * 60))
        
        let task = [
            "title": taskName,
            "description": taskDescription,
            "priority": selectedPriority?.rawValue ?? "none",
            "dueDate": dueDate
        ]
        
        guard let url = URL(string: "http://localhost:3001/tasks"),
              let jsonData = try? JSONSerialization.data(withJSONObject: task) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.httpBody = jsonData
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                await onTaskCreated()
                await MainActor.run {
                    dismiss()
                }
            }
        } catch {
            print("Error creating task: \(error)")
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
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "calendar")
                                Text("Hoje")
                                    .font(.system(size: 15, weight: .regular, design: .default))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(textColor)
                        }
                        
                        Menu {
                            ForEach(Priority.allCases, id: \.self) { priority in
                                Button(action: {
                                    selectedPriority = priority
                                }) {
                                    HStack {
                                        Image(systemName: "flag.fill")
                                            .foregroundColor(priority.color)
                                        Text(priority.displayName)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "flag.fill")
                                    .foregroundColor(selectedPriority?.color ?? .orange)
                                Text(selectedPriority?.displayName ?? "Prioridade")
                                    .font(.system(size: 15, weight: .regular, design: .default))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(textColor)
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