import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable, Equatable {
    let id: String
    let displayName: String
    let email: String
    let profileImageURL: String?
    let isOnline: Bool
    let lastSeen: Date
    let fcmToken: String?
    
    init(
        id: String,
        displayName: String,
        email: String,
        profileImageURL: String? = nil,
        isOnline: Bool = false,
        lastSeen: Date = Date(),
        fcmToken: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.profileImageURL = profileImageURL
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.fcmToken = fcmToken
    }
}

// MARK: - Firestore Extensions
extension User {
    init?(from document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let displayName = data["displayName"] as? String,
              let email = data["email"] as? String else {
            return nil
        }
        
        self.id = document.documentID
        self.displayName = displayName
        self.email = email
        self.profileImageURL = data["profileImageURL"] as? String
        self.isOnline = data["isOnline"] as? Bool ?? false
        self.lastSeen = (data["lastSeen"] as? Timestamp)?.dateValue() ?? Date()
        self.fcmToken = data["fcmToken"] as? String
    }
    
    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let displayName = data["displayName"] as? String,
              let email = data["email"] as? String else {
            return nil
        }
        
        self.id = document.documentID
        self.displayName = displayName
        self.email = email
        self.profileImageURL = data["profileImageURL"] as? String
        self.isOnline = data["isOnline"] as? Bool ?? false
        self.lastSeen = (data["lastSeen"] as? Timestamp)?.dateValue() ?? Date()
        self.fcmToken = data["fcmToken"] as? String
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "displayName": displayName,
            "email": email,
            "profileImageURL": profileImageURL as Any,
            "isOnline": isOnline,
            "lastSeen": Timestamp(date: lastSeen),
            "fcmToken": fcmToken as Any
        ]
    }
}

// MARK: - Current User Extension
extension User {
    static var current: User? {
        get {
            if let data = UserDefaults.standard.data(forKey: "currentUser"),
               let user = try? JSONDecoder().decode(User.self, from: data) {
                return user
            }
            return nil
        }
        set {
            if let user = newValue,
               let data = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(data, forKey: "currentUser")
            } else {
                UserDefaults.standard.removeObject(forKey: "currentUser")
            }
        }
    }
}
