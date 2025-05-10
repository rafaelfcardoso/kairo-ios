import Foundation
import Combine
// import ChatSession model is not needed if it's in the same module or target

class ChatSessionsViewModel: ObservableObject {
    @Published var sessions: [ChatSession] = []
    @Published var currentSession: ChatSession?
    
    // MARK: - Session Management
    func startNewSession() {
        let newSession = ChatSession(title: "New Chat")
        sessions.insert(newSession, at: 0)
        currentSession = newSession
    }
    
    func selectSession(_ session: ChatSession) {
        currentSession = session
    }
    
    func appendMessage(_ message: ChatMessage) {
        guard let idx = sessions.firstIndex(where: { $0.id == currentSession?.id }) else { return }
        sessions[idx].messages.append(message)
        currentSession = sessions[idx]
    }
    
    func deleteSession(_ session: ChatSession) {
        sessions.removeAll { $0.id == session.id }
        if currentSession?.id == session.id {
            currentSession = sessions.first
        }
    }
    
    // MARK: - (Optional) Persistence
    func loadSessions() {
        // Placeholder for loading from UserDefaults or disk
    }
    
    func saveSessions() {
        // Placeholder for saving to UserDefaults or disk
    }
}
