import SwiftUI
import Combine

class FocusSessionViewModel: ObservableObject {
    @Published var isActive = false
    @Published var isMinimized = false
    @Published var isExpanded = false
    @Published var selectedTask: TodoTask?
    @Published var timerDuration: TimeInterval = 25 * 60
    @Published var remainingTime: TimeInterval = 25 * 60
    @Published var timeWorkedToday: TimeInterval = 0
    @Published var showingForfeitAlert = false
    @Published var blockDistractions = true
    @Published var currentSessionId: String? = nil
    @Published var isLoadingInsights: Bool = false
    @Published var sevenDayDailyAverage: TimeInterval = 0
    
    // Break session properties
    @Published var isBreakActive = false
    @Published var breakDuration: TimeInterval = 5 * 60 // Default 5 minutes
    @Published var breakRemainingTime: TimeInterval = 5 * 60
    @Published var completedSessionsCount = 0
    @Published var showingSessionCompleteAlert = false
    
    private var timer: AnyCancellable?
    private var breakTimer: AnyCancellable?
    
    var progress: Double {
        1.0 - (remainingTime / timerDuration)
    }
    
    var breakProgress: Double {
        1.0 - (breakRemainingTime / breakDuration)
    }
    
    init() {
        Task {
            await loadFocusInsights()
        }
    }
    
    // MARK: - Focus Session Methods
    
    func startSession() {
        print("🎯 [Focus] Starting new focus session")
        isActive = true
        isExpanded = true
        isBreakActive = false
        showingSessionCompleteAlert = false
        startTimer()
        
        // Register the focus session with the API
        Task {
            do {
                if let task = selectedTask {
                    // Register with a task
                    try await registerFocusSession(taskIds: [task.id])
                } else {
                    // Register without a task (empty array of task IDs)
                    try await registerFocusSession(taskIds: [])
                }
            } catch {
                print("Error registering focus session: \(error)")
            }
        }
    }
    
    func startNewSessionAfterCompletion() {
        print("🎯 [Focus] Starting new session after completion")
        
        // Keep the same task selected
        let currentTask = selectedTask
        
        // Reset session state but keep the task
        resetSession()
        
        // Restore the task selection
        selectedTask = currentTask
        
        // Start a new session
        startSession()
    }
    
    func dismissSession() {
        print("🎯 [Focus] Dismissing session")
        isExpanded = false
        
        // If we're in a break or showing completion alert, reset everything
        if isBreakActive || showingSessionCompleteAlert {
            resetSession()
        }
    }
    
    func minimizeSession() {
        print("🎯 [Focus] Minimizing session")
        isMinimized = true
        isExpanded = false
    }
    
    func expandSession() {
        print("🎯 [Focus] Expanding session")
        isMinimized = false
        isExpanded = true
    }
    
    func forfeitSession() {
        print("🎯 [Focus] Forfeiting active session")
        stopTimer()
        
        // End the focus session in the API
        if let sessionId = currentSessionId {
            Task {
                do {
                    try await forfeitFocusSession(sessionId: sessionId)
                    // Refresh insights after ending the session
                    await loadFocusInsights()
                } catch {
                    print("Error ending focus session: \(error)")
                }
            }
        }
        
        resetSessionButStayExpanded()
    }
    
    func completeSession() {
        print("🎯 [Focus] Completing session")
        stopTimer()
        timeWorkedToday += timerDuration
        completedSessionsCount += 1
        
        // If the session is minimized, expand it to show the completion alert
        if isMinimized {
            print("🎯 [Focus] Session completed while minimized, expanding to show completion alert")
            isMinimized = false
            isExpanded = true
        }
        
        // Complete the focus session in the API
        if let sessionId = currentSessionId {
            Task {
                do {
                    try await completeFocusSession(sessionId: sessionId)
                    // Refresh insights after completing the session
                    await loadFocusInsights()
                } catch {
                    print("Error completing focus session: \(error)")
                }
            }
        }
        
        // Show completion alert and update state
        isActive = false
        showingSessionCompleteAlert = true
    }
    
    // MARK: - Break Session Methods
    
    func startBreak() {
        print("🎯 [Focus] Starting break")
        // Determine break duration based on completed sessions
        if completedSessionsCount % 4 == 0 {
            // Every 4th completed session gets a longer break (15 minutes)
            breakDuration = 15 * 60
            print("🎯 [Focus] Starting long break (15 minutes)")
        } else {
            // Regular short break (5 minutes)
            breakDuration = 5 * 60
            print("🎯 [Focus] Starting short break (5 minutes)")
        }
        
        breakRemainingTime = breakDuration
        isBreakActive = true
        showingSessionCompleteAlert = false
        startBreakTimer()
    }
    
    func skipBreak() {
        print("🎯 [Focus] Skipping break")
        stopBreakTimer()
        isBreakActive = false
        resetSession()
    }
    
    func forfeitLastSession() {
        print("🎯 [Focus] Forfeiting last completed session")
        // Revert the completion status
        if let sessionId = currentSessionId {
            print("🎯 [Focus] Attempting to forfeit last completed session with ID: \(sessionId)")
            Task {
                do {
                    try await forfeitFocusSession(sessionId: sessionId)
                    // Refresh insights after forfeiting the session
                    await loadFocusInsights()
                } catch {
                    print("🎯 [Focus] Error forfeiting last completed session: \(error)")
                }
            }
        } else {
            print("🎯 [Focus] No session ID available to forfeit")
        }
        
        completedSessionsCount = max(0, completedSessionsCount - 1)
        showingSessionCompleteAlert = false
        resetSession()
    }
    
    // New public method to skip break and reset the session state
    func skipBreakAndReset() {
        print("🎯 [Focus] Skipping break and resetting session")
        showingSessionCompleteAlert = false
        resetSessionButStayExpanded()
    }
    
    // New method to reset the session but keep the screen expanded
    func resetSessionButStayExpanded() {
        print("🎯 [Focus] Resetting session state but keeping screen expanded")
        if let sessionId = currentSessionId {
            print("🎯 [Focus] Clearing session ID: \(sessionId)")
        }
        
        isActive = false
        isMinimized = false
        // Note: We don't set isExpanded to false here
        isBreakActive = false
        remainingTime = timerDuration
        breakRemainingTime = breakDuration
        showingSessionCompleteAlert = false
        selectedTask = nil
        currentSessionId = nil
    }
    
    private func completeBreak() {
        print("🎯 [Focus] Break completed")
        stopBreakTimer()
        isBreakActive = false
        resetSession()
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.remainingTime > 0 {
                    self.remainingTime -= 1
                } else {
                    self.completeSession()
                }
            }
    }
    
    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    private func startBreakTimer() {
        breakTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.breakRemainingTime > 0 {
                    self.breakRemainingTime -= 1
                } else {
                    self.completeBreak()
                }
            }
    }
    
    private func stopBreakTimer() {
        breakTimer?.cancel()
        breakTimer = nil
    }
    
    private func resetSession() {
        print("🎯 [Focus] Resetting session state")
        if let sessionId = currentSessionId {
            print("🎯 [Focus] Clearing session ID: \(sessionId)")
        }
        
        isActive = false
        isMinimized = false
        isExpanded = false
        isBreakActive = false
        remainingTime = timerDuration
        breakRemainingTime = breakDuration
        showingSessionCompleteAlert = false
        selectedTask = nil
        currentSessionId = nil
    }
    
    // MARK: - API Methods
    
    @MainActor
    func registerFocusSession(taskIds: [String]) async throws {
        let endpointURL = try APIConfig.getEndpointURL("/focus-sessions")
        guard let url = URL(string: endpointURL) else {
            throw APIError.invalidURL(endpointURL)
        }
        
        // Create the request body
        let focusSession = FocusSession(taskIds: taskIds)
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(focusSession)
        
        // Create and configure the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        APIConfig.addAuthHeaders(to: &request)
        request.httpBody = jsonData
        
        // Execute the request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("🎯 [Focus] Response Status: \(httpResponse.statusCode)")
            // Check if response has valid string data without assigning to unused variable
            _ = String(data: data, encoding: .utf8) != nil
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    // Try to authenticate and retry
                    try await APIConfig.authenticateWithToken()
                    
                    var retryRequest = request
                    APIConfig.addAuthHeaders(to: &retryRequest)
                    
                    let (retryData, retryResponse) = try await URLSession.shared.data(for: retryRequest)
                    guard let retryHttpResponse = retryResponse as? HTTPURLResponse,
                          (200...299).contains(retryHttpResponse.statusCode) else {
                        throw APIError.invalidResponse
                    }
                    
                    if let responseString = String(data: retryData, encoding: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: retryData) as? [String: Any],
                       let sessionId = json["id"] as? String {
                        print("🎯 [Focus] Retry Response: \(responseString)")
                        self.currentSessionId = sessionId
                    }
                    return
                }
                throw APIError.invalidResponse
            }
            
            // Parse the response to get the session ID
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let sessionId = json["id"] as? String {
                self.currentSessionId = sessionId
                print("🎯 [Focus] Session registered with ID: \(sessionId)")
            }
        } catch {
            print("🎯 [Focus] Error registering session: \(error)")
            throw error
        }
    }
    
    @MainActor
    func forfeitFocusSession(sessionId: String) async throws {
        // Log the session ID we're trying to forfeit
        print("🎯 [Focus] Attempting to forfeit session with ID: \(sessionId)")
        
        // Use the PATCH endpoint directly on the session ID
        let endpointURL = try APIConfig.getEndpointURL("/focus-sessions/\(sessionId)")
        guard let url = URL(string: endpointURL) else {
            print("🎯 [Focus] Invalid URL for forfeit: \(endpointURL)")
            throw APIError.invalidURL(endpointURL)
        }
        
        print("🎯 [Focus] Forfeit using endpoint: \(endpointURL)")
        
        // Create the request body according to the API documentation
        let endTime = ISO8601DateFormatter().string(from: Date())
        
        // Create the body with the required fields - removed durationMinutes
        let body: [String: Any] = [
            "endTime": endTime,
            "energyLevel": "low",
            "wasSuccessful": false
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        print("🎯 [Focus] Forfeit request body: \(String(data: jsonData, encoding: .utf8) ?? "Unable to decode body")")
        
        // Create and configure the request
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        APIConfig.addAuthHeaders(to: &request)
        request.httpBody = jsonData
        
        // Execute the request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("🎯 [Focus] Invalid response type for forfeit")
                throw APIError.invalidResponse
            }
            
            print("🎯 [Focus] Forfeit Session Response Status: \(httpResponse.statusCode)")
            // Check if response has valid string data without assigning to unused variable
            _ = String(data: data, encoding: .utf8) != nil
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("🎯 [Focus] Forfeit failed with status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 401 {
                    // Try to authenticate and retry
                    print("🎯 [Focus] Attempting to reauthenticate for forfeit")
                    try await APIConfig.authenticateWithToken()
                    
                    var retryRequest = request
                    APIConfig.addAuthHeaders(to: &retryRequest)
                    
                    let (retryData, retryResponse) = try await URLSession.shared.data(for: retryRequest)
                    guard let retryHttpResponse = retryResponse as? HTTPURLResponse,
                          (200...299).contains(retryHttpResponse.statusCode) else {
                        print("🎯 [Focus] Forfeit retry failed with status: \((retryResponse as? HTTPURLResponse)?.statusCode ?? -1)")
                        throw APIError.invalidResponse
                    }
                    
                    if let responseString = String(data: retryData, encoding: .utf8) {
                        print("🎯 [Focus] Forfeit Session Retry Response: \(responseString)")
                    }
                    return
                }
                
                // If we get a 404, the session might have already been completed or doesn't exist
                if httpResponse.statusCode == 404 {
                    print("🎯 [Focus] Session not found (404). It may have already been completed or doesn't exist.")
                    // We'll consider this a success since we want to reset the session anyway
                    return
                }
                
                throw APIError.invalidResponse
            }
            
            print("🎯 [Focus] Session forfeited successfully")
        } catch {
            print("🎯 [Focus] Error forfeiting session: \(error)")
            throw error
        }
    }
    
    @MainActor
    func loadFocusInsights() async {
        isLoadingInsights = true
        defer { isLoadingInsights = false }
        
        do {
            // Load focus session history
            let sessions = try await fetchFocusSessionHistory()
            
            // Calculate time worked today
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            let todaySessions = sessions.filter { session in
                if let startTimeString = session["startTime"] as? String,
                   let startTime = ISO8601DateFormatter().date(from: startTimeString) {
                    return calendar.isDate(startTime, inSameDayAs: Date())
                }
                return false
            }
            
            // Calculate total time worked today
            var totalTimeToday: TimeInterval = 0
            for session in todaySessions {
                if let duration = session["duration"] as? Int {
                    totalTimeToday += TimeInterval(duration)
                }
            }
            self.timeWorkedToday = totalTimeToday
            
            // Calculate 7-day daily average
            var totalTimeLastSevenDays: TimeInterval = 0
            
            for session in sessions {
                if let startTimeString = session["startTime"] as? String,
                   let startTime = ISO8601DateFormatter().date(from: startTimeString),
                   let duration = session["duration"] as? Int {
                    
                    let sessionDay = calendar.startOfDay(for: startTime)
                    let daysSinceSession = calendar.dateComponents([.day], from: sessionDay, to: today).day ?? 0
                    
                    if daysSinceSession < 7 {
                        totalTimeLastSevenDays += TimeInterval(duration)
                    }
                }
            }
            
            // Calculate the average (divide by 7 days)
            self.sevenDayDailyAverage = totalTimeLastSevenDays / 7
            
            print("🎯 [Focus] Insights loaded: \(todaySessions.count) sessions today, 7-day average: \(Int(self.sevenDayDailyAverage / 60)) minutes per day")
            
        } catch {
            print("🎯 [Focus] Error loading insights: \(error)")
        }
    }
    
    @MainActor
    func fetchFocusSessionHistory() async throws -> [[String: Any]] {
        let endpointURL = try APIConfig.getEndpointURL("/focus-sessions")
        guard let url = URL(string: endpointURL) else {
            throw APIError.invalidURL(endpointURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        APIConfig.addAuthHeaders(to: &request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("🎯 [Focus] History Response Status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    // Try to authenticate and retry
                    try await APIConfig.authenticateWithToken()
                    
                    var retryRequest = request
                    APIConfig.addAuthHeaders(to: &retryRequest)
                    
                    let (retryData, retryResponse) = try await URLSession.shared.data(for: retryRequest)
                    guard let retryHttpResponse = retryResponse as? HTTPURLResponse,
                          (200...299).contains(retryHttpResponse.statusCode) else {
                        throw APIError.invalidResponse
                    }
                    
                    if let json = try? JSONSerialization.jsonObject(with: retryData) as? [[String: Any]] {
                        return json
                    }
                    return []
                }
                throw APIError.invalidResponse
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return json
            }
            return []
            
        } catch {
            print("🎯 [Focus] Error fetching session history: \(error)")
            throw error
        }
    }
    
    @MainActor
    func completeFocusSession(sessionId: String) async throws {
        print("🎯 [Focus] Attempting to complete session with ID: \(sessionId)")
        
        let endpointURL = try APIConfig.getEndpointURL("/focus-sessions/\(sessionId)/complete")
        guard let url = URL(string: endpointURL) else {
            print("🎯 [Focus] Invalid URL for complete: \(endpointURL)")
            throw APIError.invalidURL(endpointURL)
        }
        
        print("🎯 [Focus] Complete using endpoint: \(endpointURL)")
        
        // Create the request body according to the API documentation
        let endTime = ISO8601DateFormatter().string(from: Date())
        
        // Create the body with the required fields - removed durationMinutes
        let body: [String: Any] = [
            "endTime": endTime,
            "energyLevel": "medium",
            "wasSuccessful": true
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        print("🎯 [Focus] Complete request body: \(String(data: jsonData, encoding: .utf8) ?? "Unable to decode body")")
        
        // Create and configure the request
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        APIConfig.addAuthHeaders(to: &request)
        request.httpBody = jsonData
        
        // Execute the request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("🎯 [Focus] Invalid response type for complete")
                throw APIError.invalidResponse
            }
            
            print("🎯 [Focus] Complete Session Response Status: \(httpResponse.statusCode)")
            // Check if response has valid string data without assigning to unused variable
            _ = String(data: data, encoding: .utf8) != nil
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("🎯 [Focus] Complete failed with status code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 401 {
                    // Try to authenticate and retry
                    print("🎯 [Focus] Attempting to reauthenticate for complete")
                    try await APIConfig.authenticateWithToken()
                    
                    var retryRequest = request
                    APIConfig.addAuthHeaders(to: &retryRequest)
                    
                    let (retryData, retryResponse) = try await URLSession.shared.data(for: retryRequest)
                    guard let retryHttpResponse = retryResponse as? HTTPURLResponse,
                          (200...299).contains(retryHttpResponse.statusCode) else {
                        print("🎯 [Focus] Complete retry failed with status: \((retryResponse as? HTTPURLResponse)?.statusCode ?? -1)")
                        throw APIError.invalidResponse
                    }
                    
                    if let responseString = String(data: retryData, encoding: .utf8) {
                        print("🎯 [Focus] Complete Session Retry Response: \(responseString)")
                    }
                    return
                }
                
                // If we get a 404, the session might have already been completed or doesn't exist
                if httpResponse.statusCode == 404 {
                    print("🎯 [Focus] Session not found (404). It may have already been completed or doesn't exist.")
                    // We'll consider this a success since we want to reset the session anyway
                    return
                }
                
                throw APIError.invalidResponse
            }
            
            print("🎯 [Focus] Session completed successfully")
        } catch {
            print("🎯 [Focus] Error completing session: \(error)")
            throw error
        }
    }
} 
