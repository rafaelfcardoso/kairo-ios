import SwiftUI

struct BlocksView: View {
    @StateObject private var viewModel = BlocksViewModel()
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var showingSidebar: Bool
    
    // Make AppState optional to prevent crashes in tests
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
        ZStack {
            // Background
            backgroundColor.ignoresSafeArea()
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Empty spacer to push content below navigation bar
                    Spacer()
                        .frame(height: 20)
                    
                    // Shield status card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Escudo de Bloqueio")
                                    .font(.headline)
                                    .foregroundColor(textColor)
                                
                                Text("Bloqueie distrações e mantenha o foco")
                                    .font(.subheadline)
                                    .foregroundColor(Color.gray)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $viewModel.isShieldActive)
                                .labelsHidden()
                                .onChange(of: viewModel.isShieldActive) { oldValue, newValue in
                                    viewModel.toggleShield()
                                }
                        }
                        
                        if viewModel.isShieldActive {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Escudo Ativo")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.green)
                                    
                                    Text("\(viewModel.activeBlockCount) bloqueios configurados")
                                        .font(.caption)
                                        .foregroundColor(Color.gray)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    // Open shield settings
                                    viewModel.openSettings()
                                }) {
                                    Text("Configurar")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding()
                    .background(cardBackgroundColor)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 5, x: 0, y: 2)
                    
                    // Profiles section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Perfis de Bloqueio")
                            .font(.headline)
                            .foregroundColor(textColor)
                        
                        ForEach(viewModel.vpnConfiguration.profiles) { profile in
                            BlockingProfileCard(
                                profile: profile,
                                isActive: viewModel.vpnConfiguration.activeProfileId == profile.id,
                                onActivate: {
                                    viewModel.activateProfile(profile)
                                },
                                onEdit: {
                                    // Edit profile action
                                }
                            )
                        }
                        
                        Button(action: {
                            // Add new profile action
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Adicionar Perfil")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(cardBackgroundColor)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 5, x: 0, y: 2)
                    
                    // Rules section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Regras de Bloqueio")
                            .font(.headline)
                            .foregroundColor(textColor)
                        
                        ForEach(viewModel.vpnConfiguration.defaultRules) { rule in
                            BlockingRuleCard(
                                rule: rule,
                                onToggle: {
                                    // Toggle rule action
                                },
                                onEdit: {
                                    // Edit rule action
                                }
                            )
                        }
                        
                        Button(action: {
                            // Add new rule action
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Adicionar Regra")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(cardBackgroundColor)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 8)
            }
        }
        .navigationTitle("Blocos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingSidebar = true
                        HapticManager.shared.impact(style: .medium)
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                        .foregroundColor(textColor)
                        .padding(.horizontal, 4)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                settingsButton
                    .padding(.horizontal, 4)
            }
        }
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

// Supporting views
struct BlockingProfileCard: View {
    let profile: BlockingProfile
    let isActive: Bool
    let onActivate: () -> Void
    let onEdit: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.subheadline.bold())
                    .foregroundColor(textColor)
                
                Text(profile.description)
                    .font(.caption)
                    .foregroundColor(Color.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isActive {
                Text("Ativo")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            } else {
                Button(action: onActivate) {
                    Text("Ativar")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(8)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6).opacity(0.5))
        .cornerRadius(8)
    }
}

struct BlockingRuleCard: View {
    let rule: BlockingRule
    let onToggle: () -> Void
    let onEdit: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var categoryColor: Color {
        switch rule.category {
        case .socialMedia:
            return .blue
        case .entertainment:
            return .purple
        case .news:
            return .orange
        case .shopping:
            return .green
        case .productivity:
            return .red
        case .custom:
            return .gray
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(rule.name)
                        .font(.subheadline.bold())
                        .foregroundColor(textColor)
                    
                    Text(rule.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.2))
                        .foregroundColor(categoryColor)
                        .cornerRadius(4)
                }
                
                Text(rule.pattern)
                    .font(.caption)
                    .foregroundColor(Color.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: .constant(rule.isActive))
                .labelsHidden()
                .onChange(of: rule.isActive) { oldValue, newValue in
                    onToggle()
                }
            
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(8)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6).opacity(0.5))
        .cornerRadius(8)
    }
}

// Preview provider
struct BlocksView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                BlocksView(showingSidebar: .constant(false))
                    .environmentObject(ProjectViewModel())
                    .environmentObject(AppState())
            }
            .preferredColorScheme(.light)
            
            NavigationView {
                BlocksView(showingSidebar: .constant(false))
                    .environmentObject(ProjectViewModel())
                    .environmentObject(AppState())
            }
            .preferredColorScheme(.dark)
        }
    }
} 