import SwiftUI

struct MinimizedFocusSession: View {
    @Environment(\.colorScheme) private var colorScheme
    let taskTitle: String
    let progress: Double
    let remainingTime: TimeInterval
    let blockDistractions: Bool
    let onExpand: () -> Void
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : .white
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : Color(hex: "7E7E7E")
    }
    
    var formattedTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        Button(action: onExpand) {
            VStack(spacing: 0) {
                // Main content
                HStack(spacing: 12) {
                    // Task info and time
                    VStack(alignment: .leading, spacing: 2) {
                        Text(taskTitle)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(textColor)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            Text(formattedTime)
                                .font(.caption.monospacedDigit())
                                .foregroundColor(secondaryTextColor)
                            
                            if blockDistractions {
                                HStack(spacing: 4) {
                                    Image(systemName: "moon.fill")
                                        .font(.caption)
                                    Text("Modo Foco")
                                        .font(.caption)
                                }
                                .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(height: 2)
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * progress, height: 2)
                    }
                }
                .frame(height: 2)
            }
            .background(backgroundColor)
            .overlay(
                Rectangle()
                    .fill(Color(UIColor.separator))
                    .frame(height: 0.5)
                    .opacity(0.5),
                alignment: .top
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sessão de foco em andamento: \(taskTitle)")
        .accessibilityValue("Tempo restante: \(formattedTime)")
        .accessibilityHint("Toque duas vezes para expandir a sessão")
    }
} 