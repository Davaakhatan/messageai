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
            VStack {
                // Group Chat Toggle
                Toggle("Group Chat", isOn: $isGroup)
                    .padding(.horizontal)
                
                if isGroup {
                    TextField("Group Name", text: $groupName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                        .autocapitalization(.words)
                        .padding(.horizontal)
                }
                
                // Search Bar
                SearchBar(text: $searchText, onSearchButtonClicked: searchUsers)
                    .padding(.horizontal)
                
                // Selected Users
                if !selectedUsers.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(selectedUsers) { user in
                                SelectedUserChip(user: user) {
                                    removeUser(user)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Search Results
                if isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Text("No users found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(searchResults) { user in
                        UserRowView(user: user) {
                            if selectedUsers.contains(user) {
                                removeUser(user)
                            } else {
                                addUser(user)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createChat()
                    }
                    .disabled(selectedUsers.isEmpty)
                }
            }
        }
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
                    searchResults = results.filter { 
                        $0.id != currentUserId && !selectedUsers.contains($0)
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

struct SearchBar: View {
    @Binding var text: String
    let onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            TextField("Search users", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.default)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .onSubmit {
                    onSearchButtonClicked()
                }
            
            Button("Search", action: onSearchButtonClicked)
                .disabled(text.isEmpty)
        }
    }
}

struct UserRowView: View {
    let user: User
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay {
                    if let profileImageURL = user.profileImageURL {
                        AsyncImage(url: URL(string: profileImageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue)
                        }
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                    }
                }
            
            VStack(alignment: .leading) {
                Text(user.displayName)
                    .font(.headline)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

struct SelectedUserChip: View {
    let user: User
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(user.displayName)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.2))
        .cornerRadius(12)
    }
}

#Preview {
    NewChatView()
        .environmentObject(MessageService())
        .environmentObject(AuthService())
}
