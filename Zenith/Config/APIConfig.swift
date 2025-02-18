import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case authenticationFailed(String)
    case invalidResponse
    case networkError(Error)
    case invalidURL(String)
    case malformedEndpoint(String)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized access. Please check your credentials."
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidURL(let url):
            return "Invalid URL construction: \(url)"
        case .malformedEndpoint(let endpoint):
            return "Malformed endpoint path: \(endpoint)"
        }
    }
}

enum APIConfig {
    #if DEBUG
    static var isTestEnvironment = false
    static var testBaseURL: String?
    #endif
    
    static var baseURL: String {
        #if DEBUG
        if isTestEnvironment, let testURL = testBaseURL {
            return testURL
        }
        #endif
        return "https://zenith-api-development.up.railway.app"
    }
    
    static let apiPath = "/api/v1"
    static let serviceKey = "2469ab5d2f05509a8c2e28b422cdc8b5ebebc037cb27cfc7071818fa172464b2"
    private static var authToken: String?
    
    static var isDebugLoggingEnabled = true
    
    private static func logDebug(_ message: String) {
        if isDebugLoggingEnabled {
            print("🌐 [API] \(message)")
        }
    }
    
    private static func logRequestBody(_ data: Data?) {
        guard isDebugLoggingEnabled,
              let data = data,
              let json = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return
        }
        logDebug("Request Body: \n\(prettyString)")
    }
    
    private static func logResponseBody(_ data: Data) {
        guard isDebugLoggingEnabled else { return }
        
        if let json = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            logDebug("Response Body: \n\(prettyString)")
        } else if let rawString = String(data: data, encoding: .utf8) {
            logDebug("Response Body (raw): \n\(rawString)")
        }
    }
    
    static func getEndpointURL(_ endpoint: String) throws -> String {
        // Validate endpoint format
        guard endpoint.hasPrefix("/") else {
            throw APIError.malformedEndpoint("Endpoint must start with /: \(endpoint)")
        }
        
        let fullURL = baseURL + apiPath + endpoint
        logDebug("Constructed URL: \(fullURL)")
        
        // Validate URL construction
        guard let _ = URL(string: fullURL) else {
            throw APIError.invalidURL(fullURL)
        }
        
        return fullURL
    }
    
    static func addAuthHeaders(to request: inout URLRequest) {
        // First try with service key
        request.setValue(serviceKey, forHTTPHeaderField: "X-Service-Key")
        
        // If we have a token, add it too
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        logDebug("Request URL: \(request.url?.absoluteString ?? "unknown")")
        logDebug("Request Method: \(request.httpMethod ?? "GET")")
        logDebug("Request Headers: \(request.allHTTPHeaders)")
        logRequestBody(request.httpBody)
    }
    
    static func handleAuthenticationError(_ response: HTTPURLResponse, data: Data) -> APIError {
        let errorMessage = String(data: data, encoding: .utf8) ?? "No error message available"
        logDebug("Authentication Error: \(response.statusCode) - \(errorMessage)")
        
        switch response.statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .authenticationFailed(errorMessage)
        default:
            return .invalidResponse
        }
    }
    
    static func authenticateWithToken() async throws {
        let authURL = baseURL + "/v1/auth/token"
        logDebug("Attempting authentication with URL: \(authURL)")
        
        guard let url = URL(string: authURL) else {
            throw APIError.invalidURL(authURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "serviceName": "ios-frontend",
            "serviceKey": serviceKey
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logDebug("Invalid response type received during authentication")
                throw APIError.invalidResponse
            }
            
            logDebug("Auth Response Status: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                throw handleAuthenticationError(httpResponse, data: data)
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["token"] as? String else {
                logDebug("Invalid token format in response")
                throw APIError.invalidResponse
            }
            
            authToken = token
            logDebug("Authentication successful")
        } catch {
            logDebug("Authentication failed: \(error.localizedDescription)")
            if let apiError = error as? APIError {
                throw apiError
            }
            throw APIError.networkError(error)
        }
    }
    
    static func handleAPIResponse(_ data: Data, _ response: HTTPURLResponse) throws {
        logDebug("Response Status: \(response.statusCode) for URL: \(response.url?.absoluteString ?? "unknown")")
        logResponseBody(data)
        
        guard (200...299).contains(response.statusCode) else {
            switch response.statusCode {
            case 401, 403:
                throw handleAuthenticationError(response, data: data)
            case 404:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Endpoint not found"
                logDebug("Endpoint not found: \(errorMessage)")
                throw APIError.malformedEndpoint("Endpoint not found: \(response.url?.path ?? "unknown path")")
            default:
                throw APIError.invalidResponse
            }
        }
    }
}

// Extension to get all headers from URLRequest
private extension URLRequest {
    var allHTTPHeaders: [String: String] {
        allHTTPHeaderFields ?? [:]
    }
} 

