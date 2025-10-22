import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import UserNotifications

@main
struct MessageAIApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var messageService = MessageService()
    
    init() {
        // Configure Firebase with error handling
        FirebaseApp.configure()
        setupPushNotifications()
    }
    
           var body: some Scene {
               WindowGroup {
                   ContentView()
                       .environmentObject(authService)
                       .environmentObject(messageService)
                       .environmentObject(SimulatorNotificationManager.shared)
                       .onAppear {
                           authService.checkAuthStatus()
                           #if targetEnvironment(simulator)
                           SimulatorNotificationManager.shared.startListeningForNotifications()
                           #endif
                       }
               }
           }
    
    private func setupPushNotifications() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        Messaging.messaging().delegate = NotificationDelegate.shared
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap - navigate to specific chat
        let userInfo = response.notification.request.content.userInfo
        if let chatId = userInfo["chatId"] as? String {
            // Store chatId for navigation when app opens
            UserDefaults.standard.set(chatId, forKey: "pendingChatId")
        }
        completionHandler()
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        // Store FCM token for the user
        if let token = fcmToken {
            UserDefaults.standard.set(token, forKey: "fcmToken")
        }
    }
}
