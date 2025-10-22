import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingLogin = false
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var messageService: MessageService
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatListView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "message.fill" : "message")
                    Text("Chats")
                }
                .tag(0)
                .badge(messageService.unreadCount)
            
            SmartSearchView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                    Text("Search")
                }
                .tag(1)
            
            RemoteTeamAIView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "person.3.fill" : "person.3")
                    Text("Team AI")
                }
                .tag(2)
            
            AIAssistantView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "brain.head.profile.fill" : "brain.head.profile")
                    Text("AI Assistant")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.circle.fill" : "person.circle")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
        .environmentObject(MessageService())
}
