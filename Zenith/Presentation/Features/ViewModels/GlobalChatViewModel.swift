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
    @Published var messages: [ChatMessage] = []
    
    func sendMessage(_ text: String) {
        let message = ChatMessage(text: text, isUser: true)
        messages.append(message)
        inputText = ""
    }
    
    func submitText() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        sendMessage(text)
        isProcessing = true
        ClaudeLLMService.shared.sendMessage(text) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                switch result {
                case .success(let reply):
                    let assistantMessage = ChatMessage(text: reply, isUser: false)
                    self?.messages.append(assistantMessage)
                case .failure(let error):
                    let errorMessage = ChatMessage(text: "[Erro: \(error.localizedDescription)]", isUser: false)
                    self?.messages.append(errorMessage)
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
