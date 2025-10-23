import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var settingsManager = SettingsManager.shared
    @State private var showingDeleteAlert = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Profile Header
                    profileHeader
                    
                    // MARK: - Quick Settings
                    quickSettingsCard
                    
                    // MARK: - Main Settings
                    mainSettingsCard
                    
                    // MARK: - Account Actions
                    accountActionsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Delete Account", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your data.")
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                Text((authService.currentUser?.displayName ?? "User").prefix(1).uppercased())
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(authService.currentUser?.displayName ?? "User")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(authService.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    // MARK: - Quick Settings
    private var quickSettingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickSettingButton(
                    icon: "bell.fill",
                    title: "Notifications",
                    isEnabled: settingsManager.notificationsEnabled,
                    color: .blue
                ) {
                    settingsManager.notificationsEnabled.toggle()
                }
                
                QuickSettingButton(
                    icon: "moon.fill",
                    title: "Dark Mode",
                    isEnabled: settingsManager.isDarkMode,
                    color: .purple
                ) {
                    settingsManager.isDarkMode.toggle()
                }
                
                QuickSettingButton(
                    icon: "brain.head.profile",
                    title: "AI Features",
                    isEnabled: settingsManager.aiFeaturesEnabled,
                    color: .green
                ) {
                    settingsManager.aiFeaturesEnabled.toggle()
                }
                
                QuickSettingButton(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Auto Sync",
                    isEnabled: settingsManager.autoSyncEnabled,
                    color: .orange
                ) {
                    settingsManager.autoSyncEnabled.toggle()
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
    
    // MARK: - Main Settings
    private var mainSettingsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Notifications Section
                SettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "Manage your notification preferences",
                    color: .blue
                ) {
                    NotificationSettingsView()
                }
                
                Divider().padding(.leading, 48)
                
                // Appearance Section
                SettingsRow(
                    icon: "paintbrush.fill",
                    title: "Appearance",
                    subtitle: "Customize your app's look and feel",
                    color: .purple
                ) {
                    AppearanceSettingsView()
                }
                
                Divider().padding(.leading, 48)
                
                // Privacy Section
                SettingsRow(
                    icon: "lock.shield.fill",
                    title: "Privacy & Security",
                    subtitle: "Control your privacy settings",
                    color: .green
                ) {
                    PrivacySettingsView()
                }
                
                Divider().padding(.leading, 48)
                
                // Storage Section
                SettingsRow(
                    icon: "externaldrive.fill",
                    title: "Storage",
                    subtitle: "Manage your app's storage usage",
                    color: .orange
                ) {
                    StorageSettingsView()
                }
                
                Divider().padding(.leading, 48)
                
                // Help Section
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    subtitle: "Get help and contact support",
                    color: .blue
                ) {
                    HelpSupportView()
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
    
    // MARK: - Account Actions
    private var accountActionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                Button(action: {
                    showingSignOutAlert = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.right.square.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sign Out")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Sign out of your account")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
                
                Divider().padding(.leading, 48)
                
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Delete Account")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                            
                            Text("Permanently delete your account")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
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

// MARK: - Supporting Components

struct QuickSettingButton: View {
    let icon: String
    let title: String
    let isEnabled: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isEnabled ? color.opacity(0.1) : Color.gray.opacity(0.1))
                        .frame(height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isEnabled ? color : .gray)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsRow<Destination: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let destination: () -> Destination
    
    var body: some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Settings Sub-Views

struct NotificationSettingsView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        List {
            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $settingsManager.notificationsEnabled)
                Toggle("Sound", isOn: $settingsManager.soundEnabled)
                    .disabled(!settingsManager.notificationsEnabled)
                Toggle("Vibration", isOn: $settingsManager.vibrationEnabled)
                    .disabled(!settingsManager.notificationsEnabled)
                Toggle("Show Preview", isOn: $settingsManager.notificationsEnabled)
                    .disabled(!settingsManager.notificationsEnabled)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AppearanceSettingsView: View {
    @StateObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        List {
            Section("Theme") {
                Toggle("Dark Mode", isOn: $settingsManager.isDarkMode)
            }
            
            Section("Typography") {
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
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StorageSettingsView: View {
    @State private var storageUsed: String = "24.5 MB"
    
    var body: some View {
        List {
            Section("Storage Usage") {
                HStack {
                    Text("Storage Used")
                    Spacer()
                    Text(storageUsed)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Actions") {
                Button("Clear Cache") {
                    clearCache()
                }
                .foregroundColor(.blue)
                
                Button("Manage Storage") {
                    manageStorage()
                }
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("Storage")
        .navigationBarTitleDisplayMode(.inline)
    }
    
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
        
        print("✅ Cache cleared successfully")
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
        
        storageUsed = sizeString
        print("📱 Storage usage: \(sizeString)")
    }
}

#Preview {
    NavigationView {
        SettingsView()
            .environmentObject(AuthService())
    }
}
