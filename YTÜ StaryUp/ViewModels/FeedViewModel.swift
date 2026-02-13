import Foundation
import Combine

@MainActor
class FeedViewModel: ObservableObject {
    @Published var projects: [APIProject] = []
    @Published var selectedCategory: Category?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sortByUpvotes = false
    
    private let api = APIService.shared
    
    var currentUser: APIUser? { api.currentUser }
    
    var sortedProjects: [APIProject] {
        if sortByUpvotes {
            return projects.sorted { $0.upvoteCount > $1.upvoteCount }
        }
        return projects
    }
    
    func fetchProjects() async {
        if projects.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        
        do {
            let categoryString = selectedCategory?.apiValue
            let sortBy = sortByUpvotes ? "upvotes" : nil
            projects = try await api.fetchProjects(category: categoryString, sortBy: sortBy)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func toggleUpvote(project: APIProject) async {
        do {
            _ = try await api.toggleUpvote(projectId: project.id)
            // Update the project in the list
            if projects.contains(where: { $0.id == project.id }) {
                await fetchProjects() // Refresh to get updated data
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func filterByCategory(_ category: Category?) async {
        selectedCategory = category
        await fetchProjects()
    }
}
