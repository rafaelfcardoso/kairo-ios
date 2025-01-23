import SwiftUI

struct CreateTaskView: View {
    @Environment(\.dismiss) var dismiss
    @State private var taskName: String = ""
    @State private var taskDescription: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedPriority: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Nome da tarefa", text: $taskName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .foregroundColor(.white)
                
                TextField("Descrição", text: $taskDescription)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .foregroundColor(.white)
                
                HStack {
                    Image(systemName: "calendar")
                    Text("Hoje")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.gray)
                .padding()
                .background(Color(white: 0.1))
                .cornerRadius(8)
                
                HStack {
                    Image(systemName: "clock")
                    Text("Sessões")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.gray)
                .padding()
                .background(Color(white: 0.1))
                .cornerRadius(8)
                
                HStack {
                    Image(systemName: "flag")
                    Text("Prioridade")
                    Spacer()
                    Toggle("", isOn: $selectedPriority)
                }
                .foregroundColor(.gray)
                .padding()
                .background(Color(white: 0.1))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
            .background(Color.black)
            .navigationTitle("Nova Tarefa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Adicionar") {
                        // Add task logic here
                        dismiss()
                    }
                }
            }
        }
    }
} 