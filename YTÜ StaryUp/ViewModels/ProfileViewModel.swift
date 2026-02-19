import Foundation
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userProjects: [APIProject] = []
    @Published var userApplications: [APIApplication] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var applicationToWithdraw: APIApplication?
    
    private let api = APIService.shared
    
    var currentUser: APIUser? { api.currentUser }
    
    func fetchUserData() async {
        guard let user = currentUser else { return }
        
        if userProjects.isEmpty && userApplications.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        
        do {
            // Kullanıcı bilgilerini (kredi dahil) güncelle
            _ = await api.restoreSession()
            
            let allProjects = try await api.fetchProjects()
            userProjects = allProjects.filter { $0.owner.id == user.id }
            userApplications = try await api.fetchMyApplications()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func withdrawApplication(_ application: APIApplication) async {
        do {
            try await api.withdrawApplication(id: application.id)
            userApplications.removeAll { $0.id == application.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func logout() {
        api.logout()
    }
}
