import Foundation
import SwiftData

enum ApplicationStatus: String, Codable {
    case pending = "Beklemede"
    case accepted = "Kabul Edildi"
    case rejected = "Reddedildi"
    
    init?(apiValue: String) {
        switch apiValue.uppercased() {
        case "PENDING": self = .pending
        case "ACCEPTED": self = .accepted
        case "REJECTED": self = .rejected
        default: return nil
        }
    }
}

@Model
final class Application {
    @Attribute(.unique) var id: UUID
    var role: String
    var message: String
    var statusRaw: String
    var createdAt: Date
    
    var project: Project?
    var applicant: User?
    
    var status: ApplicationStatus {
        get { ApplicationStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }
    
    init(
        id: UUID = UUID(),
        project: Project? = nil,
        applicant: User? = nil,
        role: String,
        message: String = "",
        status: ApplicationStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.project = project
        self.applicant = applicant
        self.role = role
        self.message = message
        self.statusRaw = status.rawValue
        self.createdAt = createdAt
    }
}
