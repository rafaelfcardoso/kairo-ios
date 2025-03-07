import SwiftUI

struct StatisticsView: View {
    @StateObject private var viewModel = BlocksViewModel()
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @EnvironmentObject var focusSessionViewModel: FocusSessionViewModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var showingSidebar: Bool
    
    // Add optional AppState
    @EnvironmentObject private var appState: AppState
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(UIColor.systemGray6) : .white
    }
    
    var backgroundColor: Color {
        colorScheme == .dark ? .black : Color(hex: "F1F2F4")
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var body: some View {
        // Using VStack instead of ZStack for better navigation layout control
        VStack(spacing: 0) {
            // Background
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
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                .padding(.top, 24)  // Add proper top padding to avoid toolbar overlap
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .top) {
            // Add an empty spacer to ensure content respects the navigation bar
            Color.clear.frame(height: 16)  // Proper spacing for navigation bar
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationTitle("Estatísticas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                settingsButton
                    .padding(.horizontal, 4)
            }
        }
        .toolbarBackground(backgroundColor, for: .navigationBar)  // Set navigation bar background
        .toolbarBackground(.visible, for: .navigationBar)  // Make navigation bar background visible
        .refreshable {
            await viewModel.refreshData()
        }
    }
    
    private var settingsButton: some View {
        Button(action: viewModel.openSettings) {
            Image(systemName: "gear")
                .font(.title3)
                .foregroundColor(textColor)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Settings")
    }
}

// Preview provider
struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                StatisticsView(showingSidebar: .constant(false))
                    .environmentObject(ProjectViewModel())
                    .environmentObject(FocusSessionViewModel())
                    .environmentObject(AppState())
            }
            .preferredColorScheme(.light)
            
            NavigationView {
                StatisticsView(showingSidebar: .constant(false))
                    .environmentObject(ProjectViewModel())
                    .environmentObject(FocusSessionViewModel())
                    .environmentObject(AppState())
            }
            .preferredColorScheme(.dark)
        }
    }
} 