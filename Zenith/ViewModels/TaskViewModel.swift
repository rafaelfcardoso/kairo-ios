import Foundation

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    private let baseURL = "http://localhost:3001"
    
    // Combined function for fetching and refreshing tasks
    func loadTasks(isRefreshing: Bool = false) async throws {
        guard let url = URL(string: "\(baseURL)/tasks?includeArchived=false") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            var tasks = try JSONDecoder().decode([Task].self, from: data)
            
            // Sort tasks by priority
            tasks.sort { task1, task2 in
                let priorityOrder: [String: Int] = ["high": 0, "medium": 1, "low": 2]
                let priority1 = priorityOrder[task1.priority.lowercased()] ?? 3
                let priority2 = priorityOrder[task2.priority.lowercased()] ?? 3
                return priority1 < priority2
            }
            
            self.tasks = tasks
        } catch {
            throw error
        }
    }
    
    // Call this for initial fetch
    func fetchTasks() async {
        do {
            try await loadTasks()
        } catch {
            print("Error loading tasks: \(error)")
        }
    }
    
    // Call this for refresh
    @MainActor
    func refreshTasks() async {
        do {
            try await loadTasks(isRefreshing: true)
        } catch {
            print("Error refreshing tasks: \(error)")
        }
    }
} 
