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
    @Published var unreadCount: Int = 0
    @Published var chatUnreadCounts: [String: Int] = [:]

    private let db = Firestore.firestore()
    private var messageListeners: [String: ListenerRegistration] = [:]
    private var chatListener: ListenerRegistration?
    private let userService = UserService.shared
    
    init() {
        // Skip Firebase initialization in preview mode
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }
        #endif
        setupConnectionListener()
        startUnreadCountListener()
    }
    
    deinit {
        removeAllListeners()
    }
    
    private func setupConnectionListener() {
        // Set connection status to true by default to avoid permission issues
        DispatchQueue.main.async {
            self.isConnected = true
        }
        
        // Optional: Test connection with a simpler approach
        db.collection("users").limit(to: 1).getDocuments { [weak self] _, error in
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
                    self?.updateUnreadCount()
                    
                    // Fetch user names for all unique senders
                    let uniqueSenderIds = Set(messages.map { $0.senderId })
                    self?.userService.fetchUsers(userIds: Array(uniqueSenderIds))
                }
            }
    }
    
    func sendMessage(_ content: String, to chatId: String, type: Message.MessageType = .text, mediaURL: String? = nil) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        // Get chat participants to determine recipients
        db.collection("chats").document(chatId).getDocument { [weak self] document, error in
            guard let document = document,
                  let data = document.data(),
                  let participants = data["participants"] as? [String] else {
                print("❌ Error getting chat participants: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Recipients are all participants except the sender
            let recipients = participants.filter { $0 != currentUser.uid }
            
            let message = Message(
                content: content,
                senderId: currentUser.uid,
                chatId: chatId,
                type: type,
                mediaURL: mediaURL,
                recipients: recipients,
                senderName: self?.userService.getUserName(for: currentUser.uid) ?? "User"
            )
            
            // When sending a message, automatically mark all previous messages as read by this user
            self?.markAllMessagesAsReadBySender(in: chatId, senderId: currentUser.uid)
            
            self?.sendMessageToFirestore(message)
        }
    }
    
    private func sendMessageToFirestore(_ message: Message) {
        // Optimistic update
        if messages[message.chatId] == nil {
            messages[message.chatId] = []
        }
        messages[message.chatId]?.append(message)
        
        // Send to Firestore
        db.collection("messages").document(message.id).setData(message.toDictionary()) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to send message: \(error.localizedDescription)"
                    // Remove the optimistic update
                    self?.messages[message.chatId]?.removeAll { $0.id == message.id }
                    return
                }
                
                // Update delivery status
                self?.updateMessageDeliveryStatus(messageId: message.id, status: .sent)
                
                // Update chat's last message
                self?.updateChatLastMessage(chatId: message.chatId, message: message)
                
                // Send push notification to recipients
                self?.sendNotificationToRecipients(message: message)
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
    
    private func sendNotificationToRecipients(message: Message) {
        // Get sender's display name
        db.collection("users").document(message.senderId).getDocument { [weak self] userDoc, userError in
            guard let userDoc = userDoc,
                  let userData = userDoc.data(),
                  let senderName = userData["displayName"] as? String else {
                return
            }
            
            // Only send notifications to recipients (not the sender)
            guard let currentUser = Auth.auth().currentUser else { return }
            
            for recipientId in message.recipients {
                // Don't send notification to the sender
                if recipientId != currentUser.uid {
                    print("🔔 Sending notification to recipient: \(recipientId)")
                    ProductionNotificationManager.shared.sendNotification(
                        to: recipientId,
                        message: message,
                        senderName: senderName
                    )
                } else {
                    print("🔔 Skipping notification for sender: \(recipientId)")
                }
            }
        }
    }
    
    func markMessageAsRead(messageId: String) {
        updateMessageDeliveryStatus(messageId: messageId, status: .read)
    }
    
    func markAllMessagesAsRead(in chatId: String) {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        print("📖 Marking all messages as read in chat \(chatId)")
        
        // First, update local cache immediately for better UX
        if var chatMessages = messages[chatId] {
            for i in 0..<chatMessages.count {
                if chatMessages[i].senderId != currentUser.uid && chatMessages[i].deliveryStatus != .read {
                    chatMessages[i].deliveryStatus = .read
                    print("📖 Marking message as read: \(chatMessages[i].content)")
                }
            }
            messages[chatId] = chatMessages
            updateUnreadCount()
            print("✅ Updated local cache with \(chatMessages.count) messages")
        }
        
        // Then update Firestore
        db.collection("messages")
            .whereField("chatId", isEqualTo: chatId)
            .whereField("recipients", arrayContains: currentUser.uid)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error getting unread messages: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // Filter client-side for unread messages from other users
                let unreadMessages = documents.filter { document in
                    let data = document.data()
                    let senderId = data["senderId"] as? String ?? ""
                    let deliveryStatus = data["deliveryStatus"] as? String ?? ""
                    return senderId != currentUser.uid && deliveryStatus != "read"
                }
                
                print("📖 Found \(unreadMessages.count) unread messages to mark as read in Firestore")
                
                if unreadMessages.isEmpty {
                    print("✅ No unread messages to mark as read in Firestore")
                    return
                }
                
                // Update each unread message in a batch
                let batch = self?.db.batch()
                for document in unreadMessages {
                    let currentReadBy = document.data()["readBy"] as? [String] ?? []
                    if !currentReadBy.contains(currentUser.uid) {
                        let updatedReadBy = currentReadBy + [currentUser.uid]
                        batch?.updateData([
                            "deliveryStatus": "read",
                            "readBy": updatedReadBy
                        ], forDocument: document.reference)
                    }
                }
                
                batch?.commit { error in
                    if let error = error {
                        print("❌ Error marking messages as read: \(error.localizedDescription)")
                    } else {
                        print("✅ Successfully marked \(unreadMessages.count) messages as read in Firestore")
                    }
                }
            }
    }
    
    func markAllMessagesAsReadBySender(in chatId: String, senderId: String) {
        print("📖 Marking all messages as read by sender \(senderId) in chat \(chatId)")
        
        // Update Firestore to mark all messages in this chat as read by the sender
        db.collection("messages")
            .whereField("chatId", isEqualTo: chatId)
            .whereField("senderId", isNotEqualTo: senderId) // Only messages from other users
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error getting messages to mark as read by sender: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                print("📖 Found \(documents.count) messages to mark as read by sender \(senderId)")
                
                if documents.isEmpty {
                    print("✅ No messages to mark as read by sender")
                    return
                }
                
                // Update each message in a batch
                let batch = self?.db.batch()
                for document in documents {
                    let currentReadBy = document.data()["readBy"] as? [String] ?? []
                    if !currentReadBy.contains(senderId) {
                        let updatedReadBy = currentReadBy + [senderId]
                        batch?.updateData([
                            "readBy": updatedReadBy
                        ], forDocument: document.reference)
                    }
                }
                
                batch?.commit { error in
                    if let error = error {
                        print("❌ Error marking messages as read by sender: \(error.localizedDescription)")
                    } else {
                        print("✅ Successfully marked \(documents.count) messages as read by sender \(senderId)")
                    }
                }
            }
    }
    
    // MARK: - Unread Count Management
    
    private func updateUnreadCount() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        var totalUnread = 0
        for (_, messageList) in messages {
            let unreadMessages = messageList.filter { 
                $0.senderId != currentUser.uid && $0.deliveryStatus != .read 
            }
            totalUnread += unreadMessages.count
        }
        
        DispatchQueue.main.async {
            self.unreadCount = totalUnread
        }
    }
    
    // MARK: - Real-time Unread Count Monitoring
    
    private func startUnreadCountListener() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        // Listen to all messages where current user is a recipient
        db.collection("messages")
            .whereField("recipients", arrayContains: currentUser.uid)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error listening to unread messages: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // Filter for unread messages (not sent by current user and not read)
                let unreadMessages = documents.filter { doc in
                    let data = doc.data()
                    let senderId = data["senderId"] as? String
                    let deliveryStatus = data["deliveryStatus"] as? String
                    return senderId != currentUser.uid && deliveryStatus != "read"
                }
                
                // Group unread messages by chat
                var chatCounts: [String: Int] = [:]
                for message in unreadMessages {
                    let data = message.data()
                    if let chatId = data["chatId"] as? String {
                        chatCounts[chatId, default: 0] += 1
                    }
                }
                
                DispatchQueue.main.async {
                    self?.unreadCount = unreadMessages.count
                    self?.chatUnreadCounts = chatCounts
                    print("📊 Unread count updated: \(unreadMessages.count) across \(chatCounts.count) chats")
                }
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
