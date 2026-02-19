import Foundation
import SwiftData

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var title: String
    var descriptionText: String
    var categoryRaw: String
    var applicationCost: Int
    var createdAt: Date
    var upvoteCount: Int
    var upvotedByIDs: [UUID]
    
    var owner: User?
    
    @Relationship(deleteRule: .cascade, inverse: \Application.project)
    var applications: [Application] = []
    
    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        descriptionText: String,
        category: Category,
        applicationCost: Int = 5,
        owner: User? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.categoryRaw = category.rawValue
        self.applicationCost = applicationCost
        self.owner = owner
        self.createdAt = createdAt
        self.upvoteCount = 0
        self.upvotedByIDs = []
    }
    
    func isUpvoted(by user: User) -> Bool {
        upvotedByIDs.contains(user.id)
    }
    
    func toggleUpvote(by user: User) {
        if isUpvoted(by: user) {
            upvotedByIDs.removeAll { $0 == user.id }
            upvoteCount = max(0, upvoteCount - 1)
        } else {
            upvotedByIDs.append(user.id)
            upvoteCount += 1
        }
    }
}
