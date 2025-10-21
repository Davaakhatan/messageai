import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine
//import OpenAI

class MessageService: ObservableObject {
    @Published var messages: [String: [Message]] = [:]
    @Published var chats: [Chat] = []
    @Published var isConnected = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var chatUserNames: [String: String] = [:] // Cache: chatId -> displayName

    private let db = Firestore.firestore()
    private var messageListeners: [String: ListenerRegistration] = [:]
    private var chatListener: ListenerRegistration?
    
    init() {
        // Skip Firebase initialization in preview mode
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }
        #endif
        setupConnectionListener()
    }
    
    deinit {
        removeAllListeners()
    }
    
    private func setupConnectionListener() {
        db.collection("test").addSnapshotListener { [weak self] _, error in
            DispatchQueue.main.async {
                self?.isConnected = error == nil
            }
        }
    }
    
    // MARK: - Chat Management
    
    func loadChats() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        chatListener = db.collection("chats")
            .whereField("participants", arrayContains: currentUser.uid)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "Failed to load chats: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    self?.chats = documents.compactMap { Chat(from: $0) }
                    
                    // Load user names for 1-on-1 chats
                    self?.loadChatUserNames(for: self?.chats ?? [], currentUserId: currentUser.uid)
                }
            }
    }
    
    private func loadChatUserNames(for chats: [Chat], currentUserId: String) {
        for chat in chats where !chat.isGroup {
            let otherUserIds = chat.otherParticipants(currentUserId: currentUserId)
            if let otherUserId = otherUserIds.first {
                // Fetch user data for this participant
                db.collection("users").document(otherUserId).getDocument { [weak self] document, error in
                    if let document = document, document.exists,
                       let user = User(from: document) {
                        DispatchQueue.main.async {
                            self?.chatUserNames[chat.id] = user.displayName
                        }
                    }
                }
            }
        }
    }
    
    func createChat(with userIds: [String], isGroup: Bool = false, groupName: String? = nil) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let participants = [currentUser.uid] + userIds
        let chat = Chat(
            participants: participants,
            isGroup: isGroup,
            groupName: groupName,
            createdBy: isGroup ? currentUser.uid : nil,
            admins: isGroup ? [currentUser.uid] : nil
        )
        
        db.collection("chats").document(chat.id).setData(chat.toDictionary()) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to create chat: \(error.localizedDescription)"
                    return
                }
                
                // Reload chats
                self?.loadChats()
            }
        }
    }
    
    // MARK: - Message Management
    
    func loadMessages(for chatId: String) {
        // Remove existing listener for this chat
        messageListeners[chatId]?.remove()
        
        messageListeners[chatId] = db.collection("messages")
            .whereField("chatId", isEqualTo: chatId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = "Failed to load messages: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    let messages = documents.compactMap { Message(from: $0) }
                    self?.messages[chatId] = messages
                }
            }
    }
    
    func sendMessage(_ content: String, to chatId: String, type: Message.MessageType = .text, mediaURL: String? = nil) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let message = Message(
            content: content,
            senderId: currentUser.uid,
            chatId: chatId,
            type: type,
            mediaURL: mediaURL
        )
        
        // Optimistic update
        if messages[chatId] == nil {
            messages[chatId] = []
        }
        messages[chatId]?.append(message)
        
        // Send to Firestore
        db.collection("messages").document(message.id).setData(message.toDictionary()) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to send message: \(error.localizedDescription)"
                    // Remove the optimistic update
                    self?.messages[chatId]?.removeAll { $0.id == message.id }
                    return
                }
                
                // Update delivery status
                self?.updateMessageDeliveryStatus(messageId: message.id, status: .sent)
                
                // Update chat's last message
                self?.updateChatLastMessage(chatId: chatId, message: message)
            }
        }
    }
    
    func updateMessageDeliveryStatus(messageId: String, status: Message.DeliveryStatus) {
        db.collection("messages").document(messageId).updateData([
            "deliveryStatus": status.rawValue
        ]) { error in
            if let error = error {
                print("Failed to update message status: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateChatLastMessage(chatId: String, message: Message) {
        db.collection("chats").document(chatId).updateData([
            "lastMessage": message.toDictionary(),
            "updatedAt": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Failed to update chat last message: \(error.localizedDescription)")
            }
        }
    }
    
    func markMessageAsRead(messageId: String) {
        updateMessageDeliveryStatus(messageId: messageId, status: .read)
    }
    
    func markAllMessagesAsRead(in chatId: String) {
        guard let currentUser = Auth.auth().currentUser,
              let messages = messages[chatId] else { return }
        
        let unreadMessages = messages.filter { 
            $0.senderId != currentUser.uid && $0.deliveryStatus != .read 
        }
        
        for message in unreadMessages {
            markMessageAsRead(messageId: message.id)
        }
    }
    
    // MARK: - User Management

    func searchUsers(query: String) async throws -> [User] {
        return try await withCheckedThrowingContinuation { continuation in
            // Get all users and filter client-side for better search results
            db.collection("users")
                .limit(to: 50) // Get more users to filter from
                .getDocuments { snapshot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        continuation.resume(returning: [])
                        return
                    }
                    
                    let allUsers = documents.compactMap { User(from: $0) }
                    
                    // Filter users based on query (case-insensitive)
                    let filteredUsers = allUsers.filter { user in
                        let queryLower = query.lowercased()
                        let matchesDisplayName = user.displayName.lowercased().contains(queryLower)
                        let matchesEmail = user.email.lowercased().contains(queryLower)
                        return matchesDisplayName || matchesEmail
                    }
                    
                    // Limit results to 10
                    let limitedUsers = Array(filteredUsers.prefix(10))
                    continuation.resume(returning: limitedUsers)
                }
        }
    }
    
    // MARK: - Group Chat Management
    
    func addParticipants(to chatId: String, userIds: [String]) {
        db.collection("chats").document(chatId).getDocument { [weak self] document, error in
            guard let document = document,
                  document.exists,
                  var currentParticipants = document.data()?["participants"] as? [String] else {
                return
            }
            
            // Add new participants (avoid duplicates)
            let newParticipants = userIds.filter { !currentParticipants.contains($0) }
            currentParticipants.append(contentsOf: newParticipants)
            
            self?.db.collection("chats").document(chatId).updateData([
                "participants": currentParticipants,
                "updatedAt": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    print("Error adding participants: \(error.localizedDescription)")
                } else {
                    print("✅ Successfully added \(newParticipants.count) participants")
                    // Reload chats to reflect changes
                    self?.loadChats()
                }
            }
        }
    }
    
    func removeParticipant(from chatId: String, userId: String) {
        db.collection("chats").document(chatId).getDocument { [weak self] document, error in
            guard let document = document,
                  document.exists,
                  var currentParticipants = document.data()?["participants"] as? [String] else {
                return
            }
            
            // Remove participant
            currentParticipants.removeAll { $0 == userId }
            
            self?.db.collection("chats").document(chatId).updateData([
                "participants": currentParticipants,
                "updatedAt": Timestamp(date: Date())
            ]) { error in
                if let error = error {
                    print("Error removing participant: \(error.localizedDescription)")
                } else {
                    print("✅ Successfully removed participant")
                    self?.loadChats()
                }
            }
        }
    }
    
    func updateGroupName(chatId: String, newName: String) {
        db.collection("chats").document(chatId).updateData([
            "groupName": newName,
            "updatedAt": Timestamp(date: Date())
        ]) { [weak self] error in
            if let error = error {
                print("Error updating group name: \(error.localizedDescription)")
            } else {
                print("✅ Successfully updated group name")
                self?.loadChats()
            }
        }
    }
    
    func deleteChat(chatId: String) {
        // Delete all messages in the chat first
        db.collection("messages")
            .whereField("chatId", isEqualTo: chatId)
            .getDocuments { [weak self] snapshot, error in
                if let documents = snapshot?.documents {
                    for document in documents {
                        document.reference.delete()
                    }
                }
                
                // Then delete the chat
                self?.db.collection("chats").document(chatId).delete { error in
                    if let error = error {
                        print("Error deleting chat: \(error.localizedDescription)")
                    } else {
                        print("✅ Successfully deleted chat")
                        self?.loadChats()
                    }
                }
            }
    }
    
    func getUsers(for userIds: [String]) async throws -> [User] {
        return try await withCheckedThrowingContinuation { continuation in
            db.collection("users")
                .whereField(FieldPath.documentID(), in: userIds)
                .getDocuments { snapshot, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        continuation.resume(returning: [])
                        return
                    }
                    
                    let users = documents.compactMap { User(from: $0) }
                    continuation.resume(returning: users)
                }
        }
    }
    
    // MARK: - Cleanup
    
    func removeAllListeners() {
        messageListeners.values.forEach { $0.remove() }
        messageListeners.removeAll()
        chatListener?.remove()
        chatListener = nil
    }
    
    func removeMessageListener(for chatId: String) {
        messageListeners[chatId]?.remove()
        messageListeners.removeValue(forKey: chatId)
    }
}
