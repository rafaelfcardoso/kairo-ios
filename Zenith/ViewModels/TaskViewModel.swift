import Foundation

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    private let baseURL = "http://localhost:3001"
    
    func fetchTasks() {
        guard let url = URL(string: "\(baseURL)/tasks?includeArchived=false") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Error fetching tasks: \(error)")
                return
            }
            
            guard let data = data else { return }
            
            // Print the raw JSON response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Raw JSON response: \(jsonString)")
            }
            
            do {
                let tasks = try JSONDecoder().decode([Task].self, from: data)
                DispatchQueue.main.async {
                    self?.tasks = tasks
                }
            } catch {
                print("Error decoding tasks: \(error)")
                
                // Additional error debugging
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("Missing key: \(key.stringValue)")
                        print("Debug description: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("Type mismatch: expected \(type)")
                        print("Debug description: \(context.debugDescription)")
                    default:
                        print("Other decoding error: \(decodingError)")
                    }
                }
            }
        }.resume()
    }
} 