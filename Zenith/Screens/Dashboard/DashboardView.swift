import SwiftUI

struct DashboardErrorView: View {
    let secondaryTextColor: Color
    let textColor: Color
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundColor(secondaryTextColor)
            
            Text("Não foi possível carregar os projetos")
                .font(.headline)
                .foregroundColor(textColor)
            
            Text("Verifique sua conexão e tente novamente")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
                .multilineTextAlignment(.center)
            
            Button(action: retryAction) {
                Text("Tentar novamente")
                    .foregroundColor(.blue)
            }
            .padding(.top, 8)
        }
        .padding()
    }
}

struct DashboardView: View {
    @StateObject private var viewModel = ProjectViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var showingCreateProject = false
    @State private var isLoading = true
    @State private var hasError = false
    @State private var expandedProjects = true
    
    var backgroundColor: Color {
        colorScheme == .dark ? .black : Color(hex: "F1F2F4")
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        Color(hex: "7E7E7E")
    }
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : .white
    }
    
    var activeColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var inactiveColor: Color {
        Color(hex: "7E7E7E")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Inbox Card
                            if let inboxProject = viewModel.projects.first(where: { $0.isSystem }) {
                                NavigationLink(destination: InboxView()) {
                                    HStack {
                                        Image(systemName: "tray")
                                            .font(.system(size: 20))
                                            .foregroundColor(inactiveColor)
                                        
                                        Text("Entrada")
                                            .font(.headline)
                                            .foregroundColor(activeColor)
                                        
                                        Spacer()
                                        
                                        if let taskCount = inboxProject.taskCount {
                                            Text("\(taskCount)")
                                                .foregroundColor(inactiveColor)
                                                .font(.system(.subheadline, design: .rounded))
                                        }
                                    }
                                    .padding()
                                    .background(cardBackgroundColor)
                                    .cornerRadius(12)
                                }
                            }
                            
                            // Projects Section
                            VStack(spacing: 8) {
                                // Header
                                HStack {
                                    Text("Projetos")
                                        .font(.headline)
                                        .foregroundColor(activeColor)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        expandedProjects.toggle()
                                    }) {
                                        Image(systemName: expandedProjects ? "chevron.down" : "chevron.right")
                                            .foregroundColor(inactiveColor)
                                    }
                                    
                                    Button(action: {
                                        showingCreateProject = true
                                    }) {
                                        Image(systemName: "plus")
                                            .foregroundColor(activeColor)
                                    }
                                }
                                .padding(.horizontal)
                                
                                if expandedProjects {
                                    if hasError {
                                        DashboardErrorView(
                                            secondaryTextColor: secondaryTextColor,
                                            textColor: textColor,
                                            retryAction: {
                                                Task {
                                                    await loadProjects()
                                                }
                                            }
                                        )
                                    } else {
                                        // Projects List (excluding Inbox)
                                        ForEach(viewModel.projects.filter { !$0.isSystem }) { project in
                                            projectRow(project: project)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadProjects()
            }
            .sheet(isPresented: $showingCreateProject) {
                CreateProjectView(viewModel: viewModel)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func loadProjects() async {
        isLoading = true
        hasError = false
        
        do {
            try await viewModel.loadProjects()
            isLoading = false
        } catch {
            isLoading = false
            hasError = true
            print("Error loading projects: \(error)")
        }
    }
    
    @ViewBuilder
    private func projectRow(project: Project) -> some View {
        NavigationLink(destination: ProjectTasksView(project: project)) {
            HStack(spacing: 16) {
                Image(systemName: "folder.fill")
                    .foregroundColor(Color(hex: project.color))
                    .font(.system(size: 20))
                
                Text(project.name)
                    .foregroundColor(textColor)
                
                Spacer()
                
                if let taskCount = project.taskCount {
                    Text("\(taskCount)")
                        .foregroundColor(secondaryTextColor)
                        .font(.system(.subheadline, design: .rounded))
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(secondaryTextColor)
                    .font(.system(size: 14))
            }
            .padding()
            .background(cardBackgroundColor)
            .cornerRadius(12)
        }
    }
}

// Extension to conditionally apply modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "rectangle.stack.fill")
                    Text("Dashboard")
                }
            
            MainView()
                .tabItem {
                    Image(systemName: "filemenu.and.selection")
                    Text("Hoje")
                }
        }
    }
} 