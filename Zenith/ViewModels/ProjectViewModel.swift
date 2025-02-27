import Foundation

@MainActor
class ProjectViewModel: ObservableObject {
    @Published private(set) var projects: [Project] = []
    @Published private(set) var isLoading = false
    @Published private(set) var hasError = false
    
    private let baseURL = APIConfig.baseURL
    private var lastFetchTime: Date?
    private let cacheTimeout: TimeInterval = 300 // Extend cache to 5 minutes
    
    // Status variables
    private var isInitialLoadDone = false
    
    // Local persistence
    private let projectsCacheKey = "cached_projects"
    
    private func executeRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            print("📂 [Projects] Response status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("📂 [Projects] Response body: \(responseString)")
            }
            
            try APIConfig.handleAPIResponse(data, httpResponse)
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as APIError {
            print("📂 [Projects] API Error: \(error.localizedDescription)")
            if case .unauthorized = error {
                try await APIConfig.authenticateWithToken()
                
                var retryRequest = request
                APIConfig.addAuthHeaders(to: &retryRequest)
                
                let (retryData, retryResponse) = try await URLSession.shared.data(for: retryRequest)
                guard let httpResponse = retryResponse as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                print("📂 [Projects] Retry response status: \(httpResponse.statusCode)")
                if let responseString = String(data: retryData, encoding: .utf8) {
                    print("📂 [Projects] Retry response body: \(responseString)")
                }
                
                try APIConfig.handleAPIResponse(retryData, httpResponse)
                return try JSONDecoder().decode(T.self, from: retryData)
            }
            throw error
        }
    }
    
    func createProject(name: String, color: String) async throws {
        let endpointURL = try APIConfig.getEndpointURL("/projects")
        guard let url = URL(string: endpointURL) else {
            throw APIError.invalidURL(endpointURL)
        }
        
        let projectData = [
            "name": name,
            "description": "",
            "color": color,
            "parentId": nil
        ] as [String : Any?]
        
        let jsonData = try JSONSerialization.data(withJSONObject: projectData)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        APIConfig.addAuthHeaders(to: &request)
        request.httpBody = jsonData
        
        let _: EmptyResponse = try await executeRequest(request)
        
        invalidateCache() // Invalidate cache after creating new project
        try await loadProjects(forceRefresh: true)
    }
    
    // Enhanced loadProjects method with options and better caching
    func loadProjects(forceRefresh: Bool = false) async throws {
        // Return immediately if already loading to prevent duplicate requests
        if isLoading { return }
        
        // Set loading state
        isLoading = true
        hasError = false
        
        do {
            // Check if a refresh is needed based on cache conditions
            let shouldRefresh = forceRefresh || 
                               projects.isEmpty || 
                               lastFetchTime == nil || 
                               (Date().timeIntervalSince(lastFetchTime!) >= cacheTimeout)
            
            if !shouldRefresh {
                print("📂 [Projects] Using cached projects data")
                isLoading = false
                return
            }
            
            // First try to load from local storage as a fallback
            if projects.isEmpty {
                loadCachedProjects()
            }
            
            print("📂 [Projects] Loading projects from API...")
            let endpointURL = try APIConfig.getEndpointURL("/projects")
            var urlComponents = URLComponents(string: endpointURL)!
            
            urlComponents.queryItems = [
                URLQueryItem(name: "includeSystem", value: "true")
            ]
            
            guard let url = urlComponents.url else {
                throw APIError.invalidURL(urlComponents.description)
            }
            
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "accept")
            APIConfig.addAuthHeaders(to: &request)
            
            let decodedProjects: [Project] = try await executeRequest(request)
            print("📂 [Projects] Loaded \(decodedProjects.count) projects")
            print("📂 [Projects] System projects: \(decodedProjects.filter { $0.isSystem }.count)")
            
            // Update the state
            projects = decodedProjects
            lastFetchTime = Date()
            isInitialLoadDone = true
            
            // Cache the projects locally
            saveProjectsToCache(decodedProjects)
            
            isLoading = false
        } catch {
            print("📂 [Projects] Error loading projects: \(error)")
            isLoading = false
            hasError = true
            
            // If this was the first load attempt and we have cached data, keep using that
            if !isInitialLoadDone && !projects.isEmpty {
                // We already loaded from cache, so just set loading to false
                print("📂 [Projects] Falling back to cached projects due to error")
                isInitialLoadDone = true
            }
            
            throw error
        }
    }
    
    // Load projects immediately if needed
    func ensureProjectsLoaded() async {
        if projects.isEmpty && !isLoading {
            do {
                try await loadProjects()
            } catch {
                print("📂 [Projects] Error ensuring projects loaded: \(error)")
            }
        }
    }
    
    // Add cache invalidation method
    func invalidateCache() {
        lastFetchTime = nil
    }
    
    // MARK: - Local Cache Methods
    
    private func saveProjectsToCache(_ projects: [Project]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(projects)
            UserDefaults.standard.set(data, forKey: projectsCacheKey)
            print("📂 [Projects] Saved \(projects.count) projects to local cache")
        } catch {
            print("📂 [Projects] Error saving projects to cache: \(error)")
        }
    }
    
    private func loadCachedProjects() {
        guard projects.isEmpty else { return }
        
        if let data = UserDefaults.standard.data(forKey: projectsCacheKey) {
            do {
                let decoder = JSONDecoder()
                let cachedProjects = try decoder.decode([Project].self, from: data)
                self.projects = cachedProjects
                print("📂 [Projects] Loaded \(cachedProjects.count) projects from local cache")
            } catch {
                print("📂 [Projects] Error loading projects from cache: \(error)")
            }
        }
    }
    
    private struct EmptyResponse: Decodable {}
} 
