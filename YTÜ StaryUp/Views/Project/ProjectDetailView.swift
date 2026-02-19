import SwiftUI

struct ProjectDetailView: View {
    @StateObject private var viewModel = ProjectDetailViewModel()
    let projectId: String
    var initialTab: Int = 0
    
    @State private var selectedTab = 0
    @State private var isUpvoting = false
    
    var category: Category {
        guard let catString = viewModel.projectDetail?.category else { return .other }
        return Category(apiValue: catString) ?? .other
    }
    
    var body: some View {
        Group {
            if viewModel.projectDetail == nil && viewModel.errorMessage == nil {
                ProgressView()
            } else if let project = viewModel.projectDetail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                CategoryBadge(category: category)
                                Spacer()
                                Text(project.createdAt, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            
                            Text(project.title)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            // Owner
                            HStack(spacing: 8) {
                                Image(systemName: "person.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                
                                Text(project.owner.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Upvote Button
                        HStack(spacing: 16) {
                            UpvoteButton(
                                count: project.upvoteCount,
                                isUpvoted: viewModel.currentUser.map { project.upvotedByIds.contains($0.id) } ?? false,
                                isLoading: isUpvoting
                            ) {
                                Task {
                                    isUpvoting = true
                                    await viewModel.toggleUpvote(projectId: projectId)
                                    isUpvoting = false
                                }
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "person.badge.plus")
                                Text("\(project.applications.count) başvuru")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            
                            if let cost = project.applicationCost, cost > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.circle.fill")
                                        .foregroundStyle(.orange)
                                    Text("\(cost) kredi")
                                        .foregroundStyle(.orange)
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // Tab Selector
                        Picker("Sekme", selection: $selectedTab) {
                            Text("Hakkında").tag(0)
                            Text("İhale").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Tab Content
                        if selectedTab == 0 {
                            // About Tab
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Açıklama")
                                    .font(.headline)
                                
                                Text(project.description)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                        } else {
                            // Applications Tab
                            APIApplicationsTabView(project: project, viewModel: viewModel)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.vertical)
                }
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $viewModel.showApplySheet) {
                    APIApplySheetView(projectId: projectId, applicationCost: project.applicationCost ?? 5, viewModel: viewModel)
                }
                .overlay(alignment: .bottom) {
                    if !viewModel.isOwnerOfDetail() && !viewModel.hasApplied() {
                        let cost = project.applicationCost ?? 5
                        let userCredits = viewModel.currentUser?.credits ?? 0
                        let canAfford = userCredits >= cost || cost == 0
                        
                        VStack(spacing: 4) {
                            Button {
                                viewModel.showApplySheet = true
                            } label: {
                                HStack {
                                    Text("Başvur")
                                        .font(.headline)
                                    if cost > 0 {
                                        HStack(spacing: 3) {
                                            Image(systemName: "star.circle.fill")
                                                .font(.subheadline)
                                            Text("\(cost)")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                        }
                                        .foregroundStyle(.white.opacity(0.9))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(canAfford ? .blue : .gray)
                            .controlSize(.large)
                            .disabled(!canAfford)
                            
                            if !canAfford {
                                Text("Yetersiz kredi (Mevcut: \(userCredits))")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                    }
                }
            } else if let error = viewModel.errorMessage {
                VStack {
                    Text("Hata")
                        .font(.headline)
                    Text(error)
                        .foregroundStyle(.secondary)
                    Button("Tekrar Dene") {
                        Task {
                            await viewModel.fetchProjectDetail(id: projectId)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .task {
            selectedTab = initialTab
            await viewModel.fetchProjectDetail(id: projectId)
        }
        .refreshable {
            await viewModel.fetchProjectDetail(id: projectId)
        }
    }
}

struct APIApplicationsTabView: View {
    let project: APIProjectDetail
    @ObservedObject var viewModel: ProjectDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if project.applications.isEmpty {
                EmptyStateView(
                    icon: "person.badge.plus",
                    title: "Henüz başvuru yok",
                    message: "İlk başvuran sen ol!"
                )
                .padding(.top, 40)
            } else {
                List {
                    ForEach(project.applications) { application in
                        APIApplicationRowView(
                            application: application,
                            isOwner: viewModel.isOwnerOfDetail(),
                            projectId: project.id
                        ) { status in
                            Task {
                                await viewModel.updateApplicationStatus(application.id, status: status, projectId: project.id)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    }
                }
                .listStyle(.plain)
                .frame(minHeight: CGFloat(project.applications.count) * 100)
            }
        }
        .padding(.horizontal)
    }
}

struct APIApplicationRowView: View {
    let application: APIApplicationDetail
    let isOwner: Bool
    let projectId: String
    let onStatusChange: (String) -> Void
    
    @State private var showRejectConfirmation = false
    @State private var showAcceptConfirmation = false
    
    private var statusUpper: String { application.status.uppercased() }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(application.applicant.name)
                        .fontWeight(.medium)
                    
                    Text(application.role)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                StatusBadge(status: ApplicationStatus(apiValue: application.status) ?? .pending)
            }
            
            if !application.message.isEmpty {
                Text(application.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if isOwner && statusUpper == "PENDING" {
                HStack(spacing: 12) {
                    Button("Kabul Et") {
                        onStatusChange("ACCEPTED")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.small)
                    
                    Button("Reddet") {
                        showRejectConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .controlSize(.small)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if isOwner && statusUpper == "ACCEPTED" {
                Button("Reddet") {
                    showRejectConfirmation = true
                }
                .tint(.red)
            }
            if isOwner && statusUpper == "REJECTED" {
                Button("Kabul Et") {
                    showAcceptConfirmation = true
                }
                .tint(.green)
            }
        }
        .confirmationDialog(
            "Başvuruyu reddetmek istediğinize emin misiniz?",
            isPresented: $showRejectConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reddet", role: .destructive) {
                onStatusChange("REJECTED")
            }
            Button("İptal", role: .cancel) { }
        }
        .confirmationDialog(
            "Başvuruyu tekrar kabul etmek istediğinize emin misiniz?",
            isPresented: $showAcceptConfirmation,
            titleVisibility: .visible
        ) {
            Button("Kabul Et") {
                onStatusChange("ACCEPTED")
            }
            Button("İptal", role: .cancel) { }
        }
    }
}

struct APIApplySheetView: View {
    let projectId: String
    let applicationCost: Int
    @ObservedObject var viewModel: ProjectDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                if applicationCost > 0 {
                    Section {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .foregroundStyle(.orange)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Başvuru Maliyeti")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("Bu başvuru \(applicationCost) kredi düşecektir.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(applicationCost)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                
                Section {
                    TextField("Örn: iOS Developer, UI/UX Designer", text: $viewModel.applyRole)
                } header: {
                    Text("Rol")
                } footer: {
                    Text("Projede hangi rolü üstlenmek istiyorsunuz?")
                }
                
                Section {
                    TextEditor(text: $viewModel.applyMessage)
                        .frame(minHeight: 100)
                } header: {
                    Text("Mesaj (opsiyonel)")
                } footer: {
                    Text("Kendinizi tanıtın ve neden bu projeye katılmak istediğinizi açıklayın.")
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Başvur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gönder") {
                        Task {
                            await viewModel.apply(to: projectId)
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.applyRole.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProjectDetailView(projectId: "1")
    }
}
