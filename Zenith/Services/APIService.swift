import Foundation

/// Service for handling API requests to the backend
class APIService {
    // MARK: - Properties
    static let shared = APIService()
    
    private let baseURL = URL(string: "https://api.zenith-app.com/api/v1")!
    private var authToken: String?
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Authentication
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    // MARK: - HTTP Request Methods
    /// Generic request method
    func request<T: Decodable>(endpoint: String, method: HTTPMethod, body: Encodable? = nil) async throws -> T {
        guard let url = URL(string: endpoint, relativeTo: baseURL) else {
            throw APIError.invalidURL("Failed to create URL from endpoint: \(endpoint)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let authToken = authToken {
            request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(body)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200..<300:
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
            case 401:
                throw APIError.unauthorized
            case 404:
                if let responseStr = String(data: data, encoding: .utf8) {
                    throw APIError.clientError(404, responseStr)
                } else {
                    throw APIError.clientError(404, "Resource not found")
                }
            case 400..<500:
                if let responseStr = String(data: data, encoding: .utf8) {
                    throw APIError.clientError(httpResponse.statusCode, responseStr)
                } else {
                    throw APIError.clientError(httpResponse.statusCode, "Client error")
                }
            case 500..<600:
                if let responseStr = String(data: data, encoding: .utf8) {
                    throw APIError.serverError(httpResponse.statusCode, responseStr)
                } else {
                    throw APIError.serverError(httpResponse.statusCode, "Server error")
                }
            default:
                throw APIError.invalidResponse
            }
        } catch let urlError as URLError {
            throw APIError.networkError(urlError)
        } catch let apiError as APIError {
            throw apiError // Rethrow APIError as is
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    /// GET request
    func get<T: Decodable>(endpoint: String) async throws -> T {
        try await request(endpoint: endpoint, method: .get)
    }
    
    /// POST request
    func post<T: Decodable, U: Encodable>(endpoint: String, body: U) async throws -> T {
        try await request(endpoint: endpoint, method: .post, body: body)
    }
    
    /// PATCH request
    func patch<T: Decodable, U: Encodable>(endpoint: String, body: U) async throws -> T {
        try await request(endpoint: endpoint, method: .patch, body: body)
    }
    
    /// DELETE request
    func delete(endpoint: String) async throws {
        let _: EmptyResponse = try await request(endpoint: endpoint, method: .delete)
    }
}

// MARK: - Supporting Types
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct EmptyResponse: Decodable {} 