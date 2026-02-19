import SwiftUI

struct CreateProjectView: View {
    @StateObject private var viewModel = CreateProjectViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Proje başlığı", text: $viewModel.title)
                } header: {
                    Text("Başlık")
                }
                
                Section {
                    Picker("Kategori", selection: $viewModel.selectedCategory) {
                        ForEach(Category.allCases) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                } header: {
                    Text("Kategori")
                }
                
                Section {
                    TextEditor(text: $viewModel.descriptionText)
                        .frame(minHeight: 150)
                } header: {
                    Text("Açıklama")
                } footer: {
                    Text("Projenizi detaylı açıklayın. Ne yapmak istiyorsunuz? Hangi becerilere ihtiyacınız var?")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Başvuru Maliyeti")
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "star.circle.fill")
                                    .foregroundStyle(.orange)
                                Text("\(Int(viewModel.applicationCost))")
                                    .fontWeight(.bold)
                                    .foregroundStyle(.orange)
                            }
                        }
                        Slider(value: $viewModel.applicationCost, in: 0...100, step: 1)
                            .tint(.orange)
                    }
                } header: {
                    Text("Kredi")
                } footer: {
                    Text(viewModel.applicationCost == 0
                         ? "Ücretsiz başvuru — herkes başvurabilir."
                         : "Başvuru yapmak için \(Int(viewModel.applicationCost)) kredi gerekecek.")
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await viewModel.createProject()
                        }
                    } label: {
                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Paylaş")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .navigationTitle("Yeni Proje")
            .navigationDestination(isPresented: Binding(
                get: { viewModel.createdProjectId != nil && !viewModel.didCreate },
                set: { if !$0 { viewModel.createdProjectId = nil } }
            )) {
                if let projectId = viewModel.createdProjectId {
                    ProjectDetailView(projectId: projectId)
                }
            }
            .alert("Paylaşıldı!", isPresented: $viewModel.didCreate) {
                Button("Tamam") {
                    viewModel.didCreate = false
                }
            } message: {
                Text("Projeniz başarıyla paylaşıldı.")
            }
        }
    }
}

#Preview {
    CreateProjectView()
}
