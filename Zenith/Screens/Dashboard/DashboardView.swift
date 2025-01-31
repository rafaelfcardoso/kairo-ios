import SwiftUI

struct DashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showingCreateProject = false
    
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
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Project list items
                        Group {
                            projectRow(icon: "doc.text", title: "Linkedin Posts", color: .blue)
                            projectRow(icon: "planet", title: "Zenith", color: .purple)
                            projectRow(icon: "folder", title: "Notas", color: .yellow)
                            projectRow(icon: "lightbulb", title: "Ideas", color: .orange)
                            projectRow(icon: "doc.text", title: "Pitch", color: .gray)
                            projectRow(icon: "house", title: "Personal Home", color: .green)
                            projectRow(icon: "checkmark", title: "Task List", color: .blue)
                        }
                        
                        // Add project button
                        Button(action: {
                            showingCreateProject = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Novo projeto")
                            }
                            .foregroundColor(secondaryTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(cardBackgroundColor)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private func projectRow(icon: String, title: String, color: Color) -> some View {
        NavigationLink(destination: EmptyView()) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20))
                
                Text(title)
                    .foregroundColor(textColor)
                
                Spacer()
                
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
                    Image(systemName: "calendar.day.timeline.left")
                    Text("Hoje")
                }
        }
    }
} 