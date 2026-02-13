import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var upvotingProjectId: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category Filter
                CategoryFilterView(selectedCategory: $viewModel.selectedCategory) { category in
                    Task {
                        await viewModel.filterByCategory(category)
                    }
                }
                
                // Sort Toggle
                HStack {
                    Text(viewModel.sortByUpvotes ? "En Popüler" : "En Yeni")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button {
                        viewModel.sortByUpvotes.toggle()
                        Task {
                            await viewModel.fetchProjects()
                        }
                    } label: {
                        Image(systemName: viewModel.sortByUpvotes ? "flame.fill" : "clock.fill")
                            .foregroundStyle(viewModel.sortByUpvotes ? .orange : .blue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Projects List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.sortedProjects.isEmpty {
                    Spacer()
                    EmptyStateView(
                        icon: "lightbulb",
                        title: "Henüz proje yok",
                        message: "İlk fikri sen paylaş!"
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.sortedProjects) { project in
                                NavigationLink(destination: ProjectDetailView(projectId: project.id)) {
                                    ProjectCardView(
                                        project: project,
                                        isUpvoting: upvotingProjectId == project.id
                                    ) {
                                        Task {
                                            upvotingProjectId = project.id
                                            await viewModel.toggleUpvote(project: project)
                                            upvotingProjectId = nil
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await viewModel.fetchProjects()
                    }
                }
            }
            .navigationTitle("StaryUp")
            .task {
                await viewModel.fetchProjects()
            }
        }
    }
}

#Preview {
    FeedView()
}
