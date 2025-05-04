import SwiftUI

struct ActiveShieldStatus: View {
    @Environment(\.colorScheme) var colorScheme
    let mode: String
    let isActive: Bool
    let blockCount: Int
    let onToggle: () -> Void
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.systemGray6) : .white
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack {
                        StatusIndicator(isActive: isActive)
                        Text(isActive ? "Active" : "Inactive")
                            .foregroundColor(isActive ? .green : .secondary)
                            .font(.subheadline)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { isActive },
                    set: { _ in onToggle() }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .green))
            }
            
            Divider()
                .background(Color.gray.opacity(0.2))
            
            HStack {
                Label {
                    Text("\(blockCount) blocks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } icon: {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: {}) {
                    HStack {
                        Text("View Details")
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(12)
    }
}

struct StatusIndicator: View {
    let isActive: Bool
    
    var body: some View {
        Circle()
            .fill(isActive ? Color.green : Color.gray)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(isActive ? Color.green.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 4)
            )
    }
}

// MARK: - Preview
struct ActiveShieldStatus_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ActiveShieldStatus(
                mode: "Work Shield",
                isActive: true,
                blockCount: 12,
                onToggle: {}
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .background(Color.black)
            
            ActiveShieldStatus(
                mode: "Work Shield",
                isActive: false,
                blockCount: 12,
                onToggle: {}
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
            .background(Color.black)
        }
    }
} 