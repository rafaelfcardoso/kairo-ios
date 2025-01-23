import SwiftUI

struct CreateTaskView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var taskName: String = ""
    @State private var taskDescription: String = ""
    @State private var selectedDate: Date = Date()
    @State private var selectedPriority: Bool = false
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.13) : .white
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : Color(white: 0.90)
    }
    
    var statusBarBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.95)
    }
    
    var modalBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.17) : Color(white: 0.94)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                modalBackgroundColor.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    TextField("Nome da tarefa", text: $taskName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(textColor)
                    
                    TextField("Descrição", text: $taskDescription)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(textColor)
                    
                    HStack {
                        Image(systemName: "calendar")
                        Text("Hoje")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(secondaryTextColor)
                    .padding()
                    .background(cardBackgroundColor)
                    .cornerRadius(8)
                    
                    HStack {
                        Image(systemName: "clock")
                        Text("Sessões")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .foregroundColor(secondaryTextColor)
                    .padding()
                    .background(cardBackgroundColor)
                    .cornerRadius(8)
                    
                    HStack {
                        Image(systemName: "flag")
                        Text("Prioridade")
                        Spacer()
                        Toggle("", isOn: $selectedPriority)
                    }
                    .foregroundColor(secondaryTextColor)
                    .padding()
                    .background(cardBackgroundColor)
                    .cornerRadius(8)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Nova Tarefa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(textColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Adicionar") {
                        // Add task logic here
                        dismiss()
                    }
                    .foregroundColor(textColor)
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(colorScheme)
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
        .background(.clear)
    }
}

struct CreateTaskView_Previews: PreviewProvider {
    static var previews: some View {
        CreateTaskView()
            .previewDisplayName("Create Task")
    }
} 