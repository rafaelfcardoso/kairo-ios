import Foundation

struct AuthResponse: Decodable {
    let accessToken: String
    let user: User

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case user
    }
}

struct User: Decodable {
    let id: String
    let email: String
    let name: String
}

enum AuthServiceError: Error, LocalizedError {
    case invalidCredentials
    case invalidResponse
    case networkError(Error)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password."
        case .invalidResponse:
            return "Invalid response from server."
        case .networkError(let error):
            return error.localizedDescription
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

class AuthService {
    static func login(email: String, password: String) async throws -> AuthResponse {
        // UI Test stub: instantly succeed if running with -UITestMockLogin
        if ProcessInfo.processInfo.arguments.contains("-UITestMockLogin") {
            let fakeToken = "UITestFakeToken"
            let response = AuthResponse(accessToken: fakeToken, user: User(id: "test-id", email: "test@example.com", name: "UITest User"))
            APIConfig.authToken = fakeToken
            return response
        }
        guard let url = URL(string: "https://zenith-api-development.up.railway.app/api/v1/auth/login") else {
            throw AuthServiceError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthServiceError.invalidResponse
            }
            switch httpResponse.statusCode {
            case 200:
                let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                APIConfig.authToken = authResponse.accessToken
                return authResponse
            case 401:
                throw AuthServiceError.invalidCredentials
            default:
                throw AuthServiceError.invalidResponse
            }
        } catch let error as AuthServiceError {
            throw error
        } catch {
            throw AuthServiceError.networkError(error)
        }
    }
}
