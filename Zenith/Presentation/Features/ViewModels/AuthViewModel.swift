import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var userName: String = ""
    @Published var requiresLogin: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func login() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await AuthService.login(email: email, password: password)
            userName = response.user.name
            // Persist token (handled in AuthService)
            isLoading = false
            requiresLogin = false // Clear flag on successful login
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            requiresLogin = true // Set flag on login failure
        }
    }

    func logout() {
        APIConfig.authToken = nil
        userName = ""
        email = ""
        password = ""
        requiresLogin = true // Set flag on logout
    }
}
