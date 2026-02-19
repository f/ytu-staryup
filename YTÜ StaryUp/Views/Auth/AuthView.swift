import SwiftUI

struct AuthView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var isLoginMode = true
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Logo & Title
                VStack(spacing: 16) {
                    SVGLogoView(fillColor: "#000000", animated: false)
                        .frame(height: 40)
                        .padding(.horizontal, 60)
                    
                    Text("Fikirlerini paylaş, ekip bul")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Mode Picker
                Picker("Mod", selection: $isLoginMode) {
                    Text("Giriş Yap").tag(true)
                    Text("Kayıt Ol").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Form
                VStack(spacing: 16) {
                    if !isLoginMode {
                        TextField("Ad Soyad", text: $authViewModel.name)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)
                            .autocorrectionDisabled()
                    }
                    
                    TextField("E-posta", text: $authViewModel.email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    SecureField("Şifre", text: $authViewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(isLoginMode ? .password : .newPassword)
                }
                .padding(.horizontal)
                
                // Error Message
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Submit Button
                Button {
                    Task {
                        if isLoginMode {
                            await authViewModel.login()
                        } else {
                            await authViewModel.register()
                        }
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(isLoginMode ? "Giriş Yap" : "Kayıt Ol")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .disabled(authViewModel.isLoading)
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }
}

#Preview {
    AuthView(authViewModel: AuthViewModel())
}
