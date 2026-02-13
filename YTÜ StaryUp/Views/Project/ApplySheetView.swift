import SwiftUI

// Note: ApplySheetView is now integrated into APIApplySheetView in ProjectDetailView.swift
// This file can be removed or kept for reference

struct ApplySheetView: View {
    @Environment(\.dismiss) private var dismiss
    let projectId: String
    let projectTitle: String
    @ObservedObject var viewModel: ProjectDetailViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(projectTitle)
                        .font(.headline)
                } header: {
                    Text("Proje")
                }
                
                Section {
                    TextField("Örn: iOS Developer, UI Designer", text: $viewModel.applyRole)
                } header: {
                    Text("Rol")
                } footer: {
                    Text("Bu projede hangi rolde yer almak istiyorsunuz?")
                }
                
                Section {
                    TextEditor(text: $viewModel.applyMessage)
                        .frame(minHeight: 100)
                } header: {
                    Text("Mesaj (Opsiyonel)")
                } footer: {
                    Text("Kendinizi tanıtın, neden bu projede yer almak istediğinizi açıklayın.")
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Başvuru")
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
                    .disabled(viewModel.applyRole.isEmpty || viewModel.isLoading)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ApplySheetView(
        projectId: "1",
        projectTitle: "Test Project",
        viewModel: ProjectDetailViewModel()
    )
}
