import SwiftUI

struct ChatView: View {
    let chat: Chat
    @EnvironmentObject var messageService: MessageService
    @EnvironmentObject var authService: AuthService
    @State private var messageText = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingGroupInfo = false
    
    private var messages: [Message] {
        messageService.messages[chat.id] ?? []
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
                                isFromCurrentUser: message.senderId == authService.currentUser?.id
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
            }
            
            // Message Input
            MessageInputView(
                messageText: $messageText,
                onSend: sendMessage,
                onImageTap: { showingImagePicker = true }
            )
        }
        .navigationTitle(chat.displayName(for: authService.currentUser?.id ?? ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if chat.isGroup {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingGroupInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            messageService.loadMessages(for: chat.id)
            messageService.markAllMessagesAsRead(in: chat.id)
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
    @State private var showingTimestamp = false
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
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
                        .fill(isFromCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(isFromCurrentUser ? .white : .primary)
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
                        Image(systemName: deliveryStatusIcon(message.deliveryStatus))
                            .font(.caption2)
                            .foregroundColor(deliveryStatusColor(message.deliveryStatus))
                    }
                }
                .padding(.horizontal, 4)
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
