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
    
    var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : Color(white: 0.95)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    ProgressView()
                } else if hasError {
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
                    ScrollView {
                        VStack(spacing: 24) {
                            // Projects Section Header
                            HStack {
                                Text("Projetos")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(textColor)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingCreateProject = true
                                }) {
                                    Image(systemName: "plus")
                                        .foregroundColor(textColor)
                                        .font(.system(size: 20))
                                }
                            }
                            .padding(.horizontal)
                            .sheet(isPresented: $showingCreateProject) {
                                CreateProjectView(viewModel: viewModel)
                            }
                            
                            if viewModel.projects.isEmpty {
                                Text("Nenhum projeto encontrado")
                                    .foregroundColor(secondaryTextColor)
                                    .padding()
                            } else {
                                // Projects List Block
                                VStack(spacing: 0) {
                                    ForEach(viewModel.projects) { project in
                                        if viewModel.projects.firstIndex(where: { $0.id == project.id }) != 0 {
                                            Divider()
                                                .padding(.leading, 56)
                                                .padding(.trailing, 16)
                                        }
                                        
                                        projectRow(project: project)
                                            .padding(.vertical, 8)
                                            .if(viewModel.projects.first?.id == project.id) { view in
                                                view.padding(.top, 4)
                                            }
                                            .if(viewModel.projects.last?.id == project.id) { view in
                                                view.padding(.bottom, 4)
                                            }
                                    }
                                }
                                .background(cardBackgroundColor)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                    }
                    .refreshable {
                        await loadProjects()
                    }
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if isLoading {
                    await loadProjects()
                }
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
        NavigationLink(destination: EmptyView()) {
            HStack(spacing: 16) {
                Image(systemName: "folder.fill")
                    .foregroundColor(Color(hex: project.color))
                    .font(.system(size: 20))
                
                Text(project.name)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(secondaryTextColor)
                    .font(.system(size: 14))
            }
            .padding(.horizontal)
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