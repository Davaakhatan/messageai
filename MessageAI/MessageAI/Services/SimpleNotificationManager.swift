import Foundation
import UserNotifications
import Combine

/// Simple, reliable notification manager for foreground notifications
class SimpleNotificationManager: ObservableObject {
    static let shared = SimpleNotificationManager()
    
    private init() {
        setupNotificationCategories()
    }
    
    // MARK: - Setup Notification Categories
    
    private func setupNotificationCategories() {
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY_ACTION",
            title: "Reply",
            options: [],
            textInputButtonTitle: "Send",
            textInputPlaceholder: "Type your message..."
        )
        
        let markAsReadAction = UNNotificationAction(
            identifier: "MARK_READ_ACTION",
            title: "Mark as Read",
            options: []
        )
        
        let messageCategory = UNNotificationCategory(
            identifier: "MESSAGE_CATEGORY",
            actions: [replyAction, markAsReadAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([messageCategory])
    }
    
    // MARK: - Request Permission
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            if granted {
                print("✅ Notification permission granted")
                return true
            } else {
                print("❌ Notification permission denied")
                return false
            }
        } catch {
            print("❌ Error requesting notification permission: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Send Simple Notification
    
    func sendNotification(title: String, body: String, identifier: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "MESSAGE_CATEGORY"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier ?? "simple_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error sending notification: \(error.localizedDescription)")
            } else {
                print("✅ Simple notification sent: \(body)")
            }
        }
    }
    
    // MARK: - Send Message Notification
    
    func sendMessageNotification(senderName: String, message: String, chatId: String) {
        let content = UNMutableNotificationContent()
        content.title = "📱 MessageAI"
        content.body = "\(senderName): \(message)"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "MESSAGE_CATEGORY"
        content.userInfo = [
            "chatId": chatId,
            "senderName": senderName,
            "message": message
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "message_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error sending message notification: \(error.localizedDescription)")
            } else {
                print("✅ Message notification sent: \(senderName) - \(message)")
            }
        }
    }
    
    // MARK: - Clear All Notifications
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("✅ All notifications cleared")
    }
}
