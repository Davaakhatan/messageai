import Foundation
import SwiftUI
import FirebaseFirestore

struct Message: Codable, Identifiable, Equatable {
    let id: String
    let content: String
    let senderId: String
    let chatId: String
    let timestamp: Date
    let type: MessageType
    var deliveryStatus: DeliveryStatus
    let mediaURL: String?
    let replyToMessageId: String?
    let recipients: [String] // Array of user IDs who should receive this message
    let senderName: String? // Display name of the sender
    var readBy: [String] // Array of user IDs who have read this message
    var reactions: [String: [String]] // Emoji -> Array of user IDs who reacted
    
    init(
        id: String = UUID().uuidString,
        content: String,
        senderId: String,
        chatId: String,
        timestamp: Date = Date(),
        type: MessageType = .text,
        deliveryStatus: DeliveryStatus = .sending,
        mediaURL: String? = nil,
        replyToMessageId: String? = nil,
        recipients: [String] = [],
        senderName: String? = nil,
        readBy: [String] = [],
        reactions: [String: [String]] = [:]
    ) {
        self.id = id
        self.content = content
        self.senderId = senderId
        self.chatId = chatId
        self.timestamp = timestamp
        self.type = type
        self.deliveryStatus = deliveryStatus
        self.mediaURL = mediaURL
        self.replyToMessageId = replyToMessageId
        self.recipients = recipients
        self.senderName = senderName
        self.readBy = readBy
        self.reactions = reactions
    }
    
    enum MessageType: String, Codable, CaseIterable {
        case text = "text"
        case image = "image"
        case audio = "audio"
        case video = "video"
        case file = "file"
    }
    
    enum DeliveryStatus: String, Codable, CaseIterable {
        case sending = "sending"
        case sent = "sent"
        case delivered = "delivered"
        case read = "read"
        case failed = "failed"
        
        var displayColor: Color {
            switch self {
            case .sending, .sent:
                return .gray
            case .delivered:
                return .blue
            case .read:
                return .green
            case .failed:
                return .red
            }
        }
        
        var checkmarkIcon: String {
            switch self {
            case .sending, .sent:
                return "checkmark"
            case .delivered:
                return "checkmark"
            case .read:
                return "checkmark.circle.fill"
            case .failed:
                return "exclamationmark"
            }
        }
    }
}

// MARK: - Firestore Extensions
extension Message {
    init?(from document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let content = data["content"] as? String,
              let senderId = data["senderId"] as? String,
              let chatId = data["chatId"] as? String,
              let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
              let typeString = data["type"] as? String,
              let type = MessageType(rawValue: typeString),
              let statusString = data["deliveryStatus"] as? String,
              let deliveryStatus = DeliveryStatus(rawValue: statusString) else {
            return nil
        }
        
        self.id = document.documentID
        self.content = content
        self.senderId = senderId
        self.chatId = chatId
        self.timestamp = timestamp
        self.type = type
        self.deliveryStatus = deliveryStatus
        self.mediaURL = data["mediaURL"] as? String
        self.replyToMessageId = data["replyToMessageId"] as? String
        self.recipients = data["recipients"] as? [String] ?? []
        self.senderName = data["senderName"] as? String
        self.readBy = data["readBy"] as? [String] ?? []
        self.reactions = data["reactions"] as? [String: [String]] ?? [:]
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "content": content,
            "senderId": senderId,
            "chatId": chatId,
            "timestamp": Timestamp(date: timestamp),
            "type": type.rawValue,
            "deliveryStatus": deliveryStatus.rawValue,
            "mediaURL": mediaURL as Any,
            "replyToMessageId": replyToMessageId as Any,
            "recipients": recipients,
            "senderName": senderName as Any,
            "readBy": readBy,
            "reactions": reactions
        ]
    }
}
