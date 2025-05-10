import SwiftUI
import Combine

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

struct GlobalChatInput: View {
    @ObservedObject var viewModel: GlobalChatViewModel
    var onSend: ((String) -> Void)? = nil
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    
    // Initialize with TaskViewModel for natural language processing
    init(viewModel: GlobalChatViewModel, onSend: ((String) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onSend = onSend
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
                            HStack(spacing: 3) {
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
                                        
                                        // Expand chat input when focused
                                        if newValue && !viewModel.isExpanded {
                                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                viewModel.isExpanded = true
                                            }
                                        }
                                    }
                                }
                                .submitLabel(.send) // Use send button on keyboard
                                .onSubmit {
                                    let text = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !text.isEmpty else { return }
                                    print("[GlobalChatInput] onSubmit with text: \(text)")
                                    if let onSend = onSend {
                                        onSend(text)
                                        viewModel.inputText = ""
                                    } else {
                                        print("[GlobalChatInput] onSubmit fallback to viewModel.submitText()")
                                        viewModel.submitText()
                                    }
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
                            let text = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !text.isEmpty else { return }
                            print("[GlobalChatInput] Send button tapped with text: \(text)")
                            if let onSend = onSend {
                                onSend(text)
                                viewModel.inputText = ""
                            } else {
                                print("[GlobalChatInput] Send button fallback to viewModel.submitText()")
                                viewModel.submitText()
                            }
                        
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
                            } else if viewModel.isRecording {
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
        .background(containerBackgroundColor)
        .clipShape(RoundedCorners(tl: 20, tr: 20, bl: 0, br: 0))
        .simultaneousGesture(
            TapGesture().onEnded {
                DispatchQueue.main.async {
                    if !isFocused {
                        isFocused = true
                    }
                }
            }
        )
    }
    
    // Function to dismiss keyboard that can be called from outside
    func dismissKeyboard() {
        isFocused = false
        viewModel.dismissKeyboard()
    }
}