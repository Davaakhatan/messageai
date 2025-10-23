import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
            List {
            // MARK: - Notifications Section
            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $settingsManager.notificationsEnabled)
                Toggle("Sound", isOn: $settingsManager.soundEnabled)
                    .disabled(!settingsManager.notificationsEnabled)
                Toggle("Vibration", isOn: $settingsManager.vibrationEnabled)
                    .disabled(!settingsManager.notificationsEnabled)
                Toggle("Show Preview", isOn: $settingsManager.notificationsEnabled)
                    .disabled(!settingsManager.notificationsEnabled)
            }
            
            // MARK: - Appearance Section
            Section("Appearance") {
                Toggle("Dark Mode", isOn: $settingsManager.isDarkMode)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Font Size")
                        Spacer()
                        Text("\(settingsManager.fontSize)pt")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(settingsManager.fontSize) ?? 16 },
                        set: { settingsManager.fontSize = "\(Int($0))" }
                    ), in: 12...20, step: 1)
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
            
            // MARK: - AI Features Section
            Section("AI Features") {
                Toggle("Enable AI Features", isOn: $settingsManager.aiFeaturesEnabled)
                Toggle("Auto Sync", isOn: $settingsManager.autoSyncEnabled)
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
                    clearCache()
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
                    manageStorage()
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
                
                NavigationLink(destination: HelpSupportView()) {
                    Text("Help & Support")
                }
            }
            
            // MARK: - Account Actions
            Section {
                Button(action: {
                    signOut()
                }) {
                    HStack {
                        Image(systemName: "arrow.right.square")
                            .foregroundColor(.blue)
                        Text("Sign Out")
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // MARK: - Danger Zone
            Section {
                Button(action: {
                    deleteAccount()
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
    
    // MARK: - Functional Methods
    
    private func clearCache() {
        // Clear UserDefaults cache
        let defaults = UserDefaults.standard
        let keys = ["cachedMessages", "cachedChats", "cachedUsers"]
        for key in keys {
            defaults.removeObject(forKey: key)
        }
        
        // Clear temporary files
        let tempDir = FileManager.default.temporaryDirectory
        try? FileManager.default.removeItem(at: tempDir)
        
        // Show success message
        print("✅ Cache cleared successfully")
    }
    
    private func signOut() {
        authService.signOut()
    }
    
    private func manageStorage() {
        // Calculate storage usage
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        var totalSize: Int64 = 0
        
        // Calculate documents size
        if let enumerator = FileManager.default.enumerator(at: documentsPath, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }
        
        // Calculate cache size
        if let enumerator = FileManager.default.enumerator(at: cachePath, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        let sizeString = formatter.string(fromByteCount: totalSize)
        
        print("📱 Storage usage: \(sizeString)")
    }
    
    private func deleteAccount() {
        // Show confirmation alert
        let alert = UIAlertController(
            title: "Delete Account",
            message: "Are you sure you want to delete your account? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            // Delete user account
            if let user = Auth.auth().currentUser {
                user.delete { error in
                    if let error = error {
                        print("❌ Error deleting account: \(error.localizedDescription)")
                    } else {
                        print("✅ Account deleted successfully")
                        // Sign out after deletion
                        self.authService.signOut()
                    }
                }
            }
        })
        
        // Present alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
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
