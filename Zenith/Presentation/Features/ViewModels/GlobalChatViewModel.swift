import Foundation
import SwiftUI
import Combine

@MainActor
class GlobalChatViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var isRecording: Bool = false
    @Published var isFocused: Bool = false
    @Published var isExpanded: Bool = false
    @Published var isProcessing: Bool = false
    @Published var animationPhase: Int = 0
    // Remove local messages: chat sessions are now managed by ChatSessionsViewModel
    
    // Reference to the sessions view model (should be injected from parent/app coordinator)
    var chatSessionsViewModel: ChatSessionsViewModel?
    
    // Callback to trigger UI transition to NewChatScreen
    var onStartNewChat: (() -> Void)?
    
    /// Start a new chat session with the user's prompt
    func startNewChatSession(with prompt: String) {
        guard let sessionsVM = chatSessionsViewModel else { return }
        let userMessage = ChatMessage(text: prompt, isUser: true)
        let session = ChatSession(title: "New Chat", messages: [userMessage])
        sessionsVM.sessions.insert(session, at: 0)
        sessionsVM.currentSession = session
        inputText = ""
        // Optionally trigger UI transition
        onStartNewChat?()
        // Send prompt to LLM and append AI response to session
        isProcessing = true
        ClaudeLLMService.shared.sendMessage(prompt) { [weak self, weak sessionsVM] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let idx = sessionsVM?.sessions.firstIndex(where: { $0.id == session.id }) {
                    switch result {
                    case .success(let reply):
                        let assistantMessage = ChatMessage(text: reply, isUser: false)
                        sessionsVM?.sessions[idx].messages.append(assistantMessage)
                        sessionsVM?.currentSession = sessionsVM?.sessions[idx]
                    case .failure(let error):
                        let errorMessage = ChatMessage(text: "[Erro: \(error.localizedDescription)]", isUser: false)
                        sessionsVM?.sessions[idx].messages.append(errorMessage)
                        sessionsVM?.currentSession = sessionsVM?.sessions[idx]
                    }
                }
            }
        }
    }

    /// Called when the user presses send/submit in the global chat input
    func submitText() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        startNewChatSession(with: text)
    }
    
    /// Appends a message to the current session and sends it to the LLM (for use in NewChatScreen)
    func sendMessageToCurrentSession(_ text: String) {
        guard let sessionsVM = chatSessionsViewModel, var session = sessionsVM.currentSession else {
            print("[Chat] No current session or sessionsVM when sending message.")
            return
        }
        print("[Chat] Sending user message to current session: \(text)")
        let userMessage = ChatMessage(text: text, isUser: true)
        if let idx = sessionsVM.sessions.firstIndex(where: { $0.id == session.id }) {
            sessionsVM.sessions[idx].messages.append(userMessage)
            sessionsVM.currentSession = sessionsVM.sessions[idx]
            print("[Chat] Appended user message to session \(session.id)")
        } else {
            print("[Chat] Could not find session index for id: \(session.id)")
        }
        inputText = ""
        isProcessing = true
        ClaudeLLMService.shared.sendMessage(text) { [weak self, weak sessionsVM] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                guard let sessionsVM = sessionsVM else {
                    print("[Chat] sessionsVM was nil in Claude response handler")
                    return
                }
                if let idx = sessionsVM.sessions.firstIndex(where: { $0.id == session.id }) {
                    switch result {
                    case .success(let reply):
                        let assistantMessage = ChatMessage(text: reply, isUser: false)
                        sessionsVM.sessions[idx].messages.append(assistantMessage)
                        sessionsVM.currentSession = sessionsVM.sessions[idx]
                        print("[Chat] Appended Claude reply to session \(session.id): \(reply)")
                    case .failure(let error):
                        let errorMessage = ChatMessage(text: "[Erro: \(error.localizedDescription)]", isUser: false)
                        sessionsVM.sessions[idx].messages.append(errorMessage)
                        sessionsVM.currentSession = sessionsVM.sessions[idx]
                        print("[Chat] Claude error: \(error.localizedDescription)")
                    }
                } else {
                    print("[Chat] Could not find session index for id: \(session.id) in Claude response handler")
                }
            }
        }
    }
    
    func startRecording() {
        isRecording = true
    }
    
    func stopRecording() {
        isRecording = false
    }
    
    func dismissKeyboard() {
        isFocused = false
    }
}
