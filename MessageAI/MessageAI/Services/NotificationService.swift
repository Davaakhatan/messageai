import Foundation
import UserNotifications
import FirebaseMessaging
import FirebaseFirestore
import FirebaseAuth

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    // MARK: - Send Push Notification
    
    func sendMessageNotification(to userId: String, message: Message, senderName: String) {
        // For simulator testing, we'll use a different approach
        // Check if we're running on simulator
        #if targetEnvironment(simulator)
        // Simulator: Use SimulatorNotificationManager for cross-simulator notifications
        SimulatorNotificationManager.shared.sendNotificationToSimulator(
            to: userId,
            message: message,
            senderName: senderName
        )
        #else
        // Real device: Send actual FCM notification
        sendFCMNotification(to: userId, message: message, senderName: senderName)
        #endif
    }
    
    // MARK: - Simulator Notification (for testing)
    
    private func sendSimulatorNotification(to userId: String, message: Message, senderName: String) {
        // Get the current user ID to determine which simulator should receive the notification
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        // Only send notification if the target user is different from current user
        if userId != currentUserId {
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "📱 From \(senderName)"
            content.body = message.content
            content.sound = .default
            content.badge = 1
            content.userInfo = [
                "chatId": message.chatId,
                "messageId": message.id,
                "senderId": message.senderId,
                "isSimulatorNotification": true
            ]
            
            // Create notification request
            let request = UNNotificationRequest(
                identifier: "simulator_message_\(message.id)_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil // Send immediately
            )
            
            // Add notification to center
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error sending simulator notification: \(error.localizedDescription)")
                } else {
                    print("✅ Simulator notification sent to user: \(userId)")
                }
            }
        }
    }
    
    // MARK: - FCM Notification (for real devices)
    
    private func sendFCMNotification(to userId: String, message: Message, senderName: String) {
        // Get recipient's FCM token
        Firestore.firestore().collection("users").document(userId).getDocument { documentSnapshot, error in
            guard let document = documentSnapshot,
                  let data = document.data(),
                  let fcmToken = data["fcmToken"] as? String else {
                print("Error getting FCM token for recipient \(userId): \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Construct notification payload
            let serverKey = "YOUR_FIREBASE_SERVER_KEY" // Replace with your actual server key
            let urlString = "https://fcm.googleapis.com/fcm/send"
            guard let url = URL(string: urlString) else { return }
            
            let notificationContent: [String: Any] = [
                "title": senderName,
                "body": message.content,
                "sound": "default",
                "badge": 1
            ]
            
            let payload: [String: Any] = [
                "to": fcmToken,
                "notification": notificationContent,
                "data": [
                    "chatId": message.chatId,
                    "senderId": message.senderId
                ]
            ]
            
            // Send HTTP request to FCM
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
            } catch {
                print("Error serializing JSON payload: \(error.localizedDescription)")
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error sending FCM message: \(error.localizedDescription)")
                    return
                }
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("FCM Response: \(responseString)")
                }
            }.resume()
        }
    }
    
    // MARK: - Request Permission
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("❌ Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    // MARK: - Clear Badge
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    // MARK: - Schedule Local Notification (for testing)
    
    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "MessageAI Test"
        content.body = "This is a test notification from MessageAI"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling test notification: \(error.localizedDescription)")
            } else {
                print("✅ Test notification scheduled")
            }
        }
    }
}
