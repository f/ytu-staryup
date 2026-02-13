import SwiftUI

struct CategoryBadge: View {
    let category: Category
    
    var body: some View {
        Label(category.rawValue, systemImage: category.icon)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(category.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(category.color.opacity(0.1))
            .clipShape(Capsule())
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(Category.allCases) { category in
            CategoryBadge(category: category)
        }
    }
    .padding()
}
