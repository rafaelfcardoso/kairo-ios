import SwiftUI

struct InsightsDashboard: View {
    @Environment(\.colorScheme) var colorScheme
    let focusScore: Double
    let focusTrend: Double
    let screenTime: TimeInterval
    let protectedTime: TimeInterval
    let timeDistribution: (focused: Double, neutral: Double, distracted: Double)
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.systemGray6) : .white
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Focus Score
            HStack {
                CircularProgressView(progress: focusScore)
                    .frame(width: 80, height: 80)
                
                VStack(alignment: .leading) {
                    Text("Focus Score")
                        .font(.headline)
                        .foregroundColor(.primary)
                    HStack {
                        Text("\(Int(focusScore * 100))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        TrendIndicator(value: focusTrend)
                    }
                }
                Spacer()
            }
            .padding()
            .background(cardBackgroundColor)
            .cornerRadius(12)
            
            // Metrics Cards
            HStack(spacing: 12) {
                MetricCard(
                    title: "Screen Time",
                    value: screenTime.formatAsHoursAndMinutes(),
                    icon: "hourglass",
                    backgroundColor: cardBackgroundColor
                )
                
                MetricCard(
                    title: "Protected Time",
                    value: protectedTime.formatAsHoursAndMinutes(),
                    icon: "shield.fill",
                    backgroundColor: cardBackgroundColor
                )
            }
            
            // Time Distribution
            VStack(alignment: .leading, spacing: 8) {
                Text("Time Distribution")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TimeDistributionBar(distribution: timeDistribution)
                
                HStack {
                    LegendItem(color: .green, label: "Focused", value: timeDistribution.focused)
                    LegendItem(color: .yellow, label: "Neutral", value: timeDistribution.neutral)
                    LegendItem(color: .red, label: "Distracted", value: timeDistribution.distracted)
                }
            }
            .padding()
            .background(cardBackgroundColor)
            .cornerRadius(12)
        }
    }
}

// MARK: - Supporting Views
struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let backgroundColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
    }
}

struct TimeDistributionBar: View {
    let distribution: (focused: Double, neutral: Double, distracted: Double)
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green)
                    .frame(width: geometry.size.width * distribution.focused)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.yellow)
                    .frame(width: geometry.size.width * distribution.neutral)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.red)
                    .frame(width: geometry.size.width * distribution.distracted)
            }
        }
        .frame(height: 8)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let value: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
            Text("\(Int(value * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct TrendIndicator: View {
    let value: Double
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: value >= 0 ? "arrow.up.right" : "arrow.down.right")
            Text("\(abs(Int(value * 100)))%")
        }
        .foregroundColor(value >= 0 ? .green : .red)
        .font(.subheadline)
    }
}

// MARK: - Helper Extensions
extension TimeInterval {
    func formatAsHoursAndMinutes() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Preview
struct InsightsDashboard_Previews: PreviewProvider {
    static var previews: some View {
        InsightsDashboard(
            focusScore: 0.85,
            focusTrend: 0.12,
            screenTime: 14400,
            protectedTime: 7200,
            timeDistribution: (0.6, 0.3, 0.1)
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 