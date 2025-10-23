import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // MARK: - Appearance Settings
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
            updateAppearance()
        }
    }
    
    @Published var fontSize: String {
        didSet {
            UserDefaults.standard.set(fontSize, forKey: "fontSize")
        }
    }
    
    // MARK: - Notification Settings
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
            updateNotificationSettings()
        }
    }
    
    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        }
    }
    
    @Published var vibrationEnabled: Bool {
        didSet {
            UserDefaults.standard.set(vibrationEnabled, forKey: "vibrationEnabled")
        }
    }
    
    // MARK: - AI & Sync Settings
    @Published var aiFeaturesEnabled: Bool {
        didSet {
            UserDefaults.standard.set(aiFeaturesEnabled, forKey: "aiFeaturesEnabled")
        }
    }
    
    @Published var autoSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoSyncEnabled, forKey: "autoSyncEnabled")
        }
    }
    
    // MARK: - Privacy & Security Settings
    @Published var privacyMode: Bool {
        didSet {
            UserDefaults.standard.set(privacyMode, forKey: "privacyMode")
        }
    }
    
    @Published var dataUsage: String {
        didSet {
            UserDefaults.standard.set(dataUsage, forKey: "dataUsage")
        }
    }
    
    @Published var autoDeleteMessages: Bool {
        didSet {
            UserDefaults.standard.set(autoDeleteMessages, forKey: "autoDeleteMessages")
        }
    }
    
    @Published var messageRetentionDays: Int {
        didSet {
            UserDefaults.standard.set(messageRetentionDays, forKey: "messageRetentionDays")
        }
    }
    
    // MARK: - Language & Region Settings
    @Published var language: String {
        didSet {
            UserDefaults.standard.set(language, forKey: "language")
        }
    }
    
    // MARK: - Computed Properties
    var currentFontSize: Font {
        switch fontSize {
        case "Small": return .caption
        case "Medium": return .body
        case "Large": return .title3
        default: return .body
        }
    }
    
    var currentColorScheme: ColorScheme? {
        return isDarkMode ? .dark : .light
    }
    
    // MARK: - Initialization
    private init() {
        // Load settings from UserDefaults
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.fontSize = UserDefaults.standard.string(forKey: "fontSize") ?? "Medium"
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        self.soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        self.vibrationEnabled = UserDefaults.standard.object(forKey: "vibrationEnabled") as? Bool ?? true
        self.aiFeaturesEnabled = UserDefaults.standard.object(forKey: "aiFeaturesEnabled") as? Bool ?? true
        self.autoSyncEnabled = UserDefaults.standard.object(forKey: "autoSyncEnabled") as? Bool ?? true
        self.privacyMode = UserDefaults.standard.bool(forKey: "privacyMode")
        self.dataUsage = UserDefaults.standard.string(forKey: "dataUsage") ?? "Standard"
        self.autoDeleteMessages = UserDefaults.standard.bool(forKey: "autoDeleteMessages")
        self.messageRetentionDays = UserDefaults.standard.object(forKey: "messageRetentionDays") as? Int ?? 30
        self.language = UserDefaults.standard.string(forKey: "language") ?? "English"
        
        // Apply initial settings
        updateAppearance()
    }
    
    // MARK: - Settings Actions
    private func updateAppearance() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.windows.first?.overrideUserInterfaceStyle = self.isDarkMode ? .dark : .light
            }
        }
    }
    
    private func updateNotificationSettings() {
        // In a real app, this would update the notification system
        print("🔔 Notification settings updated: \(notificationsEnabled)")
    }
    
    // MARK: - Reset Settings
    func resetToDefaults() {
        isDarkMode = false
        fontSize = "Medium"
        notificationsEnabled = true
        soundEnabled = true
        vibrationEnabled = true
        aiFeaturesEnabled = true
        autoSyncEnabled = true
        privacyMode = false
        dataUsage = "Standard"
        autoDeleteMessages = false
        messageRetentionDays = 30
        language = "English"
    }
    
    // MARK: - Export Settings
    func exportSettings() -> [String: Any] {
        return [
            "isDarkMode": isDarkMode,
            "fontSize": fontSize,
            "notificationsEnabled": notificationsEnabled,
            "soundEnabled": soundEnabled,
            "vibrationEnabled": vibrationEnabled,
            "aiFeaturesEnabled": aiFeaturesEnabled,
            "autoSyncEnabled": autoSyncEnabled,
            "privacyMode": privacyMode,
            "dataUsage": dataUsage,
            "autoDeleteMessages": autoDeleteMessages,
            "messageRetentionDays": messageRetentionDays,
            "language": language
        ]
    }
    
    // MARK: - Import Settings
    func importSettings(_ settings: [String: Any]) {
        if let value = settings["isDarkMode"] as? Bool { isDarkMode = value }
        if let value = settings["fontSize"] as? String { fontSize = value }
        if let value = settings["notificationsEnabled"] as? Bool { notificationsEnabled = value }
        if let value = settings["soundEnabled"] as? Bool { soundEnabled = value }
        if let value = settings["vibrationEnabled"] as? Bool { vibrationEnabled = value }
        if let value = settings["aiFeaturesEnabled"] as? Bool { aiFeaturesEnabled = value }
        if let value = settings["autoSyncEnabled"] as? Bool { autoSyncEnabled = value }
        if let value = settings["privacyMode"] as? Bool { privacyMode = value }
        if let value = settings["dataUsage"] as? String { dataUsage = value }
        if let value = settings["autoDeleteMessages"] as? Bool { autoDeleteMessages = value }
        if let value = settings["messageRetentionDays"] as? Int { messageRetentionDays = value }
        if let value = settings["language"] as? String { language = value }
    }
}
