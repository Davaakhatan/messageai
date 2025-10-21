import SwiftUI

struct UserInfoView: View {
    @EnvironmentObject var messageService: MessageService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    let chat: Chat
    
    @State private var otherUser: User?
    @State private var isLoadingUser = false
    @State private var showingBlockAlert = false
    @State private var showingDeleteChatAlert = false
    @State private var isMuted = false
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - User Profile Section
                Section {
                    if let user = otherUser {
                        HStack {
                            Spacer()
                            VStack(spacing: 16) {
                                // Profile Image
                                Circle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 100, height: 100)
                                    .overlay {
                                        if let profileImageURL = user.profileImageURL {
                                            AsyncImage(url: URL(string: profileImageURL)) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.blue)
                                            }
                                            .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                
                                // User Name
                                Text(user.displayName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                // Email
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                // Online Status
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(user.isOnline ? Color.green : Color.gray)
                                        .frame(width: 8, height: 8)
                                    Text(user.isOnline ? "Online" : "Offline")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    } else if isLoadingUser {
                        HStack {
                            Spacer()
                            ProgressView("Loading user info...")
                            Spacer()
                        }
                        .padding(.vertical, 40)
                    } else {
                        HStack {
                            Spacer()
                            Text("Unable to load user info")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 40)
                    }
                }
                .listRowBackground(Color.clear)
                
                // MARK: - Chat Actions Section
                Section {
                    Button(action: {
                        // Future: View shared media
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .foregroundColor(.blue)
                            Text("Media, Links & Docs")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Toggle(isOn: $isMuted) {
                        HStack {
                            Image(systemName: isMuted ? "bell.slash" : "bell")
                                .foregroundColor(isMuted ? .orange : .blue)
                            Text("Mute Notifications")
                        }
                    }
                    
                    Button(action: {
                        // Future: Search in conversation
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.blue)
                            Text("Search in Conversation")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // MARK: - Privacy Section
                Section("Privacy") {
                    Button(action: {
                        showingBlockAlert = true
                    }) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.red)
                            Text("Block User")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // MARK: - Delete Chat Section
                Section {
                    Button(action: {
                        showingDeleteChatAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Delete Chat")
                                .foregroundColor(.red)
                        }
                    }
                } footer: {
                    Text("Deleting this chat will remove all messages. This action cannot be undone.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Contact Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear(perform: loadOtherUser)
            .alert("Block User", isPresented: $showingBlockAlert) {
                Button("Block", role: .destructive) {
                    blockUser()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Blocked users cannot send you messages or see your online status. You can unblock them later in Settings.")
            }
            .alert("Delete Chat", isPresented: $showingDeleteChatAlert) {
                Button("Delete", role: .destructive) {
                    deleteChat()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this chat? All messages will be permanently removed.")
            }
        }
    }
    
    private func loadOtherUser() {
        isLoadingUser = true
        let currentUserId = authService.currentUser?.id ?? ""
        let otherUserIds = chat.participants.filter { $0 != currentUserId }
        
        guard let otherUserId = otherUserIds.first else {
            isLoadingUser = false
            return
        }
        
        Task {
            do {
                let users = try await messageService.getUsers(for: [otherUserId])
                await MainActor.run {
                    self.otherUser = users.first
                    self.isLoadingUser = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingUser = false
                    print("Error loading user: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func blockUser() {
        // Future implementation: Block user functionality
        print("Block user functionality - to be implemented")
        dismiss()
    }
    
    private func deleteChat() {
        messageService.deleteChat(chatId: chat.id)
        dismiss()
    }
}

#Preview {
    UserInfoView(chat: Chat(participants: ["user1", "user2"], isGroup: false))
        .environmentObject(MessageService())
        .environmentObject(AuthService())
}

