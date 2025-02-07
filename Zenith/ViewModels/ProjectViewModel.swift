import Foundation

@MainActor
class ProjectViewModel: ObservableObject {
    @Published private(set) var projects: [Project] = []
    private let baseURL = "https://zenith-api-nest-development.up.railway.app"
    
    func createProject(name: String, color: String) async throws {
        guard let url = URL(string: "\(baseURL)/projects") else {
            throw URLError(.badURL)
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
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response type")
                throw URLError(.badServerResponse)
            }
            
            print("Create project response status code: \(httpResponse.statusCode)")
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Server error: \(errorJson)")
                }
                throw URLError(.badServerResponse)
            }
            
            // Refresh projects list after successful creation
            try await loadProjects()
        } catch {
            print("Error creating project: \(error)")
            throw error
        }
    }
    
    func loadProjects() async throws {
        print("Loading projects...")
        var urlComponents = URLComponents(string: "\(baseURL)/projects")!
        urlComponents.queryItems = [
            URLQueryItem(name: "includeSystem", value: "true"),
            URLQueryItem(name: "includeArchived", value: "false")
        ]
        
        guard let url = urlComponents.url else {
            print("Invalid URL")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response type")
                throw URLError(.badServerResponse)
            }
            
            print("Response status code: \(httpResponse.statusCode)")
            
            if !(200...299).contains(httpResponse.statusCode) {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Server error: \(errorJson)")
                }
                throw URLError(.badServerResponse)
            }
            
            // Print the raw JSON response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }
            
            let decodedProjects: [Project] = try JSONDecoder().decode([Project].self, from: data)
            print("Successfully decoded \(decodedProjects.count) projects")
            self.projects = decodedProjects
        } catch {
            print("Error loading projects: \(error)")
            throw error
        }
    }
} 