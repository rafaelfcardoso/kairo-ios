import Foundation
import Combine
// import ChatSession model is not needed if it's in the same module or target

class ChatSessionsViewModel: ObservableObject {
    @Published var sessions: [ChatSession] = [] {
        didSet {
            saveSessions()
        }
    }
    @Published var currentSession: ChatSession?
    
    private let sessionsKey = "chat_sessions_v1"
    
    init() {
        loadSessions()
    }
    
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
        // sessions didSet will trigger save
    }
    
    func deleteSession(_ session: ChatSession) {
        sessions.removeAll { $0.id == session.id }
        if currentSession?.id == session.id {
            currentSession = sessions.first
        }
        // sessions didSet will trigger save
    }
    
    // MARK: - Persistence
    func loadSessions() {
        guard let data = UserDefaults.standard.data(forKey: sessionsKey) else {
            print("[ChatSessionsViewModel] No saved sessions found.")
            return
        }
        do {
            let decoded = try JSONDecoder().decode([ChatSession].self, from: data)
            self.sessions = decoded
            print("[ChatSessionsViewModel] Loaded \(decoded.count) sessions from UserDefaults.")
            // Restore currentSession if possible
            if let first = decoded.first {
                self.currentSession = first
            }
        } catch {
            print("[ChatSessionsViewModel] Failed to decode sessions: \(error)")
        }
    }
    
    func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            UserDefaults.standard.set(data, forKey: sessionsKey)
            print("[ChatSessionsViewModel] Saved \(sessions.count) sessions to UserDefaults.")
        } catch {
            print("[ChatSessionsViewModel] Failed to encode sessions: \(error)")
        }
    }
}

