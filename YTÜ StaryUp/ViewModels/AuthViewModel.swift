import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    private let api = APIService.shared
    
    var currentUser: APIUser? { api.currentUser }
    
    func restoreSession() async {
        isLoading = true
        let restored = await api.restoreSession()
        if restored {
            isAuthenticated = true
        }
        isLoading = false
    }
    
    func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "E-posta ve şifre gerekli"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await api.login(email: email, password: password)
            isAuthenticated = true
            clearFields()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func register() async {
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty else {
            errorMessage = "Tüm alanları doldurun"
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Şifre en az 6 karakter olmalı"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await api.register(email: email, password: password, name: name)
            isAuthenticated = true
            clearFields()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logout() {
        api.logout()
        isAuthenticated = false
    }
    
    private func clearFields() {
        email = ""
        password = ""
        name = ""
    }
}
