import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showLogoutAlert = false
    
    var body: some View {
        List {
            Section("Genel") {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("Hakkında", systemImage: "info.circle")
                }
            }
            
            Section("Hesap") {
                Button(role: .destructive) {
                    showLogoutAlert = true
                } label: {
                    Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Çıkış Yap", isPresented: $showLogoutAlert) {
            Button("İptal", role: .cancel) { }
            Button("Çıkış", role: .destructive) {
                authViewModel.logout()
            }
        } message: {
            Text("Çıkış yapmak istediğinize emin misiniz?")
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
