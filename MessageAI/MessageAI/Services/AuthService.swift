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
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                if let user = user {
                    self?.loadUserData(uid: user.uid)
                } else {
                    self?.currentUser = nil
                }
            }
        }
    }
    
    func checkAuthStatus() {
        isLoading = true
        if let user = Auth.auth().currentUser {
            loadUserData(uid: user.uid)
        } else {
            isLoading = false
        }
    }
    
    private func loadUserData(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to load user data: \(error.localizedDescription)"
                    return
                }
                
                guard let document = document, document.exists,
                      let user = User(from: document) else {
                    self?.errorMessage = "User data not found"
                    return
                }
                
                self?.currentUser = user
                User.current = user
            }
        }
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }
                
                guard let result = result else {
                    self?.errorMessage = "Sign in failed"
                    return
                }
                
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
        let userData: [String: Any] = [
            "email": email,
            "displayName": displayName ?? email.components(separatedBy: "@").first ?? "User",
            "isOnline": true,
            "lastSeen": Timestamp(date: Date()),
            "fcmToken": UserDefaults.standard.string(forKey: "fcmToken")
        ]
        
        db.collection("users").document(uid).setData(userData, merge: true) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to create user profile: \(error.localizedDescription)"
                    return
                }
                
                // Load the updated user data
                self?.loadUserData(uid: uid)
            }
        }
    }
    
    func signOut() {
        do {
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
