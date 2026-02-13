import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Logo & Name
                VStack(spacing: 12) {
                    SVGLogoView(fillColor: "#000000", animated: false)
                        .frame(height: 40)
                        .padding(.horizontal, 60)
                    
                    Text("v1.0.0")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // Description
                VStack(alignment: .leading, spacing: 16) {
                    InfoSection(title: "Uygulama Hakkında") {
                        Text("YTÜ StaryUp, Yıldız Teknik Üniversitesi öğrencilerinin girişimcilik ve proje fikirlerini paylaşabilecekleri, ekip arkadaşı bulabilecekleri ve iş birliği yapabilecekleri bir platformdur.")
                    }
                    
                    InfoSection(title: "Yıldız Teknik Üniversitesi") {
                        Text("1911 yılında kurulan Yıldız Teknik Üniversitesi (YTÜ), İstanbul'un en köklü eğitim kurumlarından biridir. Beşiktaş ve Davutpaşa kampüsleriyle hizmet veren üniversite, mühendislik ve doğa bilimleri başta olmak üzere birçok alanda eğitim vermektedir.")
                    }
                    
                    InfoSection(title: "Misyonumuz") {
                        Text("YTÜ öğrencilerinin yenilikçi proje fikirlerini hayata geçirmelerine yardımcı olmak, girişimcilik ekosistemini güçlendirmek ve öğrenciler arasında iş birliğini teşvik etmek.")
                    }
                    
                    InfoSection(title: "Neler Yapabilirsiniz?") {
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "lightbulb.fill", text: "Proje fikirlerinizi paylaşın")
                            FeatureRow(icon: "person.2.fill", text: "Ekip arkadaşı bulun")
                            FeatureRow(icon: "hand.thumbsup.fill", text: "Beğendiğiniz projeleri destekleyin")
                            FeatureRow(icon: "paperplane.fill", text: "Projelere başvurun")
                            FeatureRow(icon: "magnifyingglass", text: "Kategorilere göre projeleri keşfedin")
                        }
                    }
                    
                    InfoSection(title: "İletişim") {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("staryup@yildiz.edu.tr", systemImage: "envelope.fill")
                                .font(.subheadline)
                            Label("Yıldız Teknik Üniversitesi, Beşiktaş, İstanbul", systemImage: "mappin.circle.fill")
                                .font(.subheadline)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Footer
                VStack(spacing: 4) {
                    Text("Yıldız Teknik Üniversitesi")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("© 2026 YTÜ StaryUp")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Hakkında")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            content
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 20)
            Text(text)
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
