import SwiftUI

struct UnifiedToolbar: View {
    let title: String
    var subtitle: String? = nil
    let onSidebarTap: () -> Void
    var trailing: AnyView? = nil
    var textColor: Color = .primary
    var backgroundColor: Color = Color(.systemBackground)
    var showDivider: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Button(action: onSidebarTap) {
                Image(systemName: "line.3.horizontal")
                    .font(.title3)
                    .foregroundColor(textColor)
            }
            .accessibilityLabel("Open sidebar")
            
            Spacer()
            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .id(title) // animate on title change
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.45), value: title)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(textColor.opacity(0.7))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            Spacer()
            if let trailing = trailing {
                trailing
            } else {
                Spacer().frame(width: 32) // Placeholder for alignment
            }
        }
            .padding(.horizontal, 16)
            .frame(height: 56, alignment: .center)
            .background(backgroundColor.ignoresSafeArea(edges: .top))
    }
}
