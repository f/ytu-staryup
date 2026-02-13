import Foundation
import SwiftData
import Combine

@MainActor
class MockAPIService: ObservableObject {
    static let shared = MockAPIService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private let userIdKey = "savedUserId"
    
    private init() {}
    
    // MARK: - Session Persistence
    
    private func saveSession() {
        guard let userId = currentUser?.id else { return }
        UserDefaults.standard.set(userId.uuidString, forKey: userIdKey)
    }
    
    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: userIdKey)
    }
    
    func restoreSession(context: ModelContext) async -> Bool {
        guard let userIdString = UserDefaults.standard.string(forKey: userIdKey),
              let userId = UUID(uuidString: userIdString) else {
            return false
        }
        
        let descriptor = FetchDescriptor<User>()
        do {
            let users = try context.fetch(descriptor)
            if let user = users.first(where: { $0.id == userId }) {
                currentUser = user
                isAuthenticated = true
                return true
            }
        } catch {
            print("Failed to restore session: \(error)")
        }
        
        clearSession()
        return false
    }
    
    // MARK: - Auth
    
    func login(email: String, password: String, context: ModelContext) async throws -> User {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        
        let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.email == email })
        let users = try context.fetch(descriptor)
        
        guard let user = users.first else {
            throw AuthError.userNotFound
        }
        
        currentUser = user
        isAuthenticated = true
        saveSession()
        return user
    }
    
    func register(email: String, password: String, name: String, context: ModelContext) async throws -> User {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.email == email })
        let existingUsers = try context.fetch(descriptor)
        
        guard existingUsers.isEmpty else {
            throw AuthError.emailAlreadyExists
        }
        
        let user = User(email: email, name: name)
        context.insert(user)
        try context.save()
        
        currentUser = user
        isAuthenticated = true
        saveSession()
        return user
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        clearSession()
    }
    
    // MARK: - Projects
    
    func fetchProjects(category: Category? = nil, context: ModelContext) async throws -> [Project] {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        var descriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        
        if let category = category {
            let categoryRaw = category.rawValue
            descriptor.predicate = #Predicate { $0.categoryRaw == categoryRaw }
        }
        
        return try context.fetch(descriptor)
    }
    
    func createProject(title: String, description: String, category: Category, context: ModelContext) async throws -> Project {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard let owner = currentUser else {
            throw AuthError.notAuthenticated
        }
        
        let project = Project(title: title, descriptionText: description, category: category, owner: owner)
        context.insert(project)
        try context.save()
        
        return project
    }
    
    func toggleUpvote(project: Project, context: ModelContext) async throws {
        guard let user = currentUser else {
            throw AuthError.notAuthenticated
        }
        
        project.toggleUpvote(by: user)
        try context.save()
    }
    
    // MARK: - Applications
    
    func applyToProject(_ project: Project, role: String, message: String, context: ModelContext) async throws -> Application {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard let applicant = currentUser else {
            throw AuthError.notAuthenticated
        }
        
        let application = Application(project: project, applicant: applicant, role: role, message: message)
        context.insert(application)
        try context.save()
        
        return application
    }
    
    func updateApplicationStatus(_ application: Application, status: ApplicationStatus, context: ModelContext) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
        
        application.status = status
        try context.save()
    }
}

enum AuthError: LocalizedError {
    case userNotFound
    case emailAlreadyExists
    case notAuthenticated
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .userNotFound: return "Kullanıcı bulunamadı"
        case .emailAlreadyExists: return "Bu e-posta zaten kayıtlı"
        case .notAuthenticated: return "Giriş yapmanız gerekiyor"
        case .invalidCredentials: return "Geçersiz kimlik bilgileri"
        }
    }
}
