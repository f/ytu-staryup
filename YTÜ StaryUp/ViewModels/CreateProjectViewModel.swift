import Foundation
import Combine

@MainActor
class CreateProjectViewModel: ObservableObject {
    @Published var title = ""
    @Published var descriptionText = ""
    @Published var selectedCategory: Category = .technology
    @Published var applicationCost: Double = 5
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var didCreate = false
    @Published var createdProjectId: String?
    
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
            let project = try await api.createProject(
                title: title,
                description: descriptionText,
                category: selectedCategory.apiValue,
                applicationCost: Int(applicationCost)
            )
            createdProjectId = project.id
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
        applicationCost = 5
    }
}
