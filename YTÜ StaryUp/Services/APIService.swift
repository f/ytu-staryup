import Foundation
import Combine

extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    static let iso8601NoMillis: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case unauthorized
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Geçersiz URL"
        case .noData: return "Veri alınamadı"
        case .decodingError: return "Veri işlenemedi"
        case .serverError(let message): return message
        case .unauthorized: return "Oturum süresi doldu"
        case .networkError(let error): return error.localizedDescription
        }
    }
}

@MainActor
class APIService: ObservableObject {
    static let shared = APIService()
    
    #if DEBUG
    private let baseURL = "http://localhost:3000/api"
    #else
    private let baseURL = "https://your-production-url.com/api"
    #endif
    
    @Published var currentUser: APIUser?
    @Published var isAuthenticated = false
    
    private var token: String? {
        didSet {
            if let token = token {
                UserDefaults.standard.set(token, forKey: "authToken")
            } else {
                UserDefaults.standard.removeObject(forKey: "authToken")
            }
        }
    }
    
    private init() {
        token = UserDefaults.standard.string(forKey: "authToken")
    }
    
    // MARK: - Network Helpers
    
    private func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: Encodable? = nil) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }
        
        if httpResponse.statusCode == 401 {
            logout()
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode >= 400 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.serverError("Bir hata oluştu")
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                if let date = DateFormatter.iso8601Full.date(from: dateString) {
                    return date
                }
                if let date = DateFormatter.iso8601NoMillis.date(from: dateString) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(dateString)")
            }
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError
        }
    }
    
    private func requestVoid(_ endpoint: String, method: String = "GET", body: Encodable? = nil) async throws {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }
        
        if httpResponse.statusCode == 401 {
            logout()
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode >= 400 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.serverError("Bir hata oluştu")
        }
    }
    
    // MARK: - Auth
    
    func login(email: String, password: String) async throws -> APIUser {
        struct LoginRequest: Encodable {
            let email: String
            let password: String
        }
        
        struct LoginResponse: Decodable {
            let user: APIUser
            let token: String
        }
        
        let response: LoginResponse = try await request("/auth/login", method: "POST", body: LoginRequest(email: email, password: password))
        
        token = response.token
        currentUser = response.user
        isAuthenticated = true
        
        return response.user
    }
    
    func register(email: String, password: String, name: String) async throws -> APIUser {
        struct RegisterRequest: Encodable {
            let email: String
            let password: String
            let name: String
        }
        
        struct RegisterResponse: Decodable {
            let user: APIUser
            let token: String
        }
        
        let response: RegisterResponse = try await request("/auth/register", method: "POST", body: RegisterRequest(email: email, password: password, name: name))
        
        token = response.token
        currentUser = response.user
        isAuthenticated = true
        
        return response.user
    }
    
    func restoreSession() async -> Bool {
        guard token != nil else { return false }
        
        do {
            let user: APIUser = try await request("/auth/me")
            currentUser = user
            isAuthenticated = true
            return true
        } catch {
            logout()
            return false
        }
    }
    
    func logout() {
        token = nil
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - Projects
    
    func fetchProjects(category: String? = nil, sortBy: String? = nil) async throws -> [APIProject] {
        var endpoint = "/projects"
        var queryItems: [String] = []
        
        if let category = category {
            queryItems.append("category=\(category)")
        }
        if let sortBy = sortBy {
            queryItems.append("sortBy=\(sortBy)")
        }
        
        if !queryItems.isEmpty {
            endpoint += "?" + queryItems.joined(separator: "&")
        }
        
        return try await request(endpoint)
    }
    
    func fetchProject(id: String) async throws -> APIProjectDetail {
        return try await request("/projects/\(id)")
    }
    
    func createProject(title: String, description: String, category: String, applicationCost: Int = 5) async throws -> APIProject {
        struct CreateRequest: Encodable {
            let title: String
            let description: String
            let category: String
            let applicationCost: Int
        }
        
        return try await request("/projects", method: "POST", body: CreateRequest(title: title, description: description, category: category, applicationCost: applicationCost))
    }
    
    func toggleUpvote(projectId: String) async throws -> UpvoteResponse {
        return try await request("/projects/\(projectId)/upvote", method: "POST")
    }
    
    func updateProject(id: String, title: String, description: String, category: String, applicationCost: Int) async throws {
        struct UpdateRequest: Encodable {
            let title: String
            let description: String
            let category: String
            let applicationCost: Int
        }
        
        try await requestVoid("/projects/\(id)", method: "PATCH", body: UpdateRequest(title: title, description: description, category: category, applicationCost: applicationCost))
    }
    
    func deleteProject(id: String) async throws {
        try await requestVoid("/projects/\(id)", method: "DELETE")
    }
    
    // MARK: - Applications
    
    func applyToProject(projectId: String, role: String, message: String) async throws -> APIApplication {
        struct ApplyRequest: Encodable {
            let projectId: String
            let role: String
            let message: String
        }
        
        return try await request("/applications", method: "POST", body: ApplyRequest(projectId: projectId, role: role, message: message))
    }
    
    func fetchMyApplications() async throws -> [APIApplication] {
        return try await request("/applications/my")
    }
    
    func fetchReceivedApplications() async throws -> [APIApplication] {
        return try await request("/applications/received")
    }
    
    func updateApplicationStatus(id: String, status: String) async throws -> APIApplication {
        struct StatusRequest: Encodable {
            let status: String
        }
        
        return try await request("/applications/\(id)/status", method: "PATCH", body: StatusRequest(status: status))
    }
    
    func withdrawApplication(id: String) async throws {
        try await requestVoid("/applications/\(id)", method: "DELETE")
    }
}

// MARK: - API Models

struct ErrorResponse: Decodable {
    let error: String
}

struct APIUser: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let bio: String
    let avatarURL: String?
    let credits: Int?
    let createdAt: Date
}

struct APIProjectOwner: Codable {
    let id: String
    let name: String
    let avatarURL: String?
}

struct APIProject: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let category: String
    let applicationCost: Int?
    let createdAt: Date
    let owner: APIProjectOwner
    let upvoteCount: Int
    let applicationCount: Int
    let upvotedByIds: [String]
    
    func isUpvoted(by userId: String) -> Bool {
        upvotedByIds.contains(userId)
    }
}

struct APIProjectDetail: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let category: String
    let applicationCost: Int?
    let createdAt: Date
    let owner: APIUser
    let upvoteCount: Int
    let upvotedByIds: [String]
    let applications: [APIApplicationDetail]
}

struct APIApplicationDetail: Codable, Identifiable {
    let id: String
    let role: String
    let message: String
    let status: String
    let createdAt: Date
    let applicant: APIProjectOwner
}

struct APIApplication: Codable, Identifiable {
    let id: String
    let role: String
    let message: String
    let status: String
    let createdAt: Date
    let project: APIApplicationProject?
    let applicant: APIProjectOwner?
}

struct APIApplicationProject: Codable {
    let id: String
    let title: String
    let category: String?
}

struct UpvoteResponse: Codable {
    let upvoted: Bool
    let upvoteCount: Int
}
