import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedSegment = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Profile Header
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.secondary)
                    
                    if let user = viewModel.currentUser {
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if !user.bio.isEmpty {
                            Text(user.bio)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Stats
                    HStack(spacing: 40) {
                        VStack(spacing: 4) {
                            Text("\(viewModel.userProjects.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Proje")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(viewModel.userApplications.count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Başvuru")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
                
                // Segment Picker
                Picker("Segment", selection: $selectedSegment) {
                    Text("Projelerim").tag(0)
                    Text("Başvurularım").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if selectedSegment == 0 {
                                if viewModel.userProjects.isEmpty {
                                    EmptyStateView(
                                        icon: "folder",
                                        title: "Henüz proje yok",
                                        message: "İlk projenizi paylaşın!"
                                    )
                                    .padding(.top, 40)
                                } else {
                                    ForEach(viewModel.userProjects) { project in
                                        NavigationLink(destination: ProjectDetailView(projectId: project.id)) {
                                            ProjectCardView(project: project, onUpvote: {})
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            } else {
                                if viewModel.userApplications.isEmpty {
                                    EmptyStateView(
                                        icon: "paperplane",
                                        title: "Henüz başvuru yok",
                                        message: "Projelere başvurun!"
                                    )
                                    .padding(.top, 40)
                                } else {
                                    ForEach(viewModel.userApplications) { application in
                                        APIApplicationCard(application: application)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Profil")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .task {
                await viewModel.fetchUserData()
            }
            .refreshable {
                await viewModel.fetchUserData()
            }
        }
    }
}

struct APIApplicationCard: View {
    let application: APIApplication
    
    var category: Category {
        guard let catString = application.project?.category else { return .other }
        return Category(apiValue: catString) ?? .other
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(application.project?.title ?? "-")
                    .font(.headline)
                Spacer()
                StatusBadge(status: ApplicationStatus(rawValue: application.status.lowercased()) ?? .pending)
            }
            
            HStack {
                CategoryBadge(category: category)
                Spacer()
                Text(application.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Text("Rol: \(application.role)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

#Preview {
    ProfileView()
}
