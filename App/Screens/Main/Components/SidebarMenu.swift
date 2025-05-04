import SwiftUI

struct SidebarMenu: View {
    @EnvironmentObject var projectViewModel: ProjectViewModel
    @ObservedObject var taskViewModel: TaskViewModel
    @Environment(\.colorScheme) var colorScheme
    @Binding var isShowingSidebar: Bool
    @Binding var selectedProject: Project?
    @State private var showingCreateProject = false
    @State private var statusBarHeight: CGFloat = 0
    @State private var showingSettingsSheet = false
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // Theme colors
    var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : .white
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : Color(hex: "7E7E7E")
    }
    
    var body: some View {
        // Only the sidebar content, without the overlay background
        // (The overlay is now handled in ZenithApp.swift)
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Get accurate status bar height
                Color.clear
                    .frame(height: 0)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(key: SafeAreaInsetKey.self, value: geo.safeAreaInsets)
                                .onAppear {
                                    let keyWindow = UIApplication.shared.connectedScenes
                                        .filter { $0.activationState == .foregroundActive }
                                        .compactMap { $0 as? UIWindowScene }
                                        .first?.windows
                                        .filter { $0.isKeyWindow }.first
                                    statusBarHeight = keyWindow?.safeAreaInsets.top ?? 47
                                }
                        }
                    )
                
                // Status bar spacer - using accurate height
                Color.clear
                    .frame(height: statusBarHeight)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(secondaryTextColor)
                    
                    Text("Pesquisar")
                        .foregroundColor(secondaryTextColor)
                    
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1)
                    .padding(.vertical, 8)
                
                // Menu items
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Home view (main page)
                        menuItem(
                            icon: "filemenu.and.selection",
                            title: "Hoje",
                            count: taskViewModel.tasks.count + taskViewModel.overdueTasks.count,
                            isSelected: selectedProject == nil
                        ) {
                            selectedProject = nil
                            withAnimation {
                                isShowingSidebar = false
                            }
                        }
                        
                        // Inbox
                        if let inboxProject = projectViewModel.projects.first(where: { $0.isSystem }) {
                            menuItem(
                                icon: "tray",
                                title: "Entrada",
                                count: inboxProject.taskCount ?? 0,
                                isSelected: selectedProject?.id == inboxProject.id
                            ) {
                                selectedProject = inboxProject
                                withAnimation {
                                    isShowingSidebar = false
                                }
                            }
                        }
                        
                        // Projects section header
                        HStack {
                            Text("PROJETOS")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(secondaryTextColor)
                            
                            Spacer()
                            
                            Button {
                                showingCreateProject = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.footnote)
                                    .foregroundColor(secondaryTextColor)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                        
                        // Projects list
                        if projectViewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding()
                        } else if projectViewModel.hasError {
                            VStack {
                                Spacer()
                                
                                VStack(spacing: 8) {
                                    Image(systemName: "wifi.slash")
                                        .font(.system(size: 30))
                                        .foregroundColor(secondaryTextColor)
                                    
                                    Text("Não foi possível carregar")
                                        .font(.subheadline)
                                        .foregroundColor(secondaryTextColor)
                                        .multilineTextAlignment(.center)
                                    
                                    Button("Tentar novamente") {
                                        loadProjects(forceRefresh: true)
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .padding(.top, 4)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                
                                Spacer()
                            }
                        } else {
                            ForEach(projectViewModel.projects.filter { !$0.isSystem }) { project in
                                menuItem(
                                    icon: "folder.fill",
                                    title: project.name,
                                    count: project.taskCount ?? 0,
                                    iconColor: Color(hex: project.color),
                                    isSelected: selectedProject?.id == project.id
                                ) {
                                    selectedProject = project
                                    withAnimation {
                                        isShowingSidebar = false
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Spacer()
                
                // User profile and settings at the bottom
                VStack(spacing: 0) {
                    // Divider before user section
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .padding(.bottom, 16)
                    
                    // User profile and settings
                    HStack {
                        // User avatar
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(secondaryTextColor)
                            )
                        
                        Text(authViewModel.userName.isEmpty ? "Usuário" : authViewModel.userName)
                            .font(.headline)
                            .foregroundColor(textColor)
                        
                        Spacer()
                        
                        // Settings button
                        Button {
                            showingSettingsSheet = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(secondaryTextColor)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .frame(width: min(geometry.size.width * 0.85, 350))
            .background(backgroundColor)
            .ignoresSafeArea()
        }
        .frame(maxWidth: UIScreen.main.bounds.width * 0.85)
        .sheet(isPresented: $showingCreateProject) {
            CreateProjectView(viewModel: projectViewModel)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsSheet(authViewModel: authViewModel, isShowing: $showingSettingsSheet, onLogout: {
                // This will be set by the parent (ZenithApp)
                NotificationCenter.default.post(name: .userDidLogout, object: nil)
            })
        }
        .onAppear {
            // Load projects when sidebar appears, but use caching
            loadProjects(forceRefresh: false)
        }
        .onChange(of: isShowingSidebar) { _, newValue in
            // When sidebar is shown, ensure projects are loaded
            if newValue {
                loadProjects(forceRefresh: false)
            }
        }
        .onPreferenceChange(SafeAreaInsetKey.self) { insets in
            statusBarHeight = insets.top
        }
    }
    
    // Preference key for safe area insets
    struct SafeAreaInsetKey: PreferenceKey {
        static var defaultValue: EdgeInsets = EdgeInsets()
        static func reduce(value: inout EdgeInsets, nextValue: () -> EdgeInsets) {
            value = nextValue()
        }
    }
    
    private func loadProjects(forceRefresh: Bool) {
        Task {
            do {
                try await projectViewModel.loadProjects(forceRefresh: forceRefresh)
            } catch {
                print("Error loading projects in sidebar: \(error)")
            }
        }
    }
    
    @ViewBuilder
    private func menuItem(icon: String, title: String, count: Int? = nil, iconColor: Color? = nil, isSelected: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor ?? (isSelected ? AppTheme.shared.activeColor : secondaryTextColor))
                    .frame(width: 28)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? AppTheme.shared.activeColor : textColor)
                
                Spacer()
                
                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(secondaryTextColor)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
            .background(isSelected ? Color.gray.opacity(0.2) : Color.clear)
            .cornerRadius(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).edgesIgnoringSafeArea(.all)
        
        SidebarMenu(taskViewModel: TaskViewModel(), isShowingSidebar: .constant(true), selectedProject: .constant(nil))
            .environmentObject(ProjectViewModel())
            .environmentObject(AuthViewModel())
    }
}

import Foundation
extension Notification.Name {
    static let userDidLogout = Notification.Name("userDidLogout")
}