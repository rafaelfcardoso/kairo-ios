import Foundation
import AVFoundation

@MainActor
class TaskViewModel: ObservableObject {
    @Published private(set) var tasks: [TodoTask] = []
    @Published private(set) var isLoading = false
    private let baseURL = "https://zenith-api-nest-development.up.railway.app"
    private var audioPlayer: AVAudioPlayer?
    private var currentTask: Task<Void, Error>? // This is a Swift concurrency task
    
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
    
    func loadTasks(projectId: String? = nil, isRefreshing: Bool = false, forToday: Bool = false) async throws {
        // Cancel any ongoing network request
        currentTask?.cancel()
        
        // Create a new task
        currentTask = Task {
            var urlComponents = URLComponents(string: "\(baseURL)/tasks")!
            var queryItems = [
                URLQueryItem(name: "includeArchived", value: "false"),
                URLQueryItem(name: "status", value: "not_started")
            ]
            
            if let projectId = projectId {
                queryItems.append(URLQueryItem(name: "projectId", value: projectId))
            }
            
            urlComponents.queryItems = queryItems
            
            guard let url = urlComponents.url else {
                print("Invalid URL: \(urlComponents)")
                throw URLError(.badURL)
            }
            
            print("Loading tasks with URL: \(url)")
            
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            
            guard httpResponse.statusCode == 200 else {
                print("HTTP Error: \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    print("Error response: \(errorString)")
                }
                throw URLError(.badServerResponse)
            }
            
            print("Raw JSON response: \(String(data: data, encoding: .utf8) ?? "")")
            
            let decodedTasks = try JSONDecoder().decode([TodoTask].self, from: data)
            
            if forToday {
                // Filter tasks for today after receiving them
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                print("Filtering tasks for today: \(today)")
                
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                tasks = decodedTasks.filter { task in
                    guard let dueDateString = task.dueDate,
                          let dueDate = dateFormatter.date(from: dueDateString) else {
                        print("Task \(task.title) has no due date or invalid date format")
                        return false
                    }
                    
                    // Compare only the date components (year, month, day)
                    let taskDay = calendar.startOfDay(for: dueDate)
                    let isToday = calendar.isDate(taskDay, inSameDayAs: today)
                    print("Task '\(task.title)' due date: \(dueDate), isToday: \(isToday)")
                    return isToday
                }
                print("Found \(tasks.count) tasks for today out of \(decodedTasks.count) total tasks")
            } else {
                tasks = decodedTasks
            }
        }
        
        // Wait for the task to complete
        try await currentTask?.value
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
            // Play completion sound
            audioPlayer?.play()
            
            // Remove the task from the list
            tasks.removeAll { $0.id == taskId }
        } catch {
            print("Task completion error: \(error)")
            throw error
        }
    }
    
    // Call this for initial fetch
    func fetchTasks() async {
        do {
            try await loadTasks()
        } catch {
            if !(error is CancellationError) {
                print("Error loading tasks: \(error)")
            }
        }
    }
    
    // Call this for refresh
    func refreshTasks(projectId: String? = nil, forToday: Bool = false) async {
        do {
            try await loadTasks(projectId: projectId, isRefreshing: true, forToday: forToday)
        } catch {
            if !(error is CancellationError) {
                print("Error refreshing tasks: \(error)")
            }
        }
    }
} 
