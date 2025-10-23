import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class UserService: ObservableObject {
    @Published var users: [String: User] = [:]
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var userListeners: [String: ListenerRegistration] = [:]
    
    static let shared = UserService()
    
    private init() {
        // Initialize with current user if available
        if let currentUser = Auth.auth().currentUser {
            fetchUser(userId: currentUser.uid)
        }
    }
    
    // MARK: - User Fetching
    
    func fetchUser(userId: String) {
        // Return cached user if available
        if let cachedUser = users[userId] {
            print("✅ User \(userId) already cached: \(cachedUser.displayName)")
            return
        }
        
        print("🔍 Fetching user \(userId) from Firestore...")
        
        // Fetch from Firestore
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let document = document,
                  document.exists,
                  let user = User(from: document) else {
                print("❌ Error fetching user \(userId): \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            print("✅ Successfully fetched user \(userId): \(user.displayName)")
            
            DispatchQueue.main.async {
                self?.users[userId] = user
            }
        }
    }
    
    func fetchUsers(userIds: [String]) {
        let uncachedIds = userIds.filter { users[$0] == nil }
        
        guard !uncachedIds.isEmpty else { return }
        
        // Batch fetch users
        for userId in uncachedIds {
            fetchUser(userId: userId)
        }
    }
    
    func getUserName(for userId: String) -> String {
        if let user = users[userId] {
            return user.displayName
        } else {
            // Fetch user if not cached
            fetchUser(userId: userId)
            return "User \(userId.prefix(8))"
        }
    }
    
    func getUserNameAsync(for userId: String, completion: @escaping (String) -> Void) {
        if let user = users[userId] {
            completion(user.displayName)
        } else {
            fetchUser(userId: userId)
            // Set up a listener for when the user is loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let user = self.users[userId] {
                    completion(user.displayName)
                } else {
                    completion("User \(userId.prefix(8))")
                }
            }
        }
    }
    
    // MARK: - User Management
    
    func createUser(user: User) {
        db.collection("users").document(user.id).setData(user.toDictionary()) { error in
            if let error = error {
                print("❌ Error creating user: \(error.localizedDescription)")
            } else {
                print("✅ User created successfully")
            }
        }
    }
    
    func updateUser(user: User) {
        db.collection("users").document(user.id).updateData(user.toDictionary()) { error in
            if let error = error {
                print("❌ Error updating user: \(error.localizedDescription)")
            } else {
                print("✅ User updated successfully")
            }
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        userListeners.values.forEach { $0.remove() }
    }
}
