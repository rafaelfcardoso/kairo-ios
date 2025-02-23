import SwiftUI

struct UndoToastView: View {
    let message: String
    let action: () async -> Void
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var opacity: CGFloat = 0
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.15)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(message)
                .foregroundColor(.white)
                .font(.subheadline)
            
            Button {
                Task {
                    await action()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 12, weight: .medium))
                    Text("Desfazer")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 1
            }
            
            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation(.easeIn(duration: 0.2)) {
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isPresented = false
                }
            }
        }
    }
} 