import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var settingsManager = SettingsManager.shared
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
        .preferredColorScheme(settingsManager.isDarkMode ? .dark : .light)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var messageService: MessageService
    @EnvironmentObject var notificationManager: ProductionNotificationManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatListView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "message.fill" : "message")
                    Text("Chats")
                }
                .tag(0)
                .badge(messageService.unreadCount)
            
            RemoteTeamAIView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "person.3.fill" : "person.3")
                    Text("Team AI")
                }
                .tag(1)
            
            AIAssistantView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "brain.head.profile.fill" : "brain.head.profile")
                    Text("AI Assistant")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.circle.fill" : "person.circle")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(.blue)
        .onAppear {
            // Clear all notifications when main tab view appears
            notificationManager.clearAllNotifications()
            
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
