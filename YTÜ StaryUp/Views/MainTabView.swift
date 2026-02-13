import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house.fill")
                }
                .tag(0)
            
            ExploreView()
                .tabItem {
                    Label("Keşfet", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            CreateProjectView()
                .tabItem {
                    Label("Paylaş", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            NotificationsView()
                .tabItem {
                    Label("Bildirimler", systemImage: "bell.fill")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.fill")
                }
                .tag(4)
        }
    }
}

#Preview {
    MainTabView()
}
