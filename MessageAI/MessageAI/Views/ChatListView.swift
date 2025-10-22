import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var messageService: MessageService
    @EnvironmentObject var authService: AuthService
    @StateObject private var errorHandler = ErrorHandler()
    @State private var showingNewChat = false
    @State private var searchText = ""
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            VStack {
                if messageService.isLoading && messageService.chats.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading chats...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if messageService.chats.isEmpty {
                    EmptyChatsView {
                        showingNewChat = true
                    }
                } else {
                    List {
                        ForEach(filteredChats) { chat in
                            NavigationLink(destination: ChatView(chat: chat)) {
                                ChatRowView(chat: chat)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteChat(chat)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    muteChat(chat)
                                } label: {
                                    Label("Mute", systemImage: "bell.slash")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    markChatAsUnread(chat)
                                } label: {
                                    Label("Mark Unread", systemImage: "circle.fill")
                                }
                                .tint(.blue)
                                
                                Button {
                                    archiveChat(chat)
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                .tint(.purple)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await refreshChats()
                    }
                }
            }
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewChat = true }) {
                        Image(systemName: "square.and.pencil")
                            .font(.title2)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search chats")
            .sheet(isPresented: $showingNewChat) {
                NewChatView()
            }
            .onAppear {
                messageService.loadChats()
            }
            .withErrorHandling(errorHandler)
        }
    }
    
    private func refreshChats() async {
        isRefreshing = true
        messageService.loadChats()
        
        // Simulate refresh delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isRefreshing = false
    }
    
    private var filteredChats: [Chat] {
        if searchText.isEmpty {
            return messageService.chats
        } else {
            return messageService.chats.filter { chat in
                let name = chat.isGroup ? (chat.groupName ?? "Group Chat") : (messageService.chatUserNames[chat.id] ?? "")
                return name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Chat Actions
    
    private func deleteChat(_ chat: Chat) {
        withAnimation {
            messageService.deleteChat(chatId: chat.id)
        }
    }
    
    private func muteChat(_ chat: Chat) {
        // Future implementation: Mute chat notifications
        print("Mute chat: \(chat.id)")
        // Show temporary feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func markChatAsUnread(_ chat: Chat) {
        // Future implementation: Mark chat as unread
        print("Mark chat as unread: \(chat.id)")
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func archiveChat(_ chat: Chat) {
        // Future implementation: Archive chat
        print("Archive chat: \(chat.id)")
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct ChatRowView: View {
    let chat: Chat
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var messageService: MessageService
    @State private var isOnline = false
    
    private var displayName: String {
        if chat.isGroup {
            return chat.groupName ?? "Group Chat"
        } else {
            // Use cached user name if available, otherwise show loading or ID
            return messageService.chatUserNames[chat.id] ?? "Loading..."
        }
    }
    
    private var unreadCount: Int {
        messageService.chatUnreadCounts[chat.id] ?? 0
    }
    
    private var isUnread: Bool {
        unreadCount > 0
    }
    
    private var lastMessageText: String {
        guard let lastMessage = chat.lastMessage else { return "No messages yet" }
        
        // If message is too long, show truncated version with count
        if lastMessage.content.count > 50 {
            let truncated = String(lastMessage.content.prefix(47))
            return "\(truncated)..."
        }
        return lastMessage.content
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image with Online Status
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay {
                        if let profileImageURL = chat.groupImageURL {
                            AsyncImage(url: URL(string: profileImageURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: chat.isGroup ? "person.3.fill" : "person.fill")
                                    .foregroundColor(.blue)
                            }
                            .clipShape(Circle())
                        } else {
                            Image(systemName: chat.isGroup ? "person.3.fill" : "person.fill")
                                .foregroundColor(.blue)
                        }
                    }
                
                // Online indicator
                if !chat.isGroup && isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 18, y: 18)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(displayName)
                        .font(.headline)
                        .fontWeight(isUnread ? .bold : .medium)
                        .lineLimit(1)
                        .foregroundColor(isUnread ? .primary : .primary)
                    
                    Spacer()
                    
                    if let lastMessage = chat.lastMessage {
                        Text(formatTime(lastMessage.timestamp))
                            .font(.caption)
                            .foregroundColor(isUnread ? .blue : .secondary)
                    }
                }
                
                HStack {
                    if let lastMessage = chat.lastMessage {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(lastMessageText)
                                .font(.subheadline)
                                .fontWeight(isUnread ? .medium : .regular)
                                .foregroundColor(isUnread ? .primary : .secondary)
                                .lineLimit(2)
                            
                            // Show message count if there are multiple unread messages
                            if unreadCount > 1 {
                                Text("\(unreadCount) messages")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            // Unread badge
                            if unreadCount > 0 {
                                Text("\(unreadCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .clipShape(Capsule())
                            }
                            
                            // Delivery status indicator
                            if lastMessage.senderId == authService.currentUser?.id {
                                HStack(spacing: 2) {
                                    Image(systemName: lastMessage.deliveryStatus.checkmarkIcon)
                                        .font(.caption)
                                        .foregroundColor(lastMessage.deliveryStatus.displayColor)
                                    
                                    if lastMessage.deliveryStatus == .sending {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                    }
                                }
                            }
                        }
                    } else {
                        Text("No messages yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isUnread ? Color.blue.opacity(0.05) : Color.clear)
        )
        .onAppear {
            // Check online status for one-on-one chats
            if !chat.isGroup {
                checkOnlineStatus()
            }
        }
    }
    
    private func checkOnlineStatus() {
        // This would check the other user's online status
        // For now, we'll simulate it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isOnline = Bool.random() // Simulate online status
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            formatter.timeStyle = .short
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .short
        }
        
        return formatter.string(from: date)
    }
    
}

struct EmptyChatsView: View {
    let onCreateChat: () -> Void
    
    var body: some View {
        EmptyStateView(
            icon: "message.circle",
            title: "No Chats Yet",
            message: "Start a conversation by tapping the compose button",
            actionTitle: "Start Chatting",
            action: onCreateChat
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ChatListView()
        .environmentObject(MessageService())
        .environmentObject(AuthService())
        .onAppear {
            // Disable Firebase for previews
            // This prevents crashes in SwiftUI previews
        }
}
