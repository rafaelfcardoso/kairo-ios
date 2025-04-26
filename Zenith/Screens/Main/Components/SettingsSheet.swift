import SwiftUI

struct SettingsSheet: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var isShowing: Bool
    var onLogout: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(role: .destructive) {
                        authViewModel.logout()
                        isShowing = false
                        onLogout?()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isShowing = false }
                }
            }
        }
    }
}
