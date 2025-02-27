import Foundation
import AVFoundation
import UIKit
import AudioToolbox

@MainActor
class TaskViewModel: ObservableObject {
    @Published var tasks: [TodoTask] = []
    @Published private(set) var overdueTasks: [TodoTask] = []
    @Published private(set) var isLoading = false
    @Published private(set) var greeting: String = ""
    @Published private(set) var formattedDate: String = ""
    @Published var showingUndoToast = false
    @Published var lastCompletedTaskTitle: String = ""
    @Published var timeWorkedToday: TimeInterval = 0
    @Published var focusSessionHistory: [(date: Date, duration: TimeInterval)] = []
    private let baseURL = APIConfig.baseURL
    private var currentTask: Task<Void, Error>? // This is a Swift concurrency task
    private var lastFetchTime: Date?
    private let cacheTimeout: TimeInterval = 120 // 120 seconds cache
    private var lastOverdueFetchTime: Date?  // Add this for overdue tasks cache
    private var lastCompletedTask: TodoTask? // Store the last completed task for undo
    
    init() {
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
        // Check if we have recent data
        if let lastFetch = lastFetchTime, 
           Date().timeIntervalSince(lastFetch) < cacheTimeout,
           !tasks.isEmpty {
            print("Using cached tasks data")
            return // Use cached data
        }
        
        print("Fetching new tasks data")
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
            
            lastFetchTime = Date()
        }
        
        try await currentTask?.value
    }
    
    func completeTask(_ task: TodoTask) async throws {
        let endpointURL = try APIConfig.getEndpointURL("/tasks/\(task.id)")
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
        
        // Store the task before removing it for potential undo
        lastCompletedTask = task
        lastCompletedTaskTitle = task.title
        
        // Play system sound
        AudioServicesPlaySystemSound(1004) // This is the "Tweet" sound
        
        tasks.removeAll { $0.id == taskId }
        overdueTasks.removeAll { $0.id == taskId }
        
        // Show the undo toast
        await MainActor.run {
            showingUndoToast = true
        }
        
        // Invalidate cache to ensure lists are updated
        invalidateCache()
    }
    
    func undoLastCompletion() async throws {
        guard let task = lastCompletedTask else { return }
        
        let endpointURL = try APIConfig.getEndpointURL("/tasks/\(task.id)")
        guard let url = URL(string: endpointURL) else {
            throw APIError.invalidURL(endpointURL)
        }
        
        let body = ["status": "not_started"]
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        APIConfig.addAuthHeaders(to: &request)
        request.httpBody = jsonData
        
        // Use the generic request executor
        let _: EmptyResponse = try await executeRequest(request)
        
        // Reset state
        lastCompletedTask = nil
        lastCompletedTaskTitle = ""
        
        // Reload tasks to get the restored task
        try await loadAllTasks()
    }
    
    // Add this struct for empty responses
    private struct EmptyResponse: Decodable {}
    
    // Natural language task creation
    func createTaskFromNaturalLanguage(_ command: String) async throws {
        let endpoint = "\(APIConfig.aiServiceURL)\(APIConfig.apiPath)/tasks/natural-language"
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL(endpoint)
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
        print("🌐 [AI] Sending request to: \(endpoint)")
        
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
        
        do {
            let _: EmptyResponse = try await executeRequest(request)
            invalidateCache() // Invalidate after creating new task
            try await loadTasks(forToday: true)
        } catch let error as NSError {
            print("❌ [AI] Error creating task: \(error.localizedDescription)")
            print("❌ [AI] Error details: \(error)")
            
            // Provide more specific error message for connection issues
            if error.domain == NSURLErrorDomain {
                switch error.code {
                case NSURLErrorCannotConnectToHost, NSURLErrorNotConnectedToInternet:
                    throw APIError.networkError(NSError(
                        domain: error.domain,
                        code: error.code,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Could not connect to the AI service. Please check your internet connection and try again."
                        ]
                    ))
                default:
                    throw APIError.networkError(error)
                }
            } else {
                throw APIError.networkError(error)
            }
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
    
    func loadOverdueTasks() async throws {
        // Add caching check
        if let lastFetch = lastOverdueFetchTime, 
           Date().timeIntervalSince(lastFetch) < cacheTimeout,
           !overdueTasks.isEmpty {
            print("Using cached overdue tasks data")
            return
        }
        
        print("Fetching new overdue tasks data")
        let endpointURL = try APIConfig.getEndpointURL("/tasks/views/overdue")
        let urlComponents = URLComponents(string: endpointURL)!
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL(urlComponents.description)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "accept")
        APIConfig.addAuthHeaders(to: &request)
        
        overdueTasks = try await executeRequest(request)
        lastOverdueFetchTime = Date()  // Update cache timestamp
    }
    
    func loadAllTasks() async throws {
        // Check if both caches are valid
        if let lastTasksFetch = lastFetchTime,
           let lastOverdueFetch = lastOverdueFetchTime,
           Date().timeIntervalSince(lastTasksFetch) < cacheTimeout,
           Date().timeIntervalSince(lastOverdueFetch) < cacheTimeout,
           !tasks.isEmpty || !overdueTasks.isEmpty {
            print("Using cached all tasks data")
            return
        }
        
        print("Fetching all new tasks data")
        // First invalidate caches on main actor
        await MainActor.run {
            lastOverdueFetchTime = nil
            lastFetchTime = nil
        }
        
        // Load both task types concurrently
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.loadOverdueTasks()
            }
            
            group.addTask {
                try await self.loadTasks(forToday: true)
            }
            
            try await group.waitForAll()
        }
    }
    
    // Add a method to invalidate cache when needed
    func invalidateCache() {
        print("Invalidating task caches")
        lastFetchTime = nil
        lastOverdueFetchTime = nil
    }
    
    func updateTimeWorkedToday(_ duration: TimeInterval) {
        timeWorkedToday += duration
        focusSessionHistory.append((date: Date(), duration: duration))
        // Persist to storage
    }
    
    // MARK: - Task Filtering Properties
    
    var todayTasks: [TodoTask] {
        // Regular today tasks are already filtered in the loadTasks method
        return tasks
    }
    
    var upcomingTasks: [TodoTask] {
        // Filter tasks with future dates (not today)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return tasks.filter { task in
            guard let dueDateString = task.dueDate,
                  let dueDate = dateFormatter.date(from: dueDateString) else {
                return false
            }
            
            let taskDay = calendar.startOfDay(for: dueDate)
            return taskDay >= tomorrow
        }
    }
    
    var inboxTasks: [TodoTask] {
        // Tasks with no project or in the system project
        return tasks.filter { task in
            task.project == nil || task.project?.isSystem == true
        }
    }
    
    var completedTasks: [TodoTask] {
        // For completed tasks, we would need another API call
        // This is a placeholder
        return []
    }
    
    var focusTasks: [TodoTask] {
        // Tasks suitable for focus sessions (perhaps based on priority)
        return tasks.filter { task in
            task.priority == "HIGH"
        }
    }
} 
