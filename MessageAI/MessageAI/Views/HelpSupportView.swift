import SwiftUI

struct HelpSupportView: View {
    @State private var searchText = ""
    @State private var showingContactSupport = false
    
    var body: some View {
        List {
            // MARK: - Search Bar Section
            Section {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search help articles", text: $searchText)
                        .autocapitalization(.none)
                }
            }
            
            // MARK: - Getting Started Section
            Section("Getting Started") {
                NavigationLink(destination: HelpArticleView(
                    title: "Creating Your First Chat",
                    content: """
                    To start a new conversation:
                    1. Tap the compose button (✏️) at the top right of the Chats screen
                    2. Search for a user by name or email
                    3. Select the user you want to chat with
                    4. Start typing your message!
                    
                    For group chats:
                    - Toggle "Create Group" switch
                    - Enter a group name
                    - Select multiple users
                    - Tap "Create" to start the group
                    """
                )) {
                    HelpRowView(icon: "message.badge.filled.fill", title: "Creating Your First Chat", iconColor: .blue)
                }
                
                NavigationLink(destination: HelpArticleView(
                    title: "Understanding Message Status",
                    content: """
                    Message delivery indicators:
                    
                    🕐 Clock - Message is sending
                    ✓ Single checkmark - Message sent to server
                    ✓✓ Double checkmark - Message delivered
                    ✓✓ Blue checkmarks - Message read
                    ⚠️ Warning - Message failed to send
                    
                    Tap and hold on any message to see detailed timestamp.
                    """
                )) {
                    HelpRowView(icon: "checkmark.circle", title: "Understanding Message Status", iconColor: .green)
                }
                
                NavigationLink(destination: HelpArticleView(
                    title: "Managing Your Profile",
                    content: """
                    To update your profile:
                    1. Go to the Profile tab
                    2. Tap "Edit Profile"
                    3. Update your display name
                    4. Tap the camera icon to change profile picture
                    5. Save your changes
                    
                    Your display name will be visible to all users in your chats.
                    """
                )) {
                    HelpRowView(icon: "person.circle", title: "Managing Your Profile", iconColor: .purple)
                }
            }
            
            // MARK: - Group Chats Section
            Section("Group Chats") {
                NavigationLink(destination: HelpArticleView(
                    title: "Creating a Group",
                    content: """
                    To create a group chat:
                    1. Tap the compose button (✏️)
                    2. Enable "Create Group" toggle
                    3. Enter a group name
                    4. Search and select members
                    5. Tap "Create"
                    
                    You will automatically become the group admin and creator.
                    """
                )) {
                    HelpRowView(icon: "person.3.fill", title: "Creating a Group", iconColor: .orange)
                }
                
                NavigationLink(destination: HelpArticleView(
                    title: "Adding Members",
                    content: """
                    Group admins can add new members:
                    1. Open the group chat
                    2. Tap the info button (ℹ️) at the top
                    3. Tap "Add Members"
                    4. Search and select users
                    5. Tap "Add"
                    
                    New members can see all previous messages in the group.
                    """
                )) {
                    HelpRowView(icon: "person.badge.plus", title: "Adding Members", iconColor: .green)
                }
                
                NavigationLink(destination: HelpArticleView(
                    title: "Admin Controls",
                    content: """
                    As a group admin, you can:
                    • Add new members
                    • Remove members (except the creator)
                    • Change group name
                    • Update group photo
                    • Leave the group
                    
                    The group creator can also:
                    • Delete the entire group
                    • Remove any admin
                    
                    These actions are permanent and cannot be undone.
                    """
                )) {
                    HelpRowView(icon: "shield.checkered", title: "Admin Controls", iconColor: .blue)
                }
            }
            
            // MARK: - AI Features Section
            Section("AI Assistant") {
                NavigationLink(destination: HelpArticleView(
                    title: "Team AI Features",
                    content: """
                    MessageAI includes AI-powered features for remote teams:
                    
                    📝 Meeting Summaries
                    Automatically summarize team discussions and extract action items
                    
                    📊 Project Status
                    Get AI-generated project status updates and identify blockers
                    
                    ✅ Decision Tracking
                    Track important team decisions with context and follow-ups
                    
                    ⚡ Priority Detection
                    AI identifies urgent messages and suggests actions
                    
                    🤝 Collaboration Insights
                    Get insights about team communication patterns
                    """
                )) {
                    HelpRowView(icon: "brain", title: "Team AI Features", iconColor: .purple)
                }
            }
            
            // MARK: - Privacy & Security Section
            Section("Privacy & Security") {
                NavigationLink(destination: HelpArticleView(
                    title: "Blocking Users",
                    content: """
                    To block someone:
                    1. Go to Profile > Settings
                    2. Tap "Privacy Settings"
                    3. Select "Blocked Users"
                    4. Add users to block
                    
                    Blocked users cannot:
                    • Send you messages
                    • See your online status
                    • View your profile updates
                    
                    You can unblock users at any time.
                    """
                )) {
                    HelpRowView(icon: "hand.raised", title: "Blocking Users", iconColor: .red)
                }
                
                NavigationLink(destination: HelpArticleView(
                    title: "Privacy Settings",
                    content: """
                    Control your privacy:
                    
                    Last Seen: Choose who can see when you were last online
                    Profile Photo: Control who can see your profile picture
                    Read Receipts: Enable/disable message read notifications
                    
                    Note: If you disable read receipts, you won't see them from others either.
                    """
                )) {
                    HelpRowView(icon: "lock.shield", title: "Privacy Settings", iconColor: .blue)
                }
            }
            
            // MARK: - Troubleshooting Section
            Section("Troubleshooting") {
                NavigationLink(destination: HelpArticleView(
                    title: "Messages Not Sending",
                    content: """
                    If messages aren't sending:
                    
                    1. Check your internet connection
                    2. Make sure you're logged in
                    3. Try force-closing and reopening the app
                    4. Check if the recipient blocked you
                    5. Clear app cache in Settings
                    
                    If issues persist, contact support.
                    """
                )) {
                    HelpRowView(icon: "exclamationmark.triangle", title: "Messages Not Sending", iconColor: .orange)
                }
                
                NavigationLink(destination: HelpArticleView(
                    title: "App Performance Issues",
                    content: """
                    To improve app performance:
                    
                    1. Clear cache (Settings > Clear Cache)
                    2. Archive old chats
                    3. Delete large media files
                    4. Update to the latest version
                    5. Restart your device
                    
                    Check storage usage in Settings > Storage.
                    """
                )) {
                    HelpRowView(icon: "gauge", title: "App Performance Issues", iconColor: .red)
                }
            }
            
            // MARK: - Contact Support Section
            Section {
                Button(action: {
                    showingContactSupport = true
                }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                        Text("Contact Support")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://messageai.com/faq")!) {
                    HStack {
                        Image(systemName: "safari")
                            .foregroundColor(.blue)
                        Text("Visit FAQ Website")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("MessageAI v1.0.0")
                    Text("© 2024 MessageAI. All rights reserved.")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Help & Support")
        .sheet(isPresented: $showingContactSupport) {
            ContactSupportView()
        }
    }
}

// MARK: - Help Row View
struct HelpRowView: View {
    let icon: String
    let title: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
        }
    }
}

// MARK: - Help Article View
struct HelpArticleView: View {
    let title: String
    let content: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Contact Support View
struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subject = ""
    @State private var message = ""
    @State private var category = "General"
    
    let categories = ["General", "Technical Issue", "Feature Request", "Account", "Billing", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Category") {
                    Picker("Select Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Subject") {
                    TextField("Brief description", text: $subject)
                        .autocapitalization(.sentences)
                }
                
                Section("Message") {
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                }
                
                Section {
                    Button(action: {
                        // Send support message
                        dismiss()
                    }) {
                        Text("Send Message")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(subject.isEmpty || message.isEmpty ? .gray : .blue)
                    }
                    .disabled(subject.isEmpty || message.isEmpty)
                }
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        HelpSupportView()
    }
}
