import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var notificationsEnabled = true
    @State private var soundEnabled = true
    @State private var vibrationEnabled = true
    @State private var showPreview = true
    @State private var darkModeEnabled = false
    @State private var fontSize: Double = 16
    
    var body: some View {
        List {
            // MARK: - Notifications Section
            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                Toggle("Sound", isOn: $soundEnabled)
                    .disabled(!notificationsEnabled)
                Toggle("Vibration", isOn: $vibrationEnabled)
                    .disabled(!notificationsEnabled)
                Toggle("Show Preview", isOn: $showPreview)
                    .disabled(!notificationsEnabled)
            }
            
            // MARK: - Appearance Section
            Section("Appearance") {
                Toggle("Dark Mode", isOn: $darkModeEnabled)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Font Size")
                        Spacer()
                        Text("\(Int(fontSize))pt")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $fontSize, in: 12...20, step: 1)
                }
            }
            
            // MARK: - Privacy & Security Section
            Section("Privacy & Security") {
                NavigationLink(destination: PrivacySettingsView()) {
                    HStack {
                        Image(systemName: "lock.shield")
                            .foregroundColor(.blue)
                        Text("Privacy Settings")
                    }
                }
                
                NavigationLink(destination: BlockedUsersView()) {
                    HStack {
                        Image(systemName: "hand.raised")
                            .foregroundColor(.red)
                        Text("Blocked Users")
                    }
                }
            }
            
            // MARK: - Chat Settings Section
            Section("Chat Settings") {
                NavigationLink(destination: Text("Chat Backup")) {
                    HStack {
                        Image(systemName: "arrow.up.doc")
                            .foregroundColor(.green)
                        Text("Chat Backup")
                    }
                }
                
                NavigationLink(destination: Text("Archive Chats")) {
                    HStack {
                        Image(systemName: "archivebox")
                            .foregroundColor(.orange)
                        Text("Archived Chats")
                    }
                }
                
                Button(action: {
                    // Clear cache action
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Clear Cache")
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // MARK: - Storage Section
            Section("Storage") {
                HStack {
                    Text("Storage Used")
                    Spacer()
                    Text("24.5 MB")
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    // Manage storage action
                }) {
                    HStack {
                        Image(systemName: "externaldrive")
                            .foregroundColor(.blue)
                        Text("Manage Storage")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // MARK: - About Section
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                NavigationLink(destination: Text("Terms of Service")) {
                    Text("Terms of Service")
                }
                
                NavigationLink(destination: Text("Privacy Policy")) {
                    Text("Privacy Policy")
                }
            }
            
            // MARK: - Danger Zone
            Section {
                Button(action: {
                    // Delete account action
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text("Delete Account")
                            .foregroundColor(.red)
                    }
                }
            } footer: {
                Text("Deleting your account will permanently remove all your data and cannot be undone.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Privacy Settings View
struct PrivacySettingsView: View {
    @State private var lastSeenEnabled = true
    @State private var profilePhotoVisible = true
    @State private var statusVisible = true
    @State private var readReceiptsEnabled = true
    
    var body: some View {
        List {
            Section("Visibility") {
                Toggle("Last Seen", isOn: $lastSeenEnabled)
                Toggle("Profile Photo", isOn: $profilePhotoVisible)
                Toggle("Status", isOn: $statusVisible)
            }
            
            Section("Messaging") {
                Toggle("Read Receipts", isOn: $readReceiptsEnabled)
                Toggle("Typing Indicators", isOn: .constant(true))
            }
            
            Section {
                Text("When you disable read receipts, you won't be able to see read receipts from others.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Privacy")
    }
}

// MARK: - Blocked Users View
struct BlockedUsersView: View {
    @State private var blockedUsers: [String] = []
    
    var body: some View {
        List {
            if blockedUsers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "hand.raised.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No Blocked Users")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("When you block someone, they won't be able to send you messages.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(blockedUsers, id: \.self) { user in
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text(user)
                            .font(.body)
                        
                        Spacer()
                        
                        Button("Unblock") {
                            // Unblock action
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle("Blocked Users")
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(AuthService())
    }
}
