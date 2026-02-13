import SwiftUI

struct StatusBadge: View {
    let status: ApplicationStatus
    
    var color: Color {
        switch status {
        case .pending: return .orange
        case .accepted: return .green
        case .rejected: return .red
        }
    }
    
    var icon: String {
        switch status {
        case .pending: return "clock.fill"
        case .accepted: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }
    
    var body: some View {
        Label(status.rawValue, systemImage: icon)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusBadge(status: .pending)
        StatusBadge(status: .accepted)
        StatusBadge(status: .rejected)
    }
    .padding()
}
