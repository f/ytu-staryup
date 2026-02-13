import Foundation
import SwiftUI
import Combine

enum Category: String, Codable, CaseIterable, Identifiable {
    case technology = "Teknoloji"
    case social = "Sosyal"
    case finance = "Finans"
    case health = "Sağlık"
    case education = "Eğitim"
    case entertainment = "Eğlence"
    case other = "Diğer"
    
    var id: String { rawValue }
    
    /// API value for sending to backend (English uppercase)
    var apiValue: String {
        switch self {
        case .technology: return "TECHNOLOGY"
        case .social: return "SOCIAL"
        case .finance: return "FINANCE"
        case .health: return "HEALTH"
        case .education: return "EDUCATION"
        case .entertainment: return "ENTERTAINMENT"
        case .other: return "OTHER"
        }
    }
    
    var icon: String {
        switch self {
        case .technology: return "laptopcomputer"
        case .social: return "person.3.fill"
        case .finance: return "banknote.fill"
        case .health: return "heart.fill"
        case .education: return "book.fill"
        case .entertainment: return "gamecontroller.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .technology: return .blue
        case .social: return .purple
        case .finance: return .green
        case .health: return .red
        case .education: return .orange
        case .entertainment: return .pink
        case .other: return .gray
        }
    }
    
    // Initialize from API category string (e.g., "TECHNOLOGY")
    init?(apiValue: String) {
        switch apiValue.uppercased() {
        case "TECHNOLOGY": self = .technology
        case "SOCIAL": self = .social
        case "FINANCE": self = .finance
        case "HEALTH": self = .health
        case "EDUCATION": self = .education
        case "ENTERTAINMENT": self = .entertainment
        case "OTHER": self = .other
        default: return nil
        }
    }
}
