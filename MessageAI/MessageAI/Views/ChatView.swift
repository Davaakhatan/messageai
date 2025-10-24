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
    @State private var showingReactionPicker = false
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
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                            .foregroundColor(isFromCurrentUser ? .white : .primary)
                            .cornerRadius(16)
                    }
                }
                
                // Message Reactions
                if !message.reactions.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(message.reactions.keys.sorted(), id: \.self) { emoji in
                            if let userIds = message.reactions[emoji], !userIds.isEmpty {
                                Button(action: {
                                    if userIds.contains(authService.currentUser?.id ?? "") {
                                        messageService.removeReaction(messageId: message.id, chatId: message.chatId, emoji: emoji)
                                    } else {
                                        messageService.addReaction(messageId: message.id, chatId: message.chatId, emoji: emoji)
                                    }
                                }) {
                                    HStack(spacing: 2) {
                                        Text(emoji)
                                        Text("\(userIds.count)")
                                            .font(.caption2)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                
                // Read Receipts (for group chats)
                if isFromCurrentUser && isGroupChat && !message.readBy.isEmpty {
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            // Calculate recipients count (exclude sender)
                            let recipientsCount = chatParticipants.count - 1
                            Text("Read by \(message.readBy.count) of \(recipientsCount)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            if message.readBy.count < recipientsCount {
                                Button("View Details") {
                                    showingTimestamp.toggle()
                                }
                                .font(.caption2)
                                .foregroundColor(.blue)
                            }
                        }
                        
                        // Show reader names when View Details is tapped
                        if showingTimestamp && !message.readBy.isEmpty {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Read by:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                ForEach(readByNames, id: \.self) { readerName in
                                    Text("• \(readerName)")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                
                // Timestamp
                HStack {
                    if showingTimestamp {
                        Text(formatDetailedTime(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
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
                                    Button {
                                        messageService.retryFailedMessage(messageId: message.id, chatId: message.chatId)
                                    } label: {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.caption2)
                                            .foregroundColor(.red)
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
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
        .onLongPressGesture {
            // Show reaction picker
            print("🧪 Long press detected on message: \(message.content)")
            showingReactionPicker = true
        }
        .sheet(isPresented: $showingReactionPicker) {
            ReactionPickerView(messageId: message.id, chatId: message.chatId)
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

struct ReactionPickerView: View {
    let messageId: String
    let chatId: String
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var messageService: MessageService
    
    private let commonReactions = ["👍", "👎", "❤️", "😂", "😮", "😢", "😡", "🎉"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Reaction")
                    .font(.headline)
                    .padding(.top)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                    ForEach(commonReactions, id: \.self) { emoji in
                        Button(action: {
                            messageService.addReaction(messageId: messageId, chatId: chatId, emoji: emoji)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text(emoji)
                                .font(.title)
                                .frame(width: 50, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
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
