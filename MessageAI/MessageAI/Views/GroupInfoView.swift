import SwiftUI

struct GroupInfoView: View {
    let chat: Chat
    @EnvironmentObject var messageService: MessageService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var groupName: String
    @State private var isEditingName = false
    @State private var showingAddMembers = false
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var memberUsers: [User] = []
    @State private var isLoadingMembers = true
    @State private var showingLeaveAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingRemoveMemberAlert = false
    @State private var memberToRemove: User?
    
    init(chat: Chat) {
        self.chat = chat
        _groupName = State(initialValue: chat.groupName ?? "Group Chat")
    }
    
    var currentUserId: String {
        authService.currentUser?.id ?? ""
    }
    
    var isCurrentUserAdmin: Bool {
        chat.isAdmin(userId: currentUserId)
    }
    
    var isCurrentUserCreator: Bool {
        chat.isCreator(userId: currentUserId)
    }
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Group Header Section
                Section {
                    VStack(spacing: 16) {
                        // Group Image
                        Button(action: {
                            if isCurrentUserAdmin {
                                showingImagePicker = true
                            }
                        }) {
                            ZStack(alignment: .bottomTrailing) {
                                if let groupImageURL = chat.groupImageURL, !groupImageURL.isEmpty {
                                    AsyncImage(url: URL(string: groupImageURL)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Image(systemName: "person.3.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .foregroundColor(.white)
                                            .padding(30)
                                            .background(Color.blue)
                                    }
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.3.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.white)
                                        .padding(30)
                                        .background(Color.blue)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                }
                                
                                if isCurrentUserAdmin {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!isCurrentUserAdmin)
                        
                        // Group Name
                        if isEditingName {
                            HStack {
                                TextField("Group Name", text: $groupName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .multilineTextAlignment(.center)
                                
                                Button("Save") {
                                    saveGroupName()
                                    isEditingName = false
                                }
                                .foregroundColor(.blue)
                            }
                            .padding(.horizontal)
                        } else {
                            HStack {
                                Text(groupName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                if isCurrentUserAdmin {
                                    Button(action: { isEditingName = true }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                        
                        Text("\(chat.participants.count) members")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)
                
                // MARK: - Group Actions Section
                Section("Group Actions") {
                    if isCurrentUserAdmin {
                        Button(action: {
                            showingAddMembers = true
                        }) {
                            Label("Add Members", systemImage: "person.badge.plus")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button(action: {
                        // TODO: Navigate to media gallery
                    }) {
                        Label("Media, Links & Docs", systemImage: "photo.on.rectangle.angled")
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        // TODO: Toggle mute notifications
                    }) {
                        Label("Mute Notifications", systemImage: "bell.slash")
                            .foregroundColor(.primary)
                    }
                }
                
                // MARK: - Members Section
                Section("Members (\(memberUsers.count))") {
                    if isLoadingMembers {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        ForEach(memberUsers) { user in
                            MemberRowView(
                                user: user,
                                isAdmin: chat.isAdmin(userId: user.id),
                                isCreator: chat.isCreator(userId: user.id),
                                canRemove: isCurrentUserAdmin && user.id != currentUserId && !chat.isCreator(userId: user.id)
                            ) {
                                memberToRemove = user
                                showingRemoveMemberAlert = true
                            }
                        }
                    }
                }
                
                // MARK: - Danger Zone Section
                Section {
                    Button(action: {
                        showingLeaveAlert = true
                    }) {
                        Label("Leave Group", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                    
                    if isCurrentUserCreator {
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Label("Delete Group", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    if isCurrentUserCreator {
                        Text("As the creator, you can delete this group for everyone.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Group Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddMembers) {
                AddGroupMembersView(chat: chat)
                    .environmentObject(messageService)
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showingImagePicker) {
                CustomImagePicker(selectedImage: $selectedImage)
            }
            .alert("Leave Group", isPresented: $showingLeaveAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Leave", role: .destructive) {
                    leaveGroup()
                }
            } message: {
                Text("Are you sure you want to leave this group? You can be added back by any admin.")
            }
            .alert("Delete Group", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteGroup()
                }
            } message: {
                Text("Are you sure you want to delete this group? This action cannot be undone and will remove the group for all members.")
            }
            .alert("Remove Member", isPresented: $showingRemoveMemberAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    if let member = memberToRemove {
                        removeMember(member)
                    }
                }
            } message: {
                Text("Are you sure you want to remove \(memberToRemove?.displayName ?? "this member") from the group?")
            }
            .onAppear {
                loadMembers()
            }
            .onChange(of: selectedImage) { image in
                if let image = image {
                    updateGroupImage(image)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadMembers() {
        isLoadingMembers = true
        Task {
            do {
                let users = try await messageService.getUsers(for: chat.participants)
                await MainActor.run {
                    memberUsers = users.sorted { user1, user2 in
                        // Sort: Creator first, then admins, then others
                        if chat.isCreator(userId: user1.id) { return true }
                        if chat.isCreator(userId: user2.id) { return false }
                        if chat.isAdmin(userId: user1.id) && !chat.isAdmin(userId: user2.id) { return true }
                        if !chat.isAdmin(userId: user1.id) && chat.isAdmin(userId: user2.id) { return false }
                        return user1.displayName < user2.displayName
                    }
                    isLoadingMembers = false
                }
            } catch {
                await MainActor.run {
                    isLoadingMembers = false
                }
            }
        }
    }
    
    private func saveGroupName() {
        messageService.updateGroupName(chatId: chat.id, newName: groupName)
    }
    
    private func updateGroupImage(_ image: UIImage) {
        // TODO: Upload image to Firebase Storage and update group
        // For now, just show a placeholder
        selectedImage = nil
    }
    
    private func removeMember(_ user: User) {
        messageService.removeParticipant(from: chat.id, userId: user.id)
        memberUsers.removeAll { $0.id == user.id }
        memberToRemove = nil
    }
    
    private func leaveGroup() {
        messageService.removeParticipant(from: chat.id, userId: currentUserId)
        dismiss()
    }
    
    private func deleteGroup() {
        messageService.deleteChat(chatId: chat.id)
        dismiss()
    }
}

// MARK: - Member Row View
struct MemberRowView: View {
    let user: User
    let isAdmin: Bool
    let isCreator: Bool
    let canRemove: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let profileImageURL = user.profileImageURL, !profileImageURL.isEmpty {
                AsyncImage(url: URL(string: profileImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user.displayName)
                        .font(.headline)
                    
                    if isCreator {
                        Text("Creator")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    } else if isAdmin {
                        Text("Admin")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if user.isOnline {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Online")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            // Remove Button
            if canRemove {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let sampleChat = Chat(
        participants: ["user1", "user2", "user3"],
        isGroup: true,
        groupName: "Team Devs",
        createdBy: "user1",
        admins: ["user1"]
    )
    
    return GroupInfoView(chat: sampleChat)
        .environmentObject(MessageService())
        .environmentObject(AuthService())
}

