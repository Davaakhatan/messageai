import Foundation
import FirebaseFirestore

struct Chat: Codable, Identifiable, Equatable {
    let id: String
    let participants: [String]
    let lastMessage: Message?
    let isGroup: Bool
    let groupName: String?
    let groupImageURL: String?
    let createdAt: Date
    let updatedAt: Date
    let createdBy: String? // Admin/creator of the group
    let admins: [String]? // List of admin user IDs
    
    init(
        id: String = UUID().uuidString,
        participants: [String],
        lastMessage: Message? = nil,
        isGroup: Bool = false,
        groupName: String? = nil,
        groupImageURL: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        createdBy: String? = nil,
        admins: [String]? = nil
    ) {
        self.id = id
        self.participants = participants
        self.lastMessage = lastMessage
        self.isGroup = isGroup
        self.groupName = groupName
        self.groupImageURL = groupImageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.createdBy = createdBy
        self.admins = admins ?? (createdBy != nil ? [createdBy!] : [])
    }
}

// MARK: - Firestore Extensions
extension Chat {
    init?(from document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let participants = data["participants"] as? [String],
              let isGroup = data["isGroup"] as? Bool,
              let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
              let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() else {
            return nil
        }
        
        self.id = document.documentID
        self.participants = participants
        self.isGroup = isGroup
        self.groupName = data["groupName"] as? String
        self.groupImageURL = data["groupImageURL"] as? String
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.createdBy = data["createdBy"] as? String
        self.admins = data["admins"] as? [String]
        
        // Parse last message if it exists
        if let lastMessageData = data["lastMessage"] as? [String: Any] {
            self.lastMessage = Message(
                id: lastMessageData["id"] as? String ?? "",
                content: lastMessageData["content"] as? String ?? "",
                senderId: lastMessageData["senderId"] as? String ?? "",
                chatId: document.documentID,
                timestamp: (lastMessageData["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                type: Message.MessageType(rawValue: lastMessageData["type"] as? String ?? "text") ?? .text,
                deliveryStatus: Message.DeliveryStatus(rawValue: lastMessageData["deliveryStatus"] as? String ?? "sent") ?? .sent
            )
        } else {
            self.lastMessage = nil
        }
    }
    
    func toDictionary() -> [String: Any] {
        var data: [String: Any] = [
            "participants": participants,
            "isGroup": isGroup,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        if let groupName = groupName {
            data["groupName"] = groupName
        }
        
        if let groupImageURL = groupImageURL {
            data["groupImageURL"] = groupImageURL
        }
        
        if let createdBy = createdBy {
            data["createdBy"] = createdBy
        }
        
        if let admins = admins {
            data["admins"] = admins
        }
        
        if let lastMessage = lastMessage {
            data["lastMessage"] = lastMessage.toDictionary()
        }
        
        return data
    }
}

// MARK: - Helper Methods
extension Chat {
    func displayName(for currentUserId: String) -> String {
        if isGroup {
            return groupName ?? "Group Chat"
        } else {
            // For one-on-one chats, return the other participant's name
            let otherParticipants = participants.filter { $0 != currentUserId }
            return otherParticipants.first ?? "Unknown User"
        }
    }
    
    func otherParticipants(currentUserId: String) -> [String] {
        return participants.filter { $0 != currentUserId }
    }
    
    func isAdmin(userId: String) -> Bool {
        return admins?.contains(userId) ?? false
    }
    
    func isCreator(userId: String) -> Bool {
        return createdBy == userId
    }
}
