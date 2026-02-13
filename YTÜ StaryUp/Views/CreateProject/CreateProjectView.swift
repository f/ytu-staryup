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
            .alert("Paylaşıldı!", isPresented: $viewModel.didCreate) {
                Button("Tamam") { }
            } message: {
                Text("Projeniz başarıyla paylaşıldı.")
            }
        }
    }
}

#Preview {
    CreateProjectView()
}
