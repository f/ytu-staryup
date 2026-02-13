import SwiftUI

struct ExploreView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var searchText = ""
    
    var filteredProjects: [APIProject] {
        if searchText.isEmpty {
            return viewModel.sortedProjects
        }
        return viewModel.sortedProjects.filter { project in
            project.title.localizedCaseInsensitiveContains(searchText) ||
            project.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Categories Grid
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Kategoriler")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(Category.allCases) { category in
                                    CategoryCardView(category: category) {
                                        Task {
                                            await viewModel.filterByCategory(category)
                                            withAnimation {
                                                proxy.scrollTo("results", anchor: .top)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            if viewModel.selectedCategory != nil {
                                HStack {
                                    Text("Sonuçlar: \(viewModel.selectedCategory?.rawValue ?? "")")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button("Temizle") {
                                        Task {
                                            await viewModel.filterByCategory(nil)
                                        }
                                    }
                                    .font(.caption)
                                }
                                .padding(.horizontal)
                                .padding(.top)
                                .id("results")
                                
                                if filteredProjects.isEmpty {
                                    EmptyStateView(
                                        icon: "folder",
                                        title: "Proje bulunamadı",
                                        message: "Bu kategoride henüz proje yok"
                                    )
                                    .padding(.top, 40)
                                } else {
                                    LazyVStack(spacing: 16) {
                                        ForEach(filteredProjects) { project in
                                            NavigationLink(destination: ProjectDetailView(projectId: project.id)) {
                                                ProjectCardView(project: project) {
                                                    Task {
                                                        await viewModel.toggleUpvote(project: project)
                                                    }
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Keşfet")
            .searchable(text: $searchText, prompt: "Proje ara...")
            .task {
                await viewModel.fetchProjects()
            }
        }
    }
}

struct CategoryCardView: View {
    let category: Category
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.title)
                    .foregroundStyle(category.color)
                
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(category.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    ExploreView()
}
