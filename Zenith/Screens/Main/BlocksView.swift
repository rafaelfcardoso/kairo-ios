import SwiftUI

struct BlocksView: View {
    @StateObject private var viewModel = BlocksViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.systemGray6) : .white
    }
    
    var backgroundColor: Color {
        colorScheme == .dark ? .black : Color(hex: "F1F2F4")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                InsightsDashboard(
                    focusScore: viewModel.focusScore,
                    focusTrend: viewModel.focusTrend,
                    screenTime: viewModel.screenTime,
                    protectedTime: viewModel.protectedTime,
                    timeDistribution: viewModel.timeDistribution
                )
                .background(cardBackgroundColor)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 5, x: 0, y: 2)
                
                ActiveShieldStatus(
                    mode: viewModel.currentMode,
                    isActive: viewModel.isShieldActive,
                    blockCount: viewModel.activeBlockCount,
                    onToggle: viewModel.toggleShield
                )
                .background(cardBackgroundColor)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 5, x: 0, y: 2)
                
                StatisticsCards(
                    blocksToday: viewModel.blocksToday,
                    blocksTrend: viewModel.blocksTrend,
                    savedTime: viewModel.savedTime,
                    savedTimeTrend: viewModel.savedTimeTrend
                )
            }
            .padding()
        }
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .navigationTitle("Blocks")
        .navigationBarItems(trailing: settingsButton)
        .refreshable {
            await viewModel.refreshData()
        }
    }
    
    private var settingsButton: some View {
        Button(action: viewModel.openSettings) {
            Image(systemName: "gear")
                .foregroundColor(.primary)
        }
    }
}

// Preview provider
struct BlocksView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                BlocksView()
            }
            .preferredColorScheme(.light)
            
            NavigationView {
                BlocksView()
            }
            .preferredColorScheme(.dark)
        }
    }
} 