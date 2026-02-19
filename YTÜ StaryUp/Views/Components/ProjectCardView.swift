import SwiftUI

struct ProjectCardView: View {
    let project: APIProject
    var isUpvoting: Bool = false
    let onUpvote: () -> Void
    
    var category: Category {
        Category(rawValue: project.category.lowercased().capitalized) ?? 
        Category(apiValue: project.category) ?? .other
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                CategoryBadge(category: category)
                Spacer()
                Text(project.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            // Title & Description
            Text(project.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(project.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            
            // Footer
            HStack {
                // Owner
                HStack(spacing: 4) {
                    Image(systemName: "person.circle.fill")
                        .font(.caption)
                    Text(project.owner.name)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                
                Spacer()
                
                // Application cost
                if let cost = project.applicationCost, cost > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "star.circle.fill")
                            .font(.caption2)
                        Text("\(cost)")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.orange)
                }
                
                // Applications count
                HStack(spacing: 4) {
                    Image(systemName: "person.badge.plus")
                        .font(.caption)
                    Text("\(project.applicationCount)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                
                // Upvote
                Button(action: onUpvote) {
                    HStack(spacing: 4) {
                        if isUpvoting {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.caption.weight(.bold))
                        }
                        Text("\(project.upvoteCount)")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(project.upvoteCount > 0 ? .orange : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(project.upvoteCount > 0 ? Color.orange.opacity(0.1) : Color(.systemGray6))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isUpvoting)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
}

#Preview {
    ProjectCardView(
        project: APIProject(
            id: "1",
            title: "AI Destekli Öğrenci Asistanı",
            description: "Üniversite öğrencileri için yapay zeka destekli bir asistan uygulaması.",
            category: "TECHNOLOGY",
            applicationCost: 10,
            createdAt: Date(),
            owner: APIProjectOwner(id: "1", name: "Test User", avatarURL: nil),
            upvoteCount: 5,
            applicationCount: 3,
            upvotedByIds: []
        ),
        onUpvote: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
