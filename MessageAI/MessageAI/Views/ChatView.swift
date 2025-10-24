import SwiftUI

struct ChatView: View {
    let chat: Chat
    @EnvironmentObject var messageService: MessageService
    @EnvironmentObject var authService: AuthService
    @State private var messageText = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingGroupInfo = false
    @State private var showingUserInfo = false
    
    private var messages: [Message] {
        messageService.messages[chat.id] ?? []
    }
    
    // Get proper display name using cached names for 1-on-1 chats
    private var displayName: String {
        if chat.isGroup {
            return chat.groupName ?? "Group Chat"
        } else {
            return messageService.chatUserNames[chat.id] ?? "User"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            MessageBubbleView(
                                message: message,
                                isFromCurrentUser: message.senderId == authService.currentUser?.id,
                                isGroupChat: chat.isGroup,
                                chatParticipants: chat.participants
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .onChange(of: messages.count) { _ in
                    if let lastMessage = messages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onAppear {
                    // Messages will be marked as read in the main onAppear
                }
            }
            
            // Message Input
            MessageInputView(
                messageText: $messageText,
                onSend: sendMessage,
                onImageTap: { showingImagePicker = true }
            )
        }
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if chat.isGroup {
                        showingGroupInfo = true
                    } else {
                        showingUserInfo = true
                    }
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            messageService.loadMessages(for: chat.id)
            
            // Fetch user names for all chat participants
            UserService.shared.fetchUsers(userIds: chat.participants)
            
            // Mark messages as read immediately when chat is viewed
            messageService.markAllMessagesAsRead(in: chat.id)
            
            // Also mark as read after a short delay to ensure all messages are loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                messageService.markAllMessagesAsRead(in: chat.id)
            }
            
            // Mark notifications as read for this chat using production notification manager
            ProductionNotificationManager.shared.markAllNotificationsAsReadForChat(chat.id)
            // Clear system notifications for this chat
            ProductionNotificationManager.shared.clearSystemNotificationsForChat(chat.id)
        }
        .onDisappear {
            messageService.removeMessageListener(for: chat.id)
        }
        .sheet(isPresented: $showingImagePicker) {
            CustomImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingGroupInfo) {
            GroupInfoView(chat: chat)
                .environmentObject(messageService)
                .environmentObject(authService)
        }
        .sheet(isPresented: $showingUserInfo) {
            UserInfoView(chat: chat)
                .environmentObject(messageService)
                .environmentObject(authService)
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                sendImageMessage(image)
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = ""
        
        messageService.sendMessage(content, to: chat.id)
    }
    
    private func sendImageMessage(_ image: UIImage) {
        // For now, just send a placeholder message
        // In a real app, you'd upload the image to Firebase Storage first
        messageService.sendMessage("📷 Image", to: chat.id, type: .image)
        selectedImage = nil
    }
}

struct MessageBubbleView: View {
    let message: Message
    let isFromCurrentUser: Bool
    let isGroupChat: Bool
    let chatParticipants: [String]
    @State private var showingTimestamp = false
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var messageService: MessageService
    @StateObject private var userService = UserService.shared
    
    private var isUnread: Bool {
        !isFromCurrentUser && message.deliveryStatus != .read
    }
    
    private var senderDisplayName: String {
        if let senderName = message.senderName, !senderName.isEmpty {
            return senderName
        } else {
            // Try to get from UserService
            if let user = userService.users[message.senderId] {
                return user.displayName
            } else {
                // Fetch user if not cached
                userService.fetchUser(userId: message.senderId)
                return "User \(message.senderId.prefix(8))"
            }
        }
    }
    
    private var readByNames: [String] {
        return message.readBy.map { userId in
            if let user = userService.users[userId] {
                return user.displayName
            } else {
                userService.fetchUser(userId: userId)
                return "User \(userId.prefix(8))"
            }
        }
    }
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Sender Name (for group chats)
                if isGroupChat && !isFromCurrentUser {
                    HStack {
                        Text(senderDisplayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        Spacer()
                    }
                }
                
                // Message Content
                Group {
                    if message.type == .image, let mediaURL = message.mediaURL {
                        AsyncImage(url: URL(string: mediaURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 200, maxHeight: 200)
                                .cornerRadius(12)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 200, height: 150)
                                .overlay {
                                    ProgressView()
                                }
                        }
                    } else {
                        Text(message.content)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isFromCurrentUser ? Color.blue : (isUnread ? Color.blue.opacity(0.1) : Color.gray.opacity(0.2)))
                )
                .foregroundColor(isFromCurrentUser ? .white : (isUnread ? .blue : .primary))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isUnread ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingTimestamp.toggle()
                    }
                }
                
                // Timestamp and Status
                if showingTimestamp {
                    Text(formatDetailedTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .transition(.opacity.combined(with: .scale))
                }
                
                HStack(spacing: 4) {
                    if !showingTimestamp {
                        Text(formatTime(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if isFromCurrentUser {
                        HStack(spacing: 4) {
                            Image(systemName: message.deliveryStatus.checkmarkIcon)
                                .font(.caption2)
                                .foregroundColor(message.deliveryStatus.displayColor)
                            
                            // Show status text for failed messages
                            if message.deliveryStatus == .failed {
                                HStack(spacing: 4) {
                                    Text("Failed")
                                        .font(.caption2)
                                        .foregroundColor(.red)
                                    
                                    Button(action: {
                                        messageService.retryFailedMessage(messageId: message.id, chatId: message.chatId)
                                    }) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                }
                            } else if message.deliveryStatus == .sending {
                                Text("Sending...")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
                
                // Read Receipts (for group chats)
                if isGroupChat && isFromCurrentUser && !message.readBy.isEmpty {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Read by \(message.readBy.count) of \(chatParticipants.count - 1)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if showingTimestamp {
                            Text("Read by: \(readByNames.joined(separator: ", "))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingTimestamp)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.dateInterval(of: .weekOfYear, for: Date())?.contains(date) == true {
            formatter.dateFormat = "EEEE"
        } else {
            formatter.dateStyle = .short
        }
        
        return formatter.string(from: date)
    }
    
    private func formatDetailedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
}

struct MessageInputView: View {
    @Binding var messageText: String
    let onSend: () -> Void
    let onImageTap: () -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Expanded input area
            if isExpanded {
                VStack(spacing: 8) {
                    HStack {
                        Text("Message")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Done") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = false
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                    
                    TextEditor(text: $messageText)
                        .frame(minHeight: 60, maxHeight: 120)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            // Main input bar
            HStack(spacing: 12) {
                Button(action: onImageTap) {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    TextField("Message", text: $messageText, axis: .vertical)
                        .lineLimit(1...4)
                        .keyboardType(.default)
                        .onTapGesture {
                            if !isExpanded {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded = true
                                }
                            }
                        }
                    
                    if !messageText.isEmpty {
                        Button(action: onSend) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(20)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}


#Preview {
    let sampleChat = Chat(
        participants: ["user1", "user2"],
        isGroup: false
    )
    
    return ChatView(chat: sampleChat)
        .environmentObject(MessageService())
        .environmentObject(AuthService())
}
