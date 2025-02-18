import Foundation
import AVFoundation
import UIKit

@MainActor
class TaskViewModel: ObservableObject {
    @Published private(set) var tasks: [TodoTask] = []
    @Published private(set) var overdueTasks: [TodoTask] = []
    @Published private(set) var isLoading = false
    @Published private(set) var greeting: String = ""
    @Published private(set) var formattedDate: String = ""
    private let baseURL = APIConfig.baseURL
    private var audioPlayer: AVAudioPlayer?
    private var currentTask: Task<Void, Error>? // This is a Swift concurrency task
    
    init() {
        prepareCompletionSound()
        updateDateTime()
        
        // Observe when app becomes active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateOnForeground),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func updateOnForeground() {
        updateDateTime()
    }
    
    private func updateDateTime() {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        // Update greeting based on time of day
        greeting = switch hour {
            case 5..<12: "Bom dia."
            case 12..<18: "Boa tarde."
            default: "Boa noite."
        }
        
        // Format the date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "pt_BR")
        dateFormatter.dateFormat = "dd 'de' MMMM"
        formattedDate = dateFormatter.string(from: date)
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
    
    private func executeRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Try to handle the response
            try APIConfig.handleAPIResponse(data, httpResponse)
            
            // If successful, decode the data
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as APIError {
            if case .unauthorized = error {
                // If unauthorized, try to authenticate and retry once
                try await APIConfig.authenticateWithToken()
                
                // Retry the request with the new token
                var retryRequest = request
                APIConfig.addAuthHeaders(to: &retryRequest)
                
                let (retryData, retryResponse) = try await URLSession.shared.data(for: retryRequest)
                guard let httpResponse = retryResponse as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                try APIConfig.handleAPIResponse(retryData, httpResponse)
                return try JSONDecoder().decode(T.self, from: retryData)
            }
            throw error
        }
    }
    
    func loadTasks(projectId: String? = nil, isRefreshing: Bool = false, forToday: Bool = false) async throws {
        // Cancel any ongoing network request
        currentTask?.cancel()
        
        // Create a new task
        currentTask = Task {
            let endpointURL = try APIConfig.getEndpointURL("/tasks")
            var urlComponents = URLComponents(string: endpointURL)!
            var queryItems = [
                URLQueryItem(name: "includeArchived", value: "false"),
                URLQueryItem(name: "status", value: "not_started")
            ]
            
            if let projectId = projectId {
                queryItems.append(URLQueryItem(name: "projectId", value: projectId))
            }
            
            urlComponents.queryItems = queryItems
            
            guard let url = urlComponents.url else {
                throw APIError.invalidURL(urlComponents.description)
            }
            
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "accept")
            APIConfig.addAuthHeaders(to: &request)
            
            let decodedTasks: [TodoTask] = try await executeRequest(request)
            
            if forToday {
                // Filter tasks for today after receiving them
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                tasks = decodedTasks.filter { task in
                    guard let dueDateString = task.dueDate,
                          let dueDate = dateFormatter.date(from: dueDateString) else {
                        return false
                    }
                    
                    let taskDay = calendar.startOfDay(for: dueDate)
                    return calendar.isDate(taskDay, inSameDayAs: today)
                }
            } else {
                tasks = decodedTasks
            }
        }
        
        try await currentTask?.value
    }
    
    func completeTask(_ task: TodoTask) async throws {
        let endpointURL = try APIConfig.getEndpointURL("/tasks/\(task.id)/status")
        guard let url = URL(string: endpointURL) else {
            throw APIError.invalidURL(endpointURL)
        }
        
        let body = ["status": "completed"]
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        APIConfig.addAuthHeaders(to: &request)
        request.httpBody = jsonData
        
        // Use the generic request executor
        let _: EmptyResponse = try await executeRequest(request)
        
        let taskId = task.id
        // Play completion sound
        audioPlayer?.play()
        
        // Remove the task from the list
        tasks.removeAll { $0.id == taskId }
    }
    
    // Add this struct for empty responses
    private struct EmptyResponse: Decodable {}
    
    // Natural language task creation
    func createTaskFromNaturalLanguage(_ command: String) async throws {
        let endpointURL = "http://localhost:8000/api/v1/tasks/natural-language"
        guard let url = URL(string: endpointURL) else {
            throw APIError.invalidURL(endpointURL)
        }
        
        // Get timezone information
        let timeZone = TimeZone.current
        let offsetInSeconds = timeZone.secondsFromGMT()
        let offsetInHours = Double(offsetInSeconds) / 3600.0
        let offsetSign = offsetInHours >= 0 ? "+" : ""
        
        let userContext: [String: Any] = [
            "timezone": [
                "identifier": timeZone.identifier,
                "abbreviation": timeZone.abbreviation() ?? "",
                "offsetSeconds": offsetInSeconds,
                "offsetString": "GMT\(offsetSign)\(Int(offsetInHours)):00"
            ]
        ]
        
        print("🕒 [NLP] Using timezone context: \(userContext)")
        
        let body: [String: Any] = [
            "command": command,
            "user_context": userContext
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        APIConfig.addAuthHeaders(to: &request)
        request.httpBody = jsonData
        
        // Use the generic request executor
        let _: EmptyResponse = try await executeRequest(request)
        
        // Refresh tasks after creation
        try await loadTasks(forToday: true)
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
    
    func loadOverdueTasks() async throws {
        let endpointURL = try APIConfig.getEndpointURL("/tasks/views/overdue")
        let urlComponents = URLComponents(string: endpointURL)!
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL(urlComponents.description)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "accept")
        APIConfig.addAuthHeaders(to: &request)
        
        overdueTasks = try await executeRequest(request)
    }
    
    func loadAllTasks() async throws {
        // Load both task types concurrently
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Add overdue tasks loading
            group.addTask {
                try await self.loadOverdueTasks()
            }
            
            // Add today's tasks loading
            group.addTask {
                try await self.loadTasks(forToday: true)
            }
            
            // Wait for all tasks to complete
            try await group.waitForAll()
        }
    }
} 
