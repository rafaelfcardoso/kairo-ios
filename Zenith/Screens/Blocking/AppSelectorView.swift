import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

struct AppSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selection = FamilyActivitySelection()
    @State private var isAuthorized = false
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var onSelectionComplete: (FamilyActivitySelection) -> Void
    
    var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : Color(hex: "7E7E7E")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                Text("Selecione os aplicativos e sites que você deseja bloquear durante suas sessões de foco.")
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if isAuthorized {
                    // App Selection UI
                    FamilyActivityPicker(selection: $selection)
                        .frame(height: 400)
                } else {
                    // Authorization needed UI
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .padding(.bottom, 8)
                        
                        Text("Permissão Necessária")
                            .font(.title2.bold())
                            .foregroundColor(textColor)
                        
                        Text("O Zenith precisa de permissão para configurar o Tempo de Uso a fim de bloquear aplicativos e sites durante suas sessões de foco.")
                            .font(.subheadline)
                            .foregroundColor(secondaryTextColor)
                            .multilineTextAlignment(.center)
                        
                        Button {
                            requestAuthorization()
                        } label: {
                            Text("Permitir Acesso")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Save button
                if isAuthorized {
                    Button {
                        saveSelection()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Salvar Seleção")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(isSaving)
                }
            }
            .padding(.vertical)
            .background(backgroundColor)
            .navigationTitle("Bloquear Distrações")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            .alert("Erro", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                checkAuthorization()
            }
        }
    }
    
    // Check if Screen Time authorization is already granted
    private func checkAuthorization() {
        Task {
            isAuthorized = await ScreenTimeBlockingService.shared.checkAuthorization()
        }
    }
    
    // Request Screen Time authorization
    private func requestAuthorization() {
        Task {
            isAuthorized = await ScreenTimeBlockingService.shared.requestAuthorization()
        }
    }
    
    // Save the selected apps/websites
    private func saveSelection() {
        isSaving = true
        
        // Use the completion handler to pass the selection back
        onSelectionComplete(selection)
        
        // Dismiss this view
        dismiss()
    }
} 