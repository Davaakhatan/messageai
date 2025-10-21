import SwiftUI

struct AddGroupMembersView: View {
    let chat: Chat
    @EnvironmentObject var messageService: MessageService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var selectedUsers: Set<String> = []
    @State private var isSearching = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // Get current participants to exclude them from search
    private var currentParticipantIds: Set<String> {
        Set(chat.participants)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search users by name or email", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .onChange(of: searchText) { _ in
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Selected Users Count
                if !selectedUsers.isEmpty {
                    Text("\(selectedUsers.count) user(s) selected")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal)
                }
                
                // Search Results
                if isSearching {
                    ProgressView("Searching...")
                        .padding()
                } else if searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Search for users to add")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Type a name or email to find users")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else if searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No users found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(searchResults) { user in
                            AddMemberUserRowView(
                                user: user,
                                isSelected: selectedUsers.contains(user.id),
                                isCurrentParticipant: currentParticipantIds.contains(user.id)
                            ) {
                                if currentParticipantIds.contains(user.id) {
                                    // Already in group
                                    return
                                }
                                
                                if selectedUsers.contains(user.id) {
                                    selectedUsers.remove(user.id)
                                } else {
                                    selectedUsers.insert(user.id)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Add Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addSelectedMembers()
                    }
                    .disabled(selectedUsers.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        Task {
            do {
                let results = try await messageService.searchUsers(query: searchText)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to search users: \(error.localizedDescription)"
                    showingError = true
                    isSearching = false
                }
            }
        }
    }
    
    private func addSelectedMembers() {
        guard !selectedUsers.isEmpty else { return }
        
        messageService.addParticipants(to: chat.id, userIds: Array(selectedUsers))
        dismiss()
    }
}

struct AddMemberUserRowView: View {
    let user: User
    let isSelected: Bool
    let isCurrentParticipant: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                    Text(user.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
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
                
                // Selection Indicator
                if isCurrentParticipant {
                    Text("Already in group")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isCurrentParticipant)
    }
}

#Preview {
    let sampleChat = Chat(
        participants: ["user1", "user2"],
        isGroup: true,
        groupName: "Team Devs"
    )
    
    return AddGroupMembersView(chat: sampleChat)
        .environmentObject(MessageService())
        .environmentObject(AuthService())
}

