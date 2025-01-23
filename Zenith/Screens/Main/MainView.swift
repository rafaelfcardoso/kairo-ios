//
//  MainView.swift
//  Zenith
//
//  Created by Rafael Cardoso on 02/01/25.
//

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = TaskViewModel()
    @State private var showingCreateTask = false
    @Environment(\.colorScheme) var colorScheme
    
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
                
                VStack(spacing: 16) {
                    // Header section
                    VStack(alignment: .leading) {
                        Text("Hoje")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                        
                        Text("Domingo - 5 Jan")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Tasks list
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.tasks) { task in
                                TaskRow(task: task)
                            }
                            
                            Button(action: {
                                showingCreateTask = true
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Adicionar tarefa")
                                }
                                .foregroundColor(secondaryTextColor)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(cardBackgroundColor)
                                .cornerRadius(8)
                            }
                            .sheet(isPresented: $showingCreateTask) {
                                CreateTaskView()
                                    .interactiveDismissDisabled(false)
                                    .presentationBackground(
                                        colorScheme == .dark ? Color(white: 0.17) : Color(white: 0.94)
                                    )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Start focus button
                    Button(action: {
                        print("Focus Session Started")
                    }) {
                        Text("Iniciar Foco")
                            .foregroundColor(backgroundColor)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(textColor)
                            .font(.system(size: 16, weight: .semibold))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Text("Energia Mental")
                        .foregroundColor(secondaryTextColor)
                        .font(.subheadline)
                }
            }
            .onAppear {
                viewModel.fetchTasks()
            }
        }
    }
}

// Task row component
struct TaskRow: View {
    let task: Task
    @Environment(\.colorScheme) var colorScheme
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : Color(white: 0.95)
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var body: some View {
        HStack {
            Circle()
                .strokeBorder(secondaryTextColor, lineWidth: 1.5)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .foregroundColor(textColor)
                
                if let description = task.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                }
                
                HStack(spacing: 8) {
                    if let project = task.project {
                        Text(project.name)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: project.color).opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    Text(task.priority)
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(8)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .previewDisplayName("Main View")
    }
} 