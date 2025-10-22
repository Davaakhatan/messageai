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
    @StateObject private var notificationManager = ProductionNotificationManager.shared
    
    init() {
        // Configure Firebase with error handling
        FirebaseApp.configure()
        setupPushNotifications()
        // Clear all notifications immediately on app start
        clearAllNotificationsOnStart()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(messageService)
                .environmentObject(notificationManager)
                .onAppear {
                    authService.checkAuthStatus()
                    setupNotificationSystem()
                }
        }
    }
    
    private func setupPushNotifications() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        Messaging.messaging().delegate = NotificationDelegate.shared
    }
    
           private func clearAllNotificationsOnStart() {
               // Clear system notifications immediately
               UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
               UNUserNotificationCenter.current().removeAllDeliveredNotifications()
               print("✅ Cleared all notifications on app start")
           }
           
           private func setupNotificationSystem() {
               Task {
                   // Clear all old notifications first
                   notificationManager.clearAllNotifications()
                   
                   // Request notification permission
                   let granted = await notificationManager.requestNotificationPermission()
                   
                   if granted {
                       // Start listening for notifications
                       #if targetEnvironment(simulator)
                       notificationManager.startListeningForNotifications()
                       #endif
                       print("✅ Notification system initialized")
                   } else {
                       print("❌ Notification permission denied")
                   }
               }
           }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    static let shared = NotificationDelegate()
    
    // MARK: - Handle Foreground Notifications
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Always show notifications in foreground for better UX
        completionHandler([.alert, .badge, .sound])
    }
    
    // MARK: - Handle Notification Actions
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle different notification actions
        if let actionIdentifier = response.actionIdentifier as? String {
            switch actionIdentifier {
            case "REPLY_ACTION":
                handleReplyAction(response: response, userInfo: userInfo)
            case "MARK_READ_ACTION":
                handleMarkAsReadAction(userInfo: userInfo)
            case UNNotificationDefaultActionIdentifier:
                handleNotificationTap(userInfo: userInfo)
            default:
                break
            }
        }
        
        completionHandler()
    }
    
    // MARK: - Action Handlers
    
    private func handleReplyAction(response: UNNotificationResponse, userInfo: [AnyHashable: Any]) {
        if let textResponse = response as? UNTextInputNotificationResponse,
           let chatId = userInfo["chatId"] as? String {
            let replyText = textResponse.userText
            print("📝 Quick reply: \(replyText) for chat: \(chatId)")
            // Store reply for processing
            UserDefaults.standard.set(replyText, forKey: "quickReply_\(chatId)")
        }
    }
    
    private func handleMarkAsReadAction(userInfo: [AnyHashable: Any]) {
        if let notificationId = userInfo["notificationId"] as? String {
            ProductionNotificationManager.shared.markNotificationAsRead(notificationId)
        }
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        if let chatId = userInfo["chatId"] as? String {
            // Store chatId for navigation when app opens
            UserDefaults.standard.set(chatId, forKey: "pendingChatId")
            print("🔗 Navigating to chat: \(chatId)")
        }
    }
    
    // MARK: - FCM Token Handling
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        if let token = fcmToken {
            UserDefaults.standard.set(token, forKey: "fcmToken")
            // Store FCM token in Firestore for the current user
            storeFCMTokenInFirestore(token)
        }
    }
    
    private func storeFCMTokenInFirestore(_ token: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("users")
            .document(currentUserId)
            .updateData(["fcmToken": token]) { error in
                if let error = error {
                    print("❌ Error storing FCM token: \(error.localizedDescription)")
                } else {
                    print("✅ FCM token stored in Firestore")
                }
            }
    }
}
