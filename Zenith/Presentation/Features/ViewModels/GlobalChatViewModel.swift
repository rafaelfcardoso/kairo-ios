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
    
    // Add any additional logic or dependencies you need here
    // For now, this is a minimal real implementation
    
    func submitText() {
        // Add your send/submit logic here
        inputText = ""
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
