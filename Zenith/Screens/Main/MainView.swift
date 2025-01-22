//
//  MainView.swift
//  ProjectZenith
//
//  Created by Rafael Cardoso on 02/01/25.
//

import SwiftUI

struct MainView: View {
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
                    VStack(spacing: 12) {
                        TaskRow(title: "Reunião com Time")
                        TaskRow(title: "Documentação")
                        TaskRow(title: "Ritual Diário de Desconexão", subtitle: "Trabalho Pessoal")
                        
                        Button(action: {
                            // Add task action
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
                    }
                    .padding(.horizontal)
                    
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
        }
    }
}

// Task row component
struct TaskRow: View {
    let title: String
    var subtitle: String? = nil
    
    var body: some View {
        HStack {
            Circle()
                .strokeBorder(Color.gray, lineWidth: 1.5)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(.white)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
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

