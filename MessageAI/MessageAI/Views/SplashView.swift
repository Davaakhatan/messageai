import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showMainApp = false
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        if showMainApp {
            ContentView()
        } else {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // App Logo
                    VStack(spacing: 16) {
                        Image(systemName: "message.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        Text("MessageAI")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Intelligent Messaging")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Loading indicator
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        
                        Text("Initializing...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .onAppear {
                isAnimating = true
                initializeApp()
            }
        }
    }
    
    private func initializeApp() {
        // Simulate app initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showMainApp = true
            }
        }
    }
}

#Preview {
    SplashView()
        .environmentObject(AuthService())
        .environmentObject(MessageService())
}
