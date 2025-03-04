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
    @Published var isOfflineMode = false
    @Published var lastSuccessfulSync: Date? = nil
    
    private let baseURL = APIConfig.baseURL
    private var currentTask: Task<Void, Error>? // This is a Swift concurrency task
    private var lastFetchTime: Date?
    private let cacheTimeout: TimeInterval = 120 // 120 seconds cache
    private var lastOverdueFetchTime: Date?  // Add this for overdue tasks cache
    private var lastCompletedTask: TodoTask? // Store the last completed task for undo
    private var offlineTasksCache: [TodoTask] = []
    private var offlineOverdueTasksCache: [TodoTask] = []
    
    // Keys for UserDefaults
    private let tasksCacheKey = "cached_tasks"
    private let overdueTasksCacheKey = "cached_overdue_tasks"
    private let lastSyncKey = "last_successful_sync"
    
    init() {
        updateDateTime()
        
        // Load cached data from disk
        loadOfflineCacheFromDisk()
        
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
    
    private func executeRequest<T: Decodable>(_ request: URLRequest, retryCount: Int = 0, maxRetries: Int = 3) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            // Try to handle the response
            try APIConfig.handleAPIResponse(data, httpResponse)
            
            // If successful, decode the data
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                print("Decoding error: \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response that failed to decode: \(responseString)")
                }
                throw APIError.decodingError(error)
            }
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
                
                do {
                    return try JSONDecoder().decode(T.self, from: retryData)
                } catch {
                    print("Decoding error after retry: \(error)")
                    if let responseString = String(data: retryData, encoding: .utf8) {
                        print("Response that failed to decode after retry: \(responseString)")
                    }
                    throw APIError.decodingError(error)
                }
            } else if case .serverError = error, retryCount < maxRetries {
                // For server errors, implement exponential backoff retry
                let delay = pow(2.0, Double(retryCount)) // Exponential backoff: 1, 2, 4, 8 seconds
                print("🌐 [API] Server error, retrying in \(delay) seconds (attempt \(retryCount + 1)/\(maxRetries))")
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeRequest(request, retryCount: retryCount + 1, maxRetries: maxRetries)
            }
            throw error
        } catch {
            // For network errors, also implement retry with backoff
            if (error as NSError).domain == NSURLErrorDomain && retryCount < maxRetries {
                let delay = pow(2.0, Double(retryCount)) // Exponential backoff
                print("🌐 [API] Network error, retrying in \(delay) seconds (attempt \(retryCount + 1)/\(maxRetries))")
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeRequest(request, retryCount: retryCount + 1, maxRetries: maxRetries)
            }
            throw APIError.networkError(error)
        }
    }
    
    // Save offline cache to disk
    private func saveOfflineCacheToDisk() {
        let encoder = JSONEncoder()
        
        // Save tasks cache
        if !offlineTasksCache.isEmpty {
            do {
                let data = try encoder.encode(offlineTasksCache)
                UserDefaults.standard.set(data, forKey: tasksCacheKey)
                print("🌐 [Tasks] Saved \(offlineTasksCache.count) tasks to local cache")
            } catch {
                print("🌐 [Tasks] Error saving tasks to cache: \(error)")
            }
        }
        
        // Save overdue tasks cache
        if !offlineOverdueTasksCache.isEmpty {
            do {
                let data = try encoder.encode(offlineOverdueTasksCache)
                UserDefaults.standard.set(data, forKey: overdueTasksCacheKey)
                print("🌐 [Tasks] Saved \(offlineOverdueTasksCache.count) overdue tasks to local cache")
            } catch {
                print("🌐 [Tasks] Error saving overdue tasks to cache: \(error)")
            }
        }
        
        // Save last sync time
        if let lastSync = lastSuccessfulSync {
            UserDefaults.standard.set(lastSync, forKey: lastSyncKey)
        }
    }
    
    // Load offline cache from disk
    private func loadOfflineCacheFromDisk() {
        let decoder = JSONDecoder()
        
        // Load tasks cache
        if let data = UserDefaults.standard.data(forKey: tasksCacheKey) {
            do {
                let cachedTasks = try decoder.decode([TodoTask].self, from: data)
                self.offlineTasksCache = cachedTasks
                
                // If we have cached tasks, use them initially
                if !cachedTasks.isEmpty && self.tasks.isEmpty {
                    self.tasks = cachedTasks
                    self.isOfflineMode = true
                    print("🌐 [Tasks] Loaded \(cachedTasks.count) tasks from local cache")
                }
            } catch {
                print("🌐 [Tasks] Error loading tasks from cache: \(error)")
            }
        }
        
        // Load overdue tasks cache
        if let data = UserDefaults.standard.data(forKey: overdueTasksCacheKey) {
            do {
                let cachedOverdueTasks = try decoder.decode([TodoTask].self, from: data)
                self.offlineOverdueTasksCache = cachedOverdueTasks
                
                // If we have cached overdue tasks, use them initially
                if !cachedOverdueTasks.isEmpty && self.overdueTasks.isEmpty {
                    self.overdueTasks = cachedOverdueTasks
                    self.isOfflineMode = true
                    print("🌐 [Tasks] Loaded \(cachedOverdueTasks.count) overdue tasks from local cache")
                }
            } catch {
                print("🌐 [Tasks] Error loading overdue tasks from cache: \(error)")
            }
        }
        
        // Load last sync time
        if let lastSync = UserDefaults.standard.object(forKey: lastSyncKey) as? Date {
            self.lastSuccessfulSync = lastSync
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
            do {
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
                
                print("🌐 [Tasks] Request URL: \(url.absoluteString)")
                
                var request = URLRequest(url: url)
                request.setValue("application/json", forHTTPHeaderField: "accept")
                APIConfig.addAuthHeaders(to: &request)
                
                let decodedTasks: [TodoTask] = try await executeRequest(request)
                print("🌐 [Tasks] Successfully loaded \(decodedTasks.count) tasks")
                
                // Store in offline cache
                self.offlineTasksCache = decodedTasks
                self.lastSuccessfulSync = Date()
                self.isOfflineMode = false
                
                // Save to disk
                saveOfflineCacheToDisk()
                
                // Process tasks to avoid duplicates between overdue and today's tasks
                await MainActor.run {
                    // Get the IDs of tasks that are already in the overdueTasks collection
                    let overdueTaskIds = Set(self.overdueTasks.map { $0.id })
                    
                    // Filter out tasks that are already in the overdueTasks collection
                    let filteredTasks = decodedTasks.filter { !overdueTaskIds.contains($0.id) }
                    
                    if forToday {
                        // Filter for today's tasks
                        let calendar = Calendar.current
                        let today = calendar.startOfDay(for: Date())
                        let dateFormatter = ISO8601DateFormatter()
                        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        
                        self.tasks = filteredTasks.filter { task in
                            guard let dueDateString = task.dueDate,
                                  let dueDate = dateFormatter.date(from: dueDateString) else {
                                return false
                            }
                            
                            let taskDay = calendar.startOfDay(for: dueDate)
                            return calendar.isDate(taskDay, inSameDayAs: today)
                        }
                    } else {
                        self.tasks = filteredTasks
                    }
                    
                    self.lastFetchTime = Date()
                    self.isLoading = false
                }
            } catch {
                print("🌐 [Tasks] Error loading tasks: \(error.localizedDescription)")
                
                // Switch to offline mode if we have cached data
                if !self.offlineTasksCache.isEmpty {
                    print("🌐 [Tasks] Switching to offline mode with \(self.offlineTasksCache.count) cached tasks")
                    self.isOfflineMode = true
                    
                    if forToday {
                        // Filter cached tasks for today
                        let calendar = Calendar.current
                        let today = calendar.startOfDay(for: Date())
                        let dateFormatter = ISO8601DateFormatter()
                        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        
                        tasks = self.offlineTasksCache.filter { task in
                            guard let dueDateString = task.dueDate,
                                  let dueDate = dateFormatter.date(from: dueDateString) else {
                                return false
                            }
                            
                            let taskDay = calendar.startOfDay(for: dueDate)
                            return calendar.isDate(taskDay, inSameDayAs: today)
                        }
                    } else {
                        tasks = self.offlineTasksCache
                    }
                } else {
                    // No cached data available, propagate the error
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .decodingError(let decodingError):
                            print("🌐 [Tasks] Decoding error details: \(decodingError)")
                        case .clientError(let code, let message):
                            print("🌐 [Tasks] Client error (\(code)): \(message)")
                        case .serverError(let code, let message):
                            print("🌐 [Tasks] Server error (\(code)): \(message)")
                        default:
                            print("🌐 [Tasks] API error: \(apiError.localizedDescription)")
                        }
                    }
                    throw error
                }
            }
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
        
        do {
            let endpointURL = try APIConfig.getEndpointURL("/tasks/views/overdue")
            let urlComponents = URLComponents(string: endpointURL)!
            
            guard let url = urlComponents.url else {
                throw APIError.invalidURL(urlComponents.description)
            }
            
            print("🌐 [Tasks] Overdue request URL: \(url.absoluteString)")
            
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "accept")
            APIConfig.addAuthHeaders(to: &request)
            
            let fetchedOverdueTasks: [TodoTask] = try await executeRequest(request)
            
            // Get the IDs of tasks that are already in the regular tasks collection
            let regularTaskIds = Set(tasks.map { $0.id })
            
            // Filter out tasks that are already in the regular tasks collection
            let uniqueOverdueTasks = fetchedOverdueTasks.filter { !regularTaskIds.contains($0.id) }
            
            // Update the overdue tasks collection
            overdueTasks = uniqueOverdueTasks
            
            self.offlineOverdueTasksCache = overdueTasks
            self.lastSuccessfulSync = Date()
            self.isOfflineMode = false
            
            // Save to disk
            saveOfflineCacheToDisk()
            
            print("🌐 [Tasks] Successfully loaded \(overdueTasks.count) overdue tasks")
            lastOverdueFetchTime = Date()  // Update cache timestamp
        } catch {
            print("🌐 [Tasks] Error loading overdue tasks: \(error.localizedDescription)")
            
            // Switch to offline mode if we have cached data
            if !self.offlineOverdueTasksCache.isEmpty {
                print("🌐 [Tasks] Switching to offline mode with \(self.offlineOverdueTasksCache.count) cached overdue tasks")
                self.isOfflineMode = true
                overdueTasks = self.offlineOverdueTasksCache
            } else {
                // No cached data available, propagate the error
                if let apiError = error as? APIError {
                    switch apiError {
                    case .decodingError(let decodingError):
                        print("🌐 [Tasks] Overdue decoding error details: \(decodingError)")
                    case .clientError(let code, let message):
                        print("🌐 [Tasks] Overdue client error (\(code)): \(message)")
                    case .serverError(let code, let message):
                        print("🌐 [Tasks] Overdue server error (\(code)): \(message)")
                    default:
                        print("🌐 [Tasks] Overdue API error: \(apiError.localizedDescription)")
                    }
                }
                throw error
            }
        }
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
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                // First load overdue tasks
                group.addTask {
                    do {
                        try await self.loadOverdueTasks()
                    } catch {
                        print("🌐 [Tasks] Error in loadAllTasks (overdue): \(error.localizedDescription)")
                        throw error
                    }
                }
                
                // Wait for overdue tasks to complete before loading regular tasks
                // This ensures that the filtering in loadTasks can properly exclude overdue tasks
                try await group.waitForAll()
                
                // Then load regular tasks
                try await self.loadTasks(forToday: true)
            }
            print("🌐 [Tasks] Successfully loaded all tasks: \(tasks.count) today tasks, \(overdueTasks.count) overdue tasks")
        } catch {
            print("🌐 [Tasks] Error loading all tasks: \(error.localizedDescription)")
            if let apiError = error as? APIError {
                switch apiError {
                case .decodingError(let decodingError):
                    print("🌐 [Tasks] All tasks decoding error details: \(decodingError)")
                case .clientError(let code, let message):
                    print("🌐 [Tasks] All tasks client error (\(code)): \(message)")
                case .serverError(let code, let message):
                    print("🌐 [Tasks] All tasks server error (\(code)): \(message)")
                default:
                    print("🌐 [Tasks] All tasks API error: \(apiError.localizedDescription)")
                }
            }
            throw error
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
