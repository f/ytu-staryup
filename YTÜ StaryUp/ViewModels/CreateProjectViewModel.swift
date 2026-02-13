import Foundation
import Combine

@MainActor
class CreateProjectViewModel: ObservableObject {
    @Published var title = ""
    @Published var descriptionText = ""
    @Published var selectedCategory: Category = .technology
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didCreate = false
    
    private let api = APIService.shared
    
    func createProject() async {
        guard !title.isEmpty else {
            errorMessage = "Proje başlığı gerekli"
            return
        }
        
        guard !descriptionText.isEmpty else {
            errorMessage = "Proje açıklaması gerekli"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await api.createProject(
                title: title,
                description: descriptionText,
                category: selectedCategory.apiValue
            )
            didCreate = true
            clearFields()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func clearFields() {
        title = ""
        descriptionText = ""
        selectedCategory = .technology
    }
}
