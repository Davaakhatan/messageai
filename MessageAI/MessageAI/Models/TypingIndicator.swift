import Foundation
import FirebaseFirestore

/// Model representing a typing indicator for a user in a chat
struct TypingIndicator: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let chatId: String
    let timestamp: Date
    let isTyping: Bool
    
    init(userId: String, userName: String, chatId: String, isTyping: Bool) {
        self.id = "\(userId)_\(chatId)"
        self.userId = userId
        self.userName = userName
        self.chatId = chatId
        self.timestamp = Date()
        self.isTyping = isTyping
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let userId = data["userId"] as? String,
              let userName = data["userName"] as? String,
              let chatId = data["chatId"] as? String,
              let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
              let isTyping = data["isTyping"] as? Bool else {
            return nil
        }
        
        self.id = document.documentID
        self.userId = userId
        self.userName = userName
        self.chatId = chatId
        self.timestamp = timestamp
        self.isTyping = isTyping
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "userId": userId,
            "userName": userName,
            "chatId": chatId,
            "timestamp": Timestamp(date: timestamp),
            "isTyping": isTyping
        ]
    }
}
