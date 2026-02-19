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
                } else if selectedSegment == 0 {
                    ScrollView {
                        LazyVStack(spacing: 12) {
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
                        }
                        .padding()
                    }
                } else {
                    if viewModel.userApplications.isEmpty {
                        Spacer()
                        EmptyStateView(
                            icon: "paperplane",
                            title: "Henüz başvuru yok",
                            message: "Projelere başvurun!"
                        )
                        Spacer()
                    } else {
                        List {
                            ForEach(viewModel.userApplications) { application in
                                APIApplicationCard(application: application)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        if application.status.uppercased() == "PENDING" {
                                            Button("İptal Et") {
                                                viewModel.applicationToWithdraw = application
                                            }
                                            .tint(.red)
                                        }
                                    }
                            }
                        }
                        .listStyle(.plain)
                        .confirmationDialog(
                            "Başvuruyu geri çekmek istediğinize emin misiniz?",
                            isPresented: Binding(
                                get: { viewModel.applicationToWithdraw != nil },
                                set: { if !$0 { viewModel.applicationToWithdraw = nil } }
                            ),
                            titleVisibility: .visible
                        ) {
                            Button("İptal Et", role: .destructive) {
                                if let app = viewModel.applicationToWithdraw {
                                    Task {
                                        await viewModel.withdrawApplication(app)
                                    }
                                }
                            }
                            Button("Vazgeç", role: .cancel) {
                                viewModel.applicationToWithdraw = nil
                            }
                        }
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
