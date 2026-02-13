import Foundation
import Combine

@MainActor
class ProjectDetailViewModel: ObservableObject {
    @Published var projectDetail: APIProjectDetail?
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var showApplySheet = false
    @Published var applyRole = ""
    @Published var applyMessage = ""
    
    private let api = APIService.shared
    
    var currentUser: APIUser? { api.currentUser }
    
    func fetchProjectDetail(id: String) async {
        if projectDetail == nil {
            isLoading = true
        }
        errorMessage = nil
        
        do {
            projectDetail = try await api.fetchProject(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func isOwner(of project: APIProject) -> Bool {
        guard let currentUser = currentUser else { return false }
        return project.owner.id == currentUser.id
    }
    
    func isOwnerOfDetail() -> Bool {
        guard let currentUser = currentUser, let detail = projectDetail else { return false }
        return detail.owner.id == currentUser.id
    }
    
    func hasApplied() -> Bool {
        guard let currentUser = currentUser, let detail = projectDetail else { return false }
        return detail.applications.contains { $0.applicant.id == currentUser.id }
    }
    
    func apply(to projectId: String) async {
        guard !applyRole.isEmpty else {
            errorMessage = "Rol belirtmeniz gerekiyor"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await api.applyToProject(projectId: projectId, role: applyRole, message: applyMessage)
            showApplySheet = false
            applyRole = ""
            applyMessage = ""
            // Refresh project detail to show updated applications
            await fetchProjectDetail(id: projectId)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateApplicationStatus(_ applicationId: String, status: String, projectId: String) async {
        do {
            _ = try await api.updateApplicationStatus(id: applicationId, status: status)
            // Refresh project detail
            await fetchProjectDetail(id: projectId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func toggleUpvote(projectId: String) async {
        do {
            _ = try await api.toggleUpvote(projectId: projectId)
            // Refresh project detail
            await fetchProjectDetail(id: projectId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
