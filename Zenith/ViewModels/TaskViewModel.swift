import Foundation
import AVFoundation

class TaskViewModel: ObservableObject {
    @Published var tasks: [TodoTask] = []
    private let baseURL = "http://localhost:3001"
    private var audioPlayer: AVAudioPlayer?
    
    init() {
        prepareCompletionSound()
    }
    
    private func prepareCompletionSound() {
        guard let soundURL = Bundle.main.url(forResource: "completion", withExtension: "mp3") else {
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Could not create audio player: \(error)")
        }
    }
    
    func completeTask(_ task: TodoTask) async throws {
        guard let url = URL(string: "\(baseURL)/tasks/\(task.id)/status") else {
            throw URLError(.badURL)
        }
        
        let body = ["status": "completed"]
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                throw URLError(.badServerResponse)
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Server error: \(errorJson)")
                }
                throw URLError(.badServerResponse)
            }
            
            let taskId = task.id
            await MainActor.run {
                // Play completion sound
                audioPlayer?.play()
                
                // Remove the task from the list
                tasks.removeAll { $0.id == taskId }
            }
        } catch {
            print("Task completion error: \(error)")
            throw error
        }
    }
    
    // Combined function for fetching and refreshing tasks
    func loadTasks(isRefreshing: Bool = false) async throws {
        guard let url = URL(string: "\(baseURL)/tasks?status=pending&includeArchived=false") else {
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
            
            let decodedTasks = try JSONDecoder().decode([TodoTask].self, from: data)
            
            // Sort tasks by priority
            let sortedTasks = decodedTasks.sorted { task1, task2 in
                let priorityOrder: [String: Int] = ["high": 0, "medium": 1, "low": 2]
                let priority1 = priorityOrder[task1.priority.lowercased()] ?? 3
                let priority2 = priorityOrder[task2.priority.lowercased()] ?? 3
                return priority1 < priority2
            }
            
            await MainActor.run {
                self.tasks = sortedTasks
            }
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
