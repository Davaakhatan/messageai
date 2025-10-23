import SwiftUI

struct NewChatView: View {
    @EnvironmentObject var messageService: MessageService
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var selectedUsers: [User] = []
    @State private var groupName = ""
    @State private var isGroup = false
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Chat Type Selection
                    chatTypeSection
                    
                    // Group Name Input (if group chat)
                    if isGroup {
                        groupNameSection
                    }
                    
                    // Search Section
                    searchSection
                    
                    // Selected Users
                    if !selectedUsers.isEmpty {
                        selectedUsersSection
                    }
                    
                    // Search Results
                    searchResultsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createChat()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedUsers.isEmpty || (isGroup && groupName.isEmpty))
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.message.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Start a Conversation")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create a new chat with friends or start a group conversation")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Chat Type Section
    private var chatTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Chat Type")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                // Direct Message Option
                ChatTypeCard(
                    icon: "person.2.fill",
                    title: "Direct Message",
                    subtitle: "Chat with one person",
                    isSelected: !isGroup,
                    color: .blue
                ) {
                    isGroup = false
                }
                
                // Group Chat Option
                ChatTypeCard(
                    icon: "person.3.fill",
                    title: "Group Chat",
                    subtitle: "Chat with multiple people",
                    isSelected: isGroup,
                    color: .green
                ) {
                    isGroup = true
                }
            }
        }
    }
    
    // MARK: - Group Name Section
    private var groupNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Group Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "textformat.abc")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    TextField("Enter group name", text: $groupName)
                        .font(.body)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Find People")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                TextField("Search by name or email", text: $searchText)
                    .font(.body)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit {
                        searchUsers()
                    }
                
                if !searchText.isEmpty {
                    Button("Search") {
                        searchUsers()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Selected Users Section
    private var selectedUsersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(selectedUsers.count) \(selectedUsers.count == 1 ? "person" : "people")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(selectedUsers) { user in
                        SelectedUserCard(user: user) {
                            removeUser(user)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Search Results Section
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isSearching {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Searching...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if searchResults.isEmpty && !searchText.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No users found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Try searching with a different name or email")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if !searchResults.isEmpty {
                Text("Search Results")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                LazyVStack(spacing: 8) {
                    ForEach(searchResults) { user in
                        UserCard(user: user) {
                            if selectedUsers.contains(user) {
                                removeUser(user)
                            } else {
                                addUser(user)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    private func searchUsers() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        Task {
            do {
                let results = try await messageService.searchUsers(query: searchText)
                await MainActor.run {
                    // Filter out current user and already selected users
                    let currentUserId = authService.currentUser?.id ?? ""
                    searchResults = results.filter { user in
                        user.id != currentUserId && !selectedUsers.contains(user)
                    }
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }
    
    private func addUser(_ user: User) {
        if !selectedUsers.contains(user) {
            selectedUsers.append(user)
        }
    }
    
    private func removeUser(_ user: User) {
        selectedUsers.removeAll { $0.id == user.id }
    }
    
    private func createChat() {
        let userIds = selectedUsers.map { $0.id }
        messageService.createChat(
            with: userIds,
            isGroup: isGroup,
            groupName: isGroup ? groupName : nil
        )
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Supporting Components

struct ChatTypeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? color.opacity(0.1) : Color.gray.opacity(0.1))
                        .frame(height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? color : .gray)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct UserCard: View {
    let user: User
    let onTap: () -> Void
    @State private var isSelected = false
    
    var body: some View {
        Button(action: {
            isSelected.toggle()
            onTap()
        }) {
            HStack(spacing: 12) {
                // Profile Image
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue, .purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    if let profileImageURL = user.profileImageURL {
                        AsyncImage(url: URL(string: profileImageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Text(user.displayName.prefix(1).uppercased())
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .clipShape(Circle())
                    } else {
                        Text(user.displayName.prefix(1).uppercased())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SelectedUserCard: View {
    let user: User
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 32, height: 32)
                
                if let profileImageURL = user.profileImageURL {
                    AsyncImage(url: URL(string: profileImageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Text(user.displayName.prefix(1).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .clipShape(Circle())
                } else {
                    Text(user.displayName.prefix(1).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Text(user.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    NewChatView()
        .environmentObject(MessageService())
        .environmentObject(AuthService())
}
