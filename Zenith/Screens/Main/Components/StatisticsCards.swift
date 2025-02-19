import SwiftUI

struct StatisticsCards: View {
    let blocksToday: Int
    let blocksTrend: Double
    let savedTime: TimeInterval
    let savedTimeTrend: Double
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Blocks Today",
                value: "\(blocksToday)",
                trend: blocksTrend,
                icon: "shield.slash.fill"
            )
            
            StatCard(
                title: "Saved Time",
                value: savedTime.formatAsHoursAndMinutes(),
                trend: savedTimeTrend,
                icon: "clock.fill"
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let trend: Double
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            TrendBadge(value: trend)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct TrendBadge: View {
    let value: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: value >= 0 ? "arrow.up.right" : "arrow.down.right")
            Text("\(abs(Int(value * 100)))% vs yesterday")
        }
        .font(.caption)
        .foregroundColor(value >= 0 ? .green : .red)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            (value >= 0 ? Color.green : Color.red)
                .opacity(0.1)
                .cornerRadius(8)
        )
    }
}

// MARK: - Preview
struct StatisticsCards_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StatisticsCards(
                blocksToday: 45,
                blocksTrend: 0.15,
                savedTime: 10800,
                savedTimeTrend: 0.25
            )
            .padding()
            .previewLayout(.sizeThatFits)
            
            StatisticsCards(
                blocksToday: 45,
                blocksTrend: -0.15,
                savedTime: 10800,
                savedTimeTrend: -0.25
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
        }
    }
} 