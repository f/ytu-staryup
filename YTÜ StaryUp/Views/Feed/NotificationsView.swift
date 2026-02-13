import SwiftUI
import Combine

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                if !viewModel.receivedApplications.isEmpty {
                    Section("Gelen Başvurular") {
                        ForEach(viewModel.receivedApplications) { application in
                            if let projectId = application.project?.id {
                                NavigationLink(destination: ProjectDetailView(projectId: projectId, initialTab: 1)) {
                                    ReceivedApplicationRow(application: application, viewModel: viewModel)
                                }
                            } else {
                                ReceivedApplicationRow(application: application, viewModel: viewModel)
                            }
                        }
                    }
                }
                
                if !viewModel.myApplications.isEmpty {
                    Section("Başvurularım") {
                        ForEach(viewModel.myApplications) { application in
                            if let projectId = application.project?.id {
                                NavigationLink(destination: ProjectDetailView(projectId: projectId, initialTab: 1)) {
                                    MyApplicationRow(application: application)
                                }
                            } else {
                                MyApplicationRow(application: application)
                            }
                        }
                    }
                }
                
                if viewModel.myApplications.isEmpty && viewModel.receivedApplications.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "Bildirim yok",
                        systemImage: "bell.slash",
                        description: Text("Henüz bir başvuru yok")
                    )
                }
            }
            .navigationTitle("Bildirimler")
            .refreshable {
                await viewModel.fetchApplications()
            }
            .task {
                await viewModel.fetchApplications()
            }
        }
    }
}

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var myApplications: [APIApplication] = []
    @Published var receivedApplications: [APIApplication] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let api = APIService.shared
    
    func fetchApplications() async {
        if myApplications.isEmpty && receivedApplications.isEmpty {
            isLoading = true
        }
        
        do {
            myApplications = try await api.fetchMyApplications()
            receivedApplications = try await api.fetchReceivedApplications()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateStatus(applicationId: String, status: String) async {
        do {
            _ = try await api.updateApplicationStatus(id: applicationId, status: status)
            await fetchApplications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ReceivedApplicationRow: View {
    let application: APIApplication
    @ObservedObject var viewModel: NotificationsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(application.applicant?.name ?? "Anonim")
                    .fontWeight(.medium)
                Spacer()
                StatusBadge(status: ApplicationStatus(apiValue: application.status) ?? .pending)
            }
            
            Text("Proje: \(application.project?.title ?? "-")")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("Rol: \(application.role)")
                .font(.caption)
            
            if !application.message.isEmpty {
                Text(application.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            if application.status.uppercased() == "PENDING" {
                HStack(spacing: 12) {
                    Button("Kabul Et") {
                        Task {
                            await viewModel.updateStatus(applicationId: application.id, status: "ACCEPTED")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.small)
                    
                    Button("Reddet") {
                        Task {
                            await viewModel.updateStatus(applicationId: application.id, status: "REJECTED")
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .controlSize(.small)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MyApplicationRow: View {
    let application: APIApplication
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(application.project?.title ?? "-")
                    .fontWeight(.medium)
                Spacer()
                StatusBadge(status: ApplicationStatus(apiValue: application.status) ?? .pending)
            }
            
            Text("Rol: \(application.role)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(application.createdAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NotificationsView()
}
