import SwiftUI

struct UpvoteButton: View {
    let count: Int
    let isUpvoted: Bool
    var isLoading: Bool = false
    let action: () -> Void
    
    @State private var animationAmount: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            guard !isLoading else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                animationAmount = 1.2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    animationAmount = 1.0
                }
            }
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isUpvoted ? "arrow.up.circle.fill" : "arrow.up.circle")
                        .font(.title2)
                        .scaleEffect(animationAmount)
                }
                
                Text("\(count)")
                    .font(.headline)
            }
            .foregroundStyle(isUpvoted ? .orange : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isUpvoted ? Color.orange.opacity(0.15) : Color(.systemGray6))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        UpvoteButton(count: 42, isUpvoted: true, action: {})
        UpvoteButton(count: 0, isUpvoted: false, action: {})
    }
    .padding()
}
