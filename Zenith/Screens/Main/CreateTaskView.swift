import SwiftUI

struct CreateTaskView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var taskName: String = ""
    @State private var taskDescription: String = ""
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(hex: "1F1F1F") : Color(white: 0.94)
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                TextField("Nome da tarefa", text: $taskName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20, weight: .medium, design: .default))
                    .foregroundColor(textColor)
                
                TextField("Descrição", text: $taskDescription)
                    .textFieldStyle(.plain)
                    .font(.system(size: 17, weight: .regular, design: .default))
                    .foregroundColor(textColor)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "tray")
                                Text("Entrada")
                                    .font(.system(size: 15, weight: .regular, design: .default))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(textColor)
                        }
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "calendar")
                                Text("Hoje")
                                    .font(.system(size: 15, weight: .regular, design: .default))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(textColor)
                        }
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "flag")
                                Text("Prioridade")
                                    .font(.system(size: 15, weight: .regular, design: .default))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(textColor)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

struct CreateTaskView_Previews: PreviewProvider {
    static var previews: some View {
        CreateTaskView()
            .previewDisplayName("Create Task")
    }
} 