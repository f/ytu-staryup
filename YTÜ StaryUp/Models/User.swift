import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var email: String
    var name: String
    var bio: String
    var avatarURL: String?
    var credits: Int
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Project.owner)
    var projects: [Project] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Application.applicant)
    var applications: [Application] = []
    
    init(id: UUID = UUID(), email: String, name: String, bio: String = "", avatarURL: String? = nil, credits: Int = 0, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.name = name
        self.bio = bio
        self.avatarURL = avatarURL
        self.credits = credits
        self.createdAt = createdAt
    }
}
