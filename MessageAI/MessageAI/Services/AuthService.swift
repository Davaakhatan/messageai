import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()
    
    init() {
        // Skip Firebase initialization in preview mode
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }
        #endif
        
        // Add simulator-specific identifier for isolation
        #if targetEnvironment(simulator)
        let simulatorId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        print("🔧 Simulator ID: \(simulatorId)")
        #endif
        
        print("🔧 AuthService init - setting up auth state listener")
        setupAuthStateListener()
        
        // Test Firebase connection
        print("🔧 Testing Firebase connection...")
        db.collection("test").document("test").setData(["test": "value", "timestamp": Timestamp(date: Date())]) { error in
            if let error = error {
                print("❌ Firebase connection test failed: \(error.localizedDescription)")
                print("❌ Error code: \(error._code)")
                print("❌ Error domain: \(error._domain)")
            } else {
                print("✅ Firebase connection test successful")
            }
        }
        
        // Check if user is already authenticated
        if let currentUser = Auth.auth().currentUser {
            print("🔍 User already authenticated on init: \(currentUser.uid)")
            loadUserData(uid: currentUser.uid)
        } else {
            print("🔍 No user authenticated on init")
        }
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthStateListener() {
        print("🔧 Setting up auth state listener")
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            print("🔔 Auth state changed - user: \(user?.uid ?? "nil")")
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                if let user = user {
                    print("👤 User authenticated: \(user.uid), email: \(user.email ?? "no email")")
                    self?.loadUserData(uid: user.uid)
                } else {
                    print("❌ No user authenticated")
                    self?.currentUser = nil
                }
            }
        }
    }
    
    func checkAuthStatus() {
        print("🔍 Checking auth status...")
        isLoading = true
        if let user = Auth.auth().currentUser {
            print("✅ User already authenticated: \(user.uid), email: \(user.email ?? "no email")")
            loadUserData(uid: user.uid)
        } else {
            print("❌ No user currently authenticated")
            isLoading = false
        }
    }
    
    private func loadUserData(uid: String) {
        print("🔍 Loading user data for UID: \(uid)")
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Error loading user data: \(error.localizedDescription)")
                    print("❌ Error code: \(error._code)")
                    print("❌ Error domain: \(error._domain)")
                    self?.errorMessage = "Failed to load user data: \(error.localizedDescription)"
                    return
                }
                
                guard let document = document, document.exists else {
                    print("❌ User document not found for UID: \(uid)")
                    print("🔍 Document exists: \(document?.exists ?? false)")
                    print("🔍 Document ID: \(document?.documentID ?? "nil")")
                    self?.errorMessage = "User data not found - creating new user profile"
                    // Try to create user profile if it doesn't exist
                    self?.createUserProfileIfNeeded(uid: uid)
                    return
                }
                
                print("📄 User document data: \(document.data() ?? [:])")
                
                guard let user = User(from: document) else {
                    print("❌ Failed to parse user from document")
                    print("🔍 Raw document data: \(document.data() ?? [:])")
                    self?.errorMessage = "Failed to parse user data"
                    return
                }
                
                print("✅ Successfully loaded user: \(user.displayName) (\(user.email))")
                self?.currentUser = user
                User.current = user
                print("🔍 Current user set: \(self?.currentUser?.displayName ?? "nil")")
                
                // Reinitialize notification system for the new user
                ProductionNotificationManager.shared.reinitializeForNewUser()
            }
        }
    }
    
    func createUserProfileIfNeeded(uid: String) {
        print("🔧 Creating user profile for UID: \(uid)")
        guard let firebaseUser = Auth.auth().currentUser else {
            print("❌ No Firebase user found")
            return
        }
        
        let email = firebaseUser.email ?? "unknown@example.com"
        let displayName = firebaseUser.displayName ?? email.components(separatedBy: "@").first?.capitalized ?? "User"
        
        print("📧 Creating profile for email: \(email), displayName: \(displayName)")
        
        createOrUpdateUser(uid: uid, email: email, displayName: displayName)
    }
    
    func signIn(email: String, password: String) {
        print("🔐 Attempting sign in for: \(email)")
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ Sign in error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let result = result else {
                    print("❌ Sign in failed - no result")
                    self?.errorMessage = "Sign in failed"
                    return
                }
                
                print("✅ Sign in successful for UID: \(result.user.uid)")
                self?.createOrUpdateUser(uid: result.user.uid, email: email)
            }
        }
    }
    
    func signUp(email: String, password: String, displayName: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let result = result else {
                    self?.errorMessage = "Sign up failed"
                    return
                }
                
                self?.createOrUpdateUser(uid: result.user.uid, email: email, displayName: displayName)
            }
        }
    }
    
    private func createOrUpdateUser(uid: String, email: String, displayName: String? = nil) {
        // Create a more user-friendly display name
        let finalDisplayName: String
        if let displayName = displayName, !displayName.isEmpty {
            finalDisplayName = displayName
        } else {
            let emailPrefix = email.components(separatedBy: "@").first ?? "User"
            finalDisplayName = emailPrefix.capitalized
        }
        
        print("👤 Creating/updating user profile for UID: \(uid)")
        print("📧 Email: \(email)")
        print("🏷️ Display Name: \(finalDisplayName)")
        
        let userData: [String: Any] = [
            "email": email,
            "displayName": finalDisplayName,
            "isOnline": true,
            "lastSeen": Timestamp(date: Date()),
            "fcmToken": UserDefaults.standard.string(forKey: "fcmToken") as Any
        ]
        
        print("💾 Saving user data to Firestore: \(userData)")
        
        db.collection("users").document(uid).setData(userData, merge: true) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to save user profile: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to create user profile: \(error.localizedDescription)"
                    return
                }
                
                // Update UserService cache
                let user = User(
                    id: uid,
                    displayName: finalDisplayName,
                    email: email,
                    isOnline: true,
                    lastSeen: Date()
                )
                UserService.shared.users[uid] = user
                
                print("✅ User profile saved successfully")
                // Load the updated user data
                self?.loadUserData(uid: uid)
            }
        }
    }
    
    func signOut() {
        do {
            // Stop notification listening before signing out
            ProductionNotificationManager.shared.stopListeningForNotifications()
            
            try Auth.auth().signOut()
            currentUser = nil
            User.current = nil
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    func updateUserProfile(displayName: String, profileImageURL: String? = nil) {
        guard let currentUser = currentUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        var updateData: [String: Any] = [
            "displayName": displayName,
            "updatedAt": Timestamp(date: Date())
        ]
        
        if let profileImageURL = profileImageURL {
            updateData["profileImageURL"] = profileImageURL
        }
        
        db.collection("users").document(currentUser.id).updateData(updateData) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to update profile: \(error.localizedDescription)"
                    return
                }
                
                // Reload user data
                self?.loadUserData(uid: currentUser.id)
            }
        }
    }
    
    func updateOnlineStatus(_ isOnline: Bool) {
        guard let currentUser = currentUser else { return }
        
        db.collection("users").document(currentUser.id).updateData([
            "isOnline": isOnline,
            "lastSeen": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Failed to update online status: \(error.localizedDescription)")
            }
        }
    }
}
