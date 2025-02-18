import Foundation

@MainActor
class ProjectViewModel: ObservableObject {
    @Published private(set) var projects: [Project] = []
    private let baseURL = APIConfig.baseURL
    
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
        
        // Use the generic request executor
        let _: EmptyResponse = try await executeRequest(request)
        
        // Refresh projects list after successful creation
        try await loadProjects()
    }
    
    func loadProjects() async throws {
        print("📂 [Projects] Loading projects...")
        let endpointURL = try APIConfig.getEndpointURL("/projects")
        var urlComponents = URLComponents(string: endpointURL)!
        
        // Add includeSystem query parameter
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
        projects = decodedProjects
    }
    
    private struct EmptyResponse: Decodable {}
} 
