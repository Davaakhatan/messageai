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
                chat.displayName(for: authService.currentUser?.id ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct ChatRowView: View {
    let chat: Chat
    @EnvironmentObject var authService: AuthService
    @State private var isOnline = false
    
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
                    Text(chat.displayName(for: authService.currentUser?.id ?? ""))
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let lastMessage = chat.lastMessage {
                        Text(formatTime(lastMessage.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    if let lastMessage = chat.lastMessage {
                        Text(lastMessage.content)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        // Delivery status indicator
                        if lastMessage.senderId == authService.currentUser?.id {
                            HStack(spacing: 2) {
                                Image(systemName: deliveryStatusIcon(lastMessage.deliveryStatus))
                                    .font(.caption)
                                    .foregroundColor(deliveryStatusColor(lastMessage.deliveryStatus))
                                
                                if lastMessage.deliveryStatus == .sending {
                                    ProgressView()
                                        .scaleEffect(0.6)
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
    
    private func deliveryStatusIcon(_ status: Message.DeliveryStatus) -> String {
        switch status {
        case .sending:
            return "clock"
        case .sent:
            return "checkmark"
        case .delivered:
            return "checkmark.circle"
        case .read:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle"
        }
    }
    
    private func deliveryStatusColor(_ status: Message.DeliveryStatus) -> Color {
        switch status {
        case .sending:
            return .orange
        case .sent:
            return .blue
        case .delivered:
            return .blue
        case .read:
            return .green
        case .failed:
            return .red
        }
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
