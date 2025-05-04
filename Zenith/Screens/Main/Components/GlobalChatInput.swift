import SwiftUI
import AVFoundation
import Combine

// Add @MainActor to ensure all code runs on the main thread
@MainActor
class GlobalChatViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var isRecording = false
    @Published var isFocused = false
    @Published var isExpanded = false
    @Published var keyboardHeight: CGFloat = 0
    @Published var keyboardAnimationDuration: Double = 0.25
    @Published var isProcessing = false
    @Published var chatMessages: [ChatMessage] = []
    
    // Animation properties
    @Published var animationPhase = 0
    
    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
    }
    
    private var audioRecorder: AVAudioRecorder?
    private var cancellables = Set<AnyCancellable>()
    private var taskViewModel: TaskViewModel?
    private var createTaskUseCase: CreateTaskUseCase?
    
    init(taskViewModel: TaskViewModel? = nil, createTaskUseCase: CreateTaskUseCase? = nil) {
        self.taskViewModel = taskViewModel
        self.createTaskUseCase = createTaskUseCase
        
        // Simplified keyboard handling with debouncing
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main) // Increased debounce time
            .receive(on: RunLoop.main) // Ensure updates happen on main thread
            .sink { [weak self] notification in
                guard let self = self else { return }
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                   let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
                   let _ = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
                    
                    // Add 1 point to ensure there's no gap
                    self.keyboardHeight = keyboardFrame.height + 1
                    self.keyboardAnimationDuration = duration
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main) // Increased debounce time
            .receive(on: RunLoop.main) // Ensure updates happen on main thread
            .sink { [weak self] notification in
                guard let self = self else { return }
                if let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
                   let _ = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
                    
                    self.keyboardHeight = 0
                    self.keyboardAnimationDuration = duration
                }
            }
            .store(in: &cancellables)
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            // Get the documents directory
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsDirectory.appendingPathComponent("recording.m4a")
            
            // Settings for the recorder
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // Initialize the recorder
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            
            withAnimation {
                isRecording = true
            }
            
            // Start animation for recording indicator
            startAnimationLoop()
            
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        
        // Process the recording - in a real app, you'd send this to your speech-to-text service
        // For now, we'll just simulate adding some text
        DispatchQueue.main.async {
            self.inputText = "What can I help you with today?"
        }
    }
    
    private func startAnimationLoop() {
        // Only start if recording
        guard isRecording else { return }
        
        // Loop through animation phases
        withAnimation(.easeInOut(duration: 0.5)) {
            animationPhase = (animationPhase + 1) % 3
        }
        
        // Continue the loop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startAnimationLoop()
        }
    }
    
    func toggleExpanded() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isExpanded.toggle()
        }
    }
    
    func submitText() {
        guard !inputText.isEmpty else { return }
        
        let textToProcess = inputText
        inputText = ""
        isProcessing = true
        isExpanded = true // Always expand chat on send
        // Add user message to chat
        chatMessages.append(ChatMessage(text: textToProcess, isUser: true))
        // Send to Claude
        ClaudeLLMService.shared.sendMessage(textToProcess) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isProcessing = false
                switch result {
                case .success(let reply):
                    self.chatMessages.append(ChatMessage(text: reply, isUser: false))
                case .failure(let error):
                    self.chatMessages.append(ChatMessage(text: "[Error: \(error.localizedDescription)]", isUser: false))
                }
            }
        }
    }
    
    // Method to dismiss keyboard
    func dismissKeyboard() {
        // Ensure we're on the main thread
        Task { @MainActor in
            isFocused = false
            // Hide keyboard using UIKit
            DispatchQueue.main.async {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}

struct GlobalChatInput: View {
    @ObservedObject var viewModel: GlobalChatViewModel
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    
    // Initialize with TaskViewModel for natural language processing
    init(viewModel: GlobalChatViewModel) {
        self.viewModel = viewModel
    }
    
    private var pillBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : .white
    }
    
    private var containerBackgroundColor: Color {
        // Using system background color for consistency
        colorScheme == .dark ? .black : Color(.systemGray6)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var placeholderColor: Color {
        colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.6)
    }
    
    private var iconColor: Color {
        colorScheme == .dark ? Color(white: 0.7) : Color(white: 0.5)
    }
    
    private var separatorColor: Color {
        Color.gray.opacity(0.2)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Add top padding to avoid overlapping the toolbar/navigation bar
            // Typical UINavigationBar height is 44, plus status bar (20), so 64 is a safe default
            // You can adjust this value if your toolbar is custom or larger
            let toolbarHeight: CGFloat = 64

            // Chat messages list
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.chatMessages) { message in
                            HStack {
                                if message.isUser { Spacer() }
                                Text(message.text)
                                    .padding(10)
                                    .background(message.isUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                                    .foregroundColor(message.isUser ? .blue : .primary)
                                    .cornerRadius(10)
                                if !message.isUser { Spacer() }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                }
                .padding(.top, toolbarHeight)
                .onChange(of: viewModel.chatMessages.count) { _ in
                    withAnimation { proxy.scrollTo(viewModel.chatMessages.last?.id, anchor: .bottom) }
                }
            }
            // Input container with background
            VStack(spacing: 0) {
                // Main chat input
                HStack(spacing: 12) {
                    // Input pill that contains both the text field and microphone
                    ZStack {
                        // Background pill
                        RoundedRectangle(cornerRadius: 18)
                            .fill(pillBackgroundColor)
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                        
                        // Input and microphone layout
                        HStack(spacing: 8) {
                            // Input field or placeholder
                            ZStack(alignment: .leading) {
                                if viewModel.inputText.isEmpty && !viewModel.isRecording {
                                    Text("Ask anything...")
                                        .foregroundColor(placeholderColor)
                                        .padding(.leading, 6)
                                        .font(.subheadline)
                                }
                                
                                if viewModel.isRecording {
                                    // Recording indicator
                                    HStack(spacing: 8) {
                                        ForEach(0..<3) { i in
                                            Circle()
                                                .fill(Color.red.opacity(viewModel.animationPhase == i ? 1.0 : 0.3))
                                                .frame(width: 4, height: 4)
                                        }
                                        
                                        Text("Listening...")
                                            .foregroundColor(Color.red)
                                            .font(.caption)
                                    }
                                    .padding(.leading, 8)
                                } else {
                                    // Use a binding that's explicitly tied to the main actor
                                    let inputBinding = Binding<String>(
                                        get: { self.viewModel.inputText },
                                        set: { self.viewModel.inputText = $0 }
                                    )
                                    
                                    TextField("", text: inputBinding)
                                        .padding(.leading, 6)
                                        .foregroundColor(textColor)
                                        .font(.subheadline)
                                        .focused($isFocused)
                                        .onChange(of: isFocused) { _, newValue in
                                            // Ensure this runs on the main thread
                                            Task { @MainActor in
                                                viewModel.isFocused = newValue
                                                
                                                if newValue {
                                                    // Delay the animation slightly to avoid competing with keyboard animation
                                                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        viewModel.isExpanded = true
                                                    }
                                                }
                                            }
                                        }
                                        .submitLabel(.send) // Use send button on keyboard
                                        .onSubmit {
                                            viewModel.submitText()
                                        }
                                        // Add this to improve keyboard responsiveness
                                        .autocorrectionDisabled(true)
                                        .textInputAutocapitalization(.never)
                                }
                            }
                            .frame(height: 36)
                            
                            Spacer()
                            
                            // Microphone, Send, or Processing button
                            Button {
                                if viewModel.isProcessing {
                                    // Do nothing while processing
                                    return
                                } else if !viewModel.inputText.isEmpty {
                                    viewModel.submitText()
                                } else if viewModel.isRecording {
                                    viewModel.stopRecording()
                                } else {
                                    viewModel.startRecording()
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(viewModel.inputText.isEmpty ? Color.clear : Color.blue)
                                        .frame(width: 28, height: 28)
                                    
                                    if viewModel.isProcessing {
                                        // Processing indicator
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: viewModel.inputText.isEmpty ? iconColor : .white))
                                            .scaleEffect(0.8)
                                    } else if viewModel.isRecording {
                                        // Stop icon
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.red)
                                            .frame(width: 10, height: 10)
                                    } else if !viewModel.inputText.isEmpty {
                                        // Send icon for text input
                                        Image(systemName: "arrow.up")
                                            .foregroundColor(.white)
                                            .font(.system(size: 14, weight: .semibold))
                                    } else {
                                        // Mic icon for voice input (non-filled version)
                                        Image(systemName: "mic")
                                            .foregroundColor(iconColor)
                                            .font(.system(size: 14))
                                    }
                                }
                                .padding(.trailing, 4)
                            }
                            .frame(width: 36, height: 36)
                            .disabled(viewModel.isProcessing)
                        }
                        .padding(.horizontal, 6)
                    }
                    .frame(height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(viewModel.isFocused ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isFocused)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .background(containerBackgroundColor)
            .clipShape(RoundedCorners(tl: 20, tr: 20, bl: 0, br: 0))
            .onTapGesture {
                // Ensure we're on the main thread and prioritize this action
                DispatchQueue.main.async {
                    if !isFocused {
                        isFocused = true
                    }
                }
            }
        }
    }
    
    // Function to dismiss keyboard that can be called from outside
    func dismissKeyboard() {
        isFocused = false
        viewModel.dismissKeyboard()
    }
}

// Extension to UIApplication for keyboard dismissal
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Helper shape for custom corner rounding
struct RoundedCorners: Shape {
    var tl: CGFloat = 0.0
    var tr: CGFloat = 0.0
    var bl: CGFloat = 0.0
    var br: CGFloat = 0.0
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                tl > 0 ? .topLeft : [],
                tr > 0 ? .topRight : [],
                bl > 0 ? .bottomLeft : [],
                br > 0 ? .bottomRight : []
            ].reduce([], { $0.union($1) }),
            cornerRadii: CGSize(width: max(max(tl, tr), max(bl, br)), height: max(max(tl, tr), max(bl, br)))
        )
        return Path(path.cgPath)
    }
}

struct GlobalChatInput_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light mode preview
            ZStack(alignment: .bottom) {
                Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    Spacer()
                    GlobalChatInput(viewModel: GlobalChatViewModel())
                    
                    // Simulate tab bar for preview
                    HStack {
                        Spacer()
                        Text("Home")
                        Spacer()
                        Text("Focus")
                        Spacer()
                        Text("Blocks")
                        Spacer()
                    }
                    .frame(height: 50)
                    .background(Color(.systemGray6))
                }
            }
            .environment(\.colorScheme, .light)
            
            // Dark mode preview
            ZStack(alignment: .bottom) {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    Spacer()
                    GlobalChatInput(viewModel: GlobalChatViewModel())
                    
                    // Simulate tab bar for preview
                    HStack {
                        Spacer()
                        Text("Home")
                            .foregroundColor(.white)
                        Spacer()
                        Text("Focus")
                            .foregroundColor(.white)
                        Spacer()
                        Text("Blocks")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .frame(height: 50)
                    .background(Color.black)
                }
            }
            .environment(\.colorScheme, .dark)
        }
    }
}