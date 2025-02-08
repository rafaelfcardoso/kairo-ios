import SwiftUI

struct CreateProjectView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel: ProjectViewModel
    @State private var projectName: String = ""
    @State private var selectedColor: Color = .green
    @State private var isLoading = false
    @State private var error: Error?
    
    init(viewModel: ProjectViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // Predefined colors for suggestions
    let colorSuggestions: [Color] = [
        .init(hex: "FF6B6B"), // Red
        .init(hex: "4D96FF"), // Blue
        .init(hex: "51CF66"), // Green
        .init(hex: "845EF7"), // Purple
        .init(hex: "FF758F"), // Pink
        .init(hex: "339AF0"), // Light Blue
        .init(hex: "F06595"), // Hot Pink
        .init(hex: "FFA94D")  // Orange
    ]
    
    var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryBackgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.95)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 24) {
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nome")
                            .foregroundColor(.gray)
                            .font(.system(size: 15))
                        
                        TextField("", text: $projectName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 17))
                            .foregroundColor(textColor)
                            .padding()
                            .background(secondaryBackgroundColor)
                            .cornerRadius(12)
                            .disabled(isLoading)
                    }
                    
                    // Color Picker
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            ColorPicker("", selection: $selectedColor)
                                .labelsHidden()
                                .disabled(isLoading)
                            
                            ForEach(colorSuggestions, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 30, height: 30)
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                                    .disabled(isLoading)
                            }
                        }
                    }
                    
                    if let error = error {
                        Text("Erro ao criar projeto: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Spacer()
                }
                .padding()
                
                if isLoading {
                    ProgressView()
                }
            }
            .navigationTitle("Novo projeto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Pronto") {
                        Task {
                            await createProject()
                        }
                    }
                    .disabled(projectName.isEmpty || isLoading)
                }
            }
        }
    }
    
    private func createProject() async {
        isLoading = true
        error = nil
        
        do {
            // Convert Color to hex string
            let components = selectedColor.cgColor?.components ?? [0, 0, 0, 1]
            let r = Int(components[0] * 255)
            let g = Int(components[1] * 255)
            let b = Int(components[2] * 255)
            let hexColor = String(format: "#%02X%02X%02X", r, g, b)
            print("Debug: Converting color to hex: \(hexColor)")
            
            try await viewModel.createProject(name: projectName, color: hexColor)
            dismiss()
        } catch {
            self.error = error
            isLoading = false
        }
    }
}

struct CreateProjectView_Previews: PreviewProvider {
    static var previews: some View {
        CreateProjectView(viewModel: ProjectViewModel())
            .preferredColorScheme(.dark)
    }
} 