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
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    // Header section
                    VStack(alignment: .leading) {
                        Text("Hoje")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Domingo - 5 Jan")
                            .font(.subheadline)
                            .foregroundColor(.gray)
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
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.black)
                                .cornerRadius(8)
                            }
                            .sheet(isPresented: $showingCreateTask) {
                                CreateTaskView()
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
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
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
                        .foregroundColor(.gray)
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
    
    var body: some View {
        HStack {
            Circle()
                .strokeBorder(Color.gray, lineWidth: 1.5)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .foregroundColor(.white)
                
                if let description = task.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
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
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(white: 0.1))
        .cornerRadius(8)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
} 