import Foundation
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
import Combine

class SimulatorNotificationManager: ObservableObject {
    static let shared = SimulatorNotificationManager()
    
    @Published var pendingNotifications: [SimulatorNotification] = []
    private var lastNotificationTime: Date = Date.distantPast
    private let notificationCooldown: TimeInterval = 0.5 // 0.5 seconds cooldown
    
    private init() {}
    
    // MARK: - Simulator Notification Model
    
    struct SimulatorNotification: Identifiable {
        let id = UUID().uuidString
        let senderId: String
        let senderName: String
        let message: String
        let chatId: String
        let timestamp: Date
    }
    
    // MARK: - Send Notification to Other Simulator
    
    func sendNotificationToSimulator(
        to userId: String,
        message: Message,
        senderName: String
    ) {
        // Get current user ID
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Only send if different user
        if userId != currentUserId {
            let notification = SimulatorNotification(
                senderId: currentUserId,
                senderName: senderName,
                message: message.content,
                chatId: message.chatId,
                timestamp: Date()
            )
            
            // Store notification for the TARGET user (not current user)
            self.storeNotificationForUser(userId: userId, notification: notification)
            
            print("📱 Storing notification for user: \(userId) from sender: \(currentUserId)")
        } else {
            print("⚠️ Skipping notification - same user: \(userId)")
        }
    }
    
    // MARK: - Store Notification in Firestore
    
    private func storeNotificationForUser(userId: String, notification: SimulatorNotification) {
        print("💾 Storing notification for user: \(userId)")
        print("📝 Notification content: \(notification.message)")
        
        let notificationData: [String: Any] = [
            "id": notification.id,
            "senderId": notification.senderId,
            "senderName": notification.senderName,
            "message": notification.message,
            "chatId": notification.chatId,
            "timestamp": notification.timestamp,
            "isRead": false
        ]
        
        Firestore.firestore()
            .collection("simulator_notifications")
            .document(userId)
            .collection("notifications")
            .document(notification.id)
            .setData(notificationData) { error in
                if let error = error {
                    print("❌ Error storing simulator notification: \(error.localizedDescription)")
                } else {
                    print("✅ Simulator notification stored for user: \(userId)")
                }
            }
    }
    
    // MARK: - Trigger Local Notification
    
    private func triggerLocalNotification(_ notification: SimulatorNotification) {
        let content = UNMutableNotificationContent()
        content.title = "📱 From \(notification.senderName)"
        content.body = notification.message
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "chatId": notification.chatId,
            "senderId": notification.senderId,
            "isSimulatorNotification": true
        ]
        
        let request = UNNotificationRequest(
            identifier: "sim_\(notification.id)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error triggering local notification: \(error.localizedDescription)")
            } else {
                print("✅ Local notification triggered")
            }
        }
    }
    
    // MARK: - Listen for Notifications
    
    func startListeningForNotifications() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("simulator_notifications")
            .document(currentUserId)
            .collection("notifications")
            .whereField("isRead", isEqualTo: false)
            .order(by: "timestamp", descending: true)
            .limit(to: 1) // Only get the latest notification
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error listening to notifications: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { 
                    print("📭 No notification documents found")
                    return 
                }
                
                print("📬 Received \(documents.count) notification documents")
                
                // Only process if there are new notifications
                guard !documents.isEmpty else { 
                    print("📭 No notifications to process")
                    return 
                }
                
                let notifications = documents.compactMap { doc -> SimulatorNotification? in
                    let data = doc.data()
                    guard let senderId = data["senderId"] as? String,
                          let senderName = data["senderName"] as? String,
                          let message = data["message"] as? String,
                          let chatId = data["chatId"] as? String,
                          let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
                        return nil
                    }
                    
                    return SimulatorNotification(
                        senderId: senderId,
                        senderName: senderName,
                        message: message,
                        chatId: chatId,
                        timestamp: timestamp
                    )
                }
                
                DispatchQueue.main.async {
                    self?.pendingNotifications = notifications
                    
                    // Only show the latest notification with cooldown
                    if let latestNotification = notifications.first {
                        self?.showSystemNotificationWithCooldown(latestNotification)
                    }
                }
            }
    }
    
    // MARK: - Show System Notification with Cooldown
    
    private func showSystemNotificationWithCooldown(_ notification: SimulatorNotification) {
        let now = Date()
        let timeSinceLastNotification = now.timeIntervalSince(lastNotificationTime)
        
        print("🔔 Attempting to show notification: \(notification.message)")
        print("⏰ Time since last notification: \(timeSinceLastNotification)s, cooldown: \(notificationCooldown)s")
        
        if timeSinceLastNotification < notificationCooldown {
            print("⏰ Notification cooldown active, skipping notification")
            return
        }
        
        lastNotificationTime = now
        print("✅ Cooldown passed, showing notification")
        showSystemNotification(notification)
    }
    
    // MARK: - Show System Notification
    
    private func showSystemNotification(_ notification: SimulatorNotification) {
        // Get current user ID to verify this notification is for the current user
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Only show notification if it's NOT from the current user
        if notification.senderId != currentUserId {
            let content = UNMutableNotificationContent()
            content.title = "📱 MessageAI"
            content.body = "\(notification.senderName): \(notification.message)"
            content.sound = .default
            content.badge = 1
            content.userInfo = [
                "chatId": notification.chatId,
                "senderId": notification.senderId,
                "isSimulatorNotification": true
            ]
            
            let request = UNNotificationRequest(
                identifier: "system_\(notification.id)",
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error showing system notification: \(error.localizedDescription)")
                } else {
                    print("✅ System notification shown for user: \(currentUserId) from: \(notification.senderId)")
                }
            }
        } else {
            print("⚠️ Skipping system notification - same user: \(notification.senderId)")
        }
    }
    
    // MARK: - Mark as Read
    
    func markNotificationAsRead(_ notificationId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("simulator_notifications")
            .document(currentUserId)
            .collection("notifications")
            .document(notificationId)
            .updateData(["isRead": true]) { error in
                if let error = error {
                    print("❌ Error marking notification as read: \(error.localizedDescription)")
                } else {
                    print("✅ Notification marked as read")
                }
            }
    }
    
    // MARK: - Mark All Notifications as Read for Chat
    
    func markAllNotificationsAsReadForChat(_ chatId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("simulator_notifications")
            .document(currentUserId)
            .collection("notifications")
            .whereField("chatId", isEqualTo: chatId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error getting notifications for chat: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // Mark all notifications for this chat as read
                let batch = Firestore.firestore().batch()
                for document in documents {
                    batch.updateData(["isRead": true], forDocument: document.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("❌ Error marking chat notifications as read: \(error.localizedDescription)")
                    } else {
                        print("✅ All notifications marked as read for chat: \(chatId)")
                    }
                }
            }
    }
}
