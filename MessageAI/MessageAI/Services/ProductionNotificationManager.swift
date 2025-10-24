import Foundation
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
import Combine

/// Production-ready notification manager following iOS best practices
class ProductionNotificationManager: ObservableObject {
    static let shared = ProductionNotificationManager()
    
    @Published var pendingNotifications: [NotificationData] = []
    private var notificationListener: ListenerRegistration?
    private var lastNotificationTime: Date = Date.distantPast
    private let notificationCooldown: TimeInterval = 0.5 // Reduced cooldown for better responsiveness
    
    private init() {
        setupNotificationCategories()
    }
    
    deinit {
        notificationListener?.remove()
        print("🧹 ProductionNotificationManager deallocated")
    }
    
    // MARK: - Notification Data Model
    
    struct NotificationData: Identifiable, Codable {
        let id: String
        let senderId: String
        let senderName: String
        let message: String
        let chatId: String
        let timestamp: Date
        let isRead: Bool
        let type: NotificationType
        let emoji: String?
        
        enum NotificationType: String, Codable {
            case message = "message"
            case reaction = "reaction"
        }
        
        init(senderId: String, senderName: String, message: String, chatId: String, type: NotificationType = .message, emoji: String? = nil) {
            self.id = UUID().uuidString
            self.senderId = senderId
            self.senderName = senderName
            self.message = message
            self.chatId = chatId
            self.timestamp = Date()
            self.isRead = false
            self.type = type
            self.emoji = emoji
        }
        
        init(id: String, senderId: String, senderName: String, message: String, chatId: String, timestamp: Date, isRead: Bool, type: NotificationType = .message, emoji: String? = nil) {
            self.id = id
            self.senderId = senderId
            self.senderName = senderName
            self.message = message
            self.chatId = chatId
            self.timestamp = timestamp
            self.isRead = isRead
            self.type = type
            self.emoji = emoji
        }
    }
    
    // MARK: - Setup Notification Categories
    
    private func setupNotificationCategories() {
        // Create notification category with actions
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
    
    // MARK: - Reaction Notifications
    
    /// Send a reaction notification to message recipients
    func sendReactionNotification(senderId: String, senderName: String, emoji: String, messageContent: String, chatId: String, messageRecipients: [String]) {
        print("🔔 Sending reaction notification: \(emoji) from \(senderName)")
        
        // Don't send notification to the sender
        let recipients = messageRecipients.filter { $0 != senderId }
        
        for recipientId in recipients {
            let notification = NotificationData(
                senderId: senderId,
                senderName: senderName,
                message: "\(emoji) reacted to \"\(messageContent)\"",
                chatId: chatId,
                type: .reaction,
                emoji: emoji
            )
            
            storeNotificationForUser(userId: recipientId, notification: notification)
        }
    }
    
    // MARK: - Request Notification Permission
    
    func requestNotificationPermission() async -> Bool {
        do {
            // First check current authorization status
            let currentSettings = await UNUserNotificationCenter.current().notificationSettings()
            print("📱 Current notification settings: \(currentSettings.authorizationStatus.rawValue)")
            
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            print("📱 Notification permission result: \(granted)")
            
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
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
    
    // MARK: - Send Notification
    
    func sendNotification(to userId: String, message: Message, senderName: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid,
              userId != currentUserId else {
            print("⚠️ Skipping notification - same user or no current user")
            return
        }
        
        let notificationData = NotificationData(
            senderId: currentUserId,
            senderName: senderName,
            message: message.content,
            chatId: message.chatId
        )
        
        storeNotificationForUser(userId: userId, notification: notificationData)
    }
    
    // MARK: - Store Notification in Firestore
    
    private func storeNotificationForUser(userId: String, notification: NotificationData) {
        let notificationData: [String: Any] = [
            "id": notification.id,
            "senderId": notification.senderId,
            "senderName": notification.senderName,
            "message": notification.message,
            "chatId": notification.chatId,
            "timestamp": notification.timestamp,
            "isRead": notification.isRead
        ]
        
        Firestore.firestore()
            .collection("simulator_notifications")
            .document(userId)
            .collection("notifications")
            .document(notification.id)
            .setData(notificationData) { error in
                if let error = error {
                    print("❌ Error storing notification: \(error.localizedDescription)")
                } else {
                    print("✅ Notification stored for user: \(userId)")
                    // DO NOT display notification here - let the receiver's device handle it
                }
            }
    }
    
    // MARK: - Display Immediate Notification
    
    private func displayImmediateNotification(_ notification: NotificationData) {
        // Double-check: Only show notifications NOT from current user
        guard let currentUserId = Auth.auth().currentUser?.uid,
              notification.senderId != currentUserId else {
            print("⚠️ Skipping notification display - from current user")
            return
        }
        
        // Check cooldown
        let now = Date()
        let timeSinceLastNotification = now.timeIntervalSince(lastNotificationTime)
        
        if timeSinceLastNotification < notificationCooldown {
            print("⏰ Notification cooldown active, skipping")
            return
        }
        
        lastNotificationTime = now
        
        print("🔔 Attempting to display notification: \(notification.message) from \(notification.senderName)")
        
        // Create notification content
        let content = UNMutableNotificationContent()
        
        // Different titles and content for reaction vs message notifications
        if notification.type == .reaction {
            content.title = "\(notification.emoji ?? "👍") Reaction"
            content.body = "\(notification.senderName) reacted to your message"
        } else {
            content.title = "📱 MessageAI"
            content.body = "\(notification.senderName): \(notification.message)"
        }
        
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "MESSAGE_CATEGORY"
        content.userInfo = [
            "chatId": notification.chatId,
            "senderId": notification.senderId,
            "notificationId": notification.id,
            "isSimulatorNotification": true
        ]
        
        // Create immediate trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "immediate_\(notification.id)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        // Check notification settings before adding
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("📱 Notification settings: \(settings.authorizationStatus.rawValue)")
            
            if settings.authorizationStatus == .authorized {
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("❌ Error displaying notification: \(error.localizedDescription)")
                    } else {
                        print("✅ Notification displayed: \(notification.message)")
                    }
                }
            } else {
                print("❌ Notifications not authorized, cannot display")
            }
        }
    }
    
    // MARK: - Start Listening for Notifications
    
    func startListeningForNotifications() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Clear ALL notifications when starting to listen
        clearAllNotifications()
        
        // Remove existing listener
        notificationListener?.remove()
        
        notificationListener = Firestore.firestore()
            .collection("simulator_notifications")
            .document(currentUserId)
            .collection("notifications")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error listening to notifications: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let notifications = documents.compactMap { doc -> NotificationData? in
                    let data = doc.data()
                    guard let senderId = data["senderId"] as? String,
                          let senderName = data["senderName"] as? String,
                          let message = data["message"] as? String,
                          let chatId = data["chatId"] as? String,
                          let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                          let isRead = data["isRead"] as? Bool else {
                        return nil
                    }
                    
                    return NotificationData(
                        id: doc.documentID,
                        senderId: senderId,
                        senderName: senderName,
                        message: message,
                        chatId: chatId,
                        timestamp: timestamp,
                        isRead: isRead
                    )
                }
                
                // Filter for unread notifications and sort by timestamp
                let unreadNotifications = notifications
                    .filter { !$0.isRead && $0.senderId != currentUserId }
                    .sorted { $0.timestamp > $1.timestamp }
                
                DispatchQueue.main.async {
                    self?.pendingNotifications = unreadNotifications
                    
                    // Display the latest notification if it's new
                    if let latestNotification = unreadNotifications.first {
                        print("🔔 Found notification for current user: \(currentUserId) from sender: \(latestNotification.senderId)")
                        print("🔔 Notification content: \(latestNotification.message)")
                        self?.displayImmediateNotification(latestNotification)
                    } else {
                        print("⚠️ No unread notifications to display")
                    }
                }
            }
    }
    
    // MARK: - Mark Notifications as Read
    
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
    
    func markAllNotificationsAsReadForChat(_ chatId: String) {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Get all notifications for this user (no complex query to avoid index requirement)
        Firestore.firestore()
            .collection("simulator_notifications")
            .document(currentUserId)
            .collection("notifications")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error getting notifications for chat: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // Filter client-side for this chat and unread status
                let notificationsToUpdate = documents.filter { doc in
                    let data = doc.data()
                    let docChatId = data["chatId"] as? String
                    let isRead = data["isRead"] as? Bool
                    return docChatId == chatId && isRead == false
                }
                
                if notificationsToUpdate.isEmpty {
                    print("✅ No unread notifications found for chat: \(chatId)")
                    return
                }
                
                let batch = Firestore.firestore().batch()
                for document in notificationsToUpdate {
                    batch.updateData(["isRead": true], forDocument: document.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("❌ Error marking chat notifications as read: \(error.localizedDescription)")
                    } else {
                        print("✅ All notifications marked as read for chat: \(chatId)")
                        // Remove from pending notifications and clear system notifications
                        DispatchQueue.main.async { [weak self] in
                            self?.pendingNotifications.removeAll { $0.chatId == chatId }
                            // Clear system notifications for this chat
                            self?.clearSystemNotificationsForChat(chatId)
                        }
                    }
                }
            }
    }
    
    // MARK: - Clear System Notifications for Chat
    
    func clearSystemNotificationsForChat(_ chatId: String) {
        // Clear all delivered notifications for this chat
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let chatNotifications = notifications.filter { notification in
                let userInfo = notification.request.content.userInfo
                return userInfo["chatId"] as? String == chatId
            }
            
            let identifiers = chatNotifications.map { $0.request.identifier }
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
            print("✅ Cleared \(identifiers.count) system notifications for chat: \(chatId)")
        }
        
        // Also clear all pending notifications for this chat
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let chatRequests = requests.filter { request in
                let userInfo = request.content.userInfo
                return userInfo["chatId"] as? String == chatId
            }
            
            let identifiers = chatRequests.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
            print("✅ Cleared \(identifiers.count) pending notifications for chat: \(chatId)")
        }
    }
    
    // MARK: - Test Notification (for debugging)
    
    func testNotification() {
        print("🧪 Testing notification system...")
        
        let testNotification = NotificationData(
            senderId: "test_sender",
            senderName: "Test User",
            message: "This is a test notification",
            chatId: "test_chat"
        )
        
        displayImmediateNotification(testNotification)
    }
    
    // MARK: - Clear All Notifications
    
    func clearAllNotifications() {
        // Clear system notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // Clear from memory
        DispatchQueue.main.async { [weak self] in
            self?.pendingNotifications.removeAll()
        }
        
        // Clear from Firestore
        clearAllNotificationsFromFirestore()
        
        print("✅ All notifications cleared from system, memory, and Firestore")
    }
    
    private func clearAllNotificationsFromFirestore() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore()
            .collection("simulator_notifications")
            .document(currentUserId)
            .collection("notifications")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error getting notifications to clear: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let batch = Firestore.firestore().batch()
                for document in documents {
                    batch.deleteDocument(document.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("❌ Error clearing notifications from Firestore: \(error.localizedDescription)")
                    } else {
                        print("✅ Cleared \(documents.count) notifications from Firestore")
                    }
                }
            }
    }
    
    // MARK: - Get Notification Settings
    
    func getNotificationSettings() async -> UNNotificationSettings {
        return await UNUserNotificationCenter.current().notificationSettings()
    }
}
