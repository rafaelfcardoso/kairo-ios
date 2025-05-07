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
        sendMessage(inputText)
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
