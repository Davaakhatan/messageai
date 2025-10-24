import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Search Result Models
struct SearchResult: Identifiable {
    let id: String
    let type: SearchResultType
    let title: String
    let subtitle: String
    let content: String
    let timestamp: Date
    let chatId: String?
    let metadata: [String: Any]
    
    enum SearchResultType: String, CaseIterable {
        case message = "message"
        case user = "user"
        case chat = "chat"
        case actionItem = "action_item"
        case decision = "decision"
        case meeting = "meeting"
    }
}

// MARK: - Search Filters
struct SearchFilters {
    var searchInMessages: Bool = true
    var searchInUsers: Bool = true
    var searchInChats: Bool = true
    var searchInActionItems: Bool = true
    var searchInDecisions: Bool = true
    var searchInMeetings: Bool = true
    var dateRange: DateRange? = nil
    var chatIds: [String]? = nil
    var senderIds: [String]? = nil
    
    enum DateRange: Hashable {
        case today
        case yesterday
        case thisWeek
        case thisMonth
        case custom(start: Date, end: Date)
    }
}

// MARK: - Smart Search Service
class SmartSearchService: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    @Published var searchQuery = ""
    @Published var searchFilters = SearchFilters()
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Auto-search when query changes
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                if !query.isEmpty {
                    self?.performSearch(query: query)
                } else {
                    self?.searchResults = []
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Main Search Function
    func performSearch(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        searchResults = []
        
        let searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Perform searches in parallel
        let group = DispatchGroup()
        var allResults: [SearchResult] = []
        
        if searchFilters.searchInMessages {
            group.enter()
            searchMessages(query: searchQuery) { results in
                allResults.append(contentsOf: results)
                group.leave()
            }
        }
        
        if searchFilters.searchInUsers {
            group.enter()
            searchUsers(query: searchQuery) { results in
                allResults.append(contentsOf: results)
                group.leave()
            }
        }
        
        if searchFilters.searchInChats {
            group.enter()
            searchChats(query: searchQuery) { results in
                allResults.append(contentsOf: results)
                group.leave()
            }
        }
        
        if searchFilters.searchInActionItems {
            group.enter()
            searchActionItems(query: searchQuery) { results in
                allResults.append(contentsOf: results)
                group.leave()
            }
        }
        
        if searchFilters.searchInDecisions {
            group.enter()
            searchDecisions(query: searchQuery) { results in
                allResults.append(contentsOf: results)
                group.leave()
            }
        }
        
        if searchFilters.searchInMeetings {
            group.enter()
            searchMeetings(query: searchQuery) { results in
                allResults.append(contentsOf: results)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // Sort results by relevance and timestamp
            self.searchResults = self.sortResults(allResults, for: searchQuery)
            self.isSearching = false
        }
    }
    
    // MARK: - Individual Search Functions
    
    private func searchMessages(query: String, completion: @escaping ([SearchResult]) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("🔍 Smart Search: No current user")
            completion([])
            return
        }
        
        print("🔍 Smart Search: Searching for '\(query)' in messages")
        
        // Get user's chat IDs first
        db.collection("chats")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Smart Search: Error getting chats: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let self = self,
                      let documents = snapshot?.documents else {
                    print("❌ Smart Search: No chat documents found")
                    completion([])
                    return
                }
                
                let chatIds = documents.map { $0.documentID }
                print("🔍 Smart Search: Found \(chatIds.count) chats: \(chatIds)")
                
                // Search in messages from user's chats
                self.db.collection("messages")
                    .whereField("chatId", in: chatIds)
                    .order(by: "timestamp", descending: true)
                    .limit(to: 100)
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print("❌ Smart Search: Error getting messages: \(error.localizedDescription)")
                            completion([])
                            return
                        }
                        
                        guard let documents = snapshot?.documents else {
                            print("❌ Smart Search: No message documents found")
                            completion([])
                            return
                        }
                        
                        print("🔍 Smart Search: Found \(documents.count) messages to search through")
                        
                        let results = documents.compactMap { doc -> SearchResult? in
                            let data = doc.data()
                            guard let content = data["content"] as? String,
                                  let senderId = data["senderId"] as? String,
                                  let chatId = data["chatId"] as? String,
                                  let timestamp = data["timestamp"] as? Timestamp else {
                                return nil
                            }
                            
                            // Check if content matches query
                            if content.lowercased().contains(query) {
                                print("✅ Smart Search: Found match in message: '\(content)'")
                                return SearchResult(
                                    id: doc.documentID,
                                    type: .message,
                                    title: "Message",
                                    subtitle: self.getSenderName(senderId: senderId),
                                    content: content,
                                    timestamp: timestamp.dateValue(),
                                    chatId: chatId,
                                    metadata: [
                                        "senderId": senderId,
                                        "messageId": doc.documentID
                                    ]
                                )
                            }
                            return nil
                        }
                        
                        print("🔍 Smart Search: Found \(results.count) matching messages")
                        completion(results)
                    }
            }
    }
    
    private func searchUsers(query: String, completion: @escaping ([SearchResult]) -> Void) {
        db.collection("users")
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let results = documents.compactMap { doc -> SearchResult? in
                    let data = doc.data()
                    guard let displayName = data["displayName"] as? String,
                          let email = data["email"] as? String else {
                        return nil
                    }
                    
                    // Check if name or email matches query
                    if displayName.lowercased().contains(query) || email.lowercased().contains(query) {
                        return SearchResult(
                            id: doc.documentID,
                            type: .user,
                            title: displayName,
                            subtitle: email,
                            content: "User Profile",
                            timestamp: Date(),
                            chatId: nil,
                            metadata: [
                                "userId": doc.documentID,
                                "email": email,
                                "isOnline": data["isOnline"] as? Bool ?? false
                            ]
                        )
                    }
                    return nil
                }
                
                completion(results)
            }
    }
    
    private func searchChats(query: String, completion: @escaping ([SearchResult]) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
        db.collection("chats")
            .whereField("participants", arrayContains: currentUserId)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let results = documents.compactMap { doc -> SearchResult? in
                    let data = doc.data()
                    guard let participants = data["participants"] as? [String],
                          let isGroup = data["isGroup"] as? Bool else {
                        return nil
                    }
                    
                    let chatName = data["name"] as? String ?? "Chat"
                    
                    // Check if chat name matches query
                    if chatName.lowercased().contains(query) {
                        return SearchResult(
                            id: doc.documentID,
                            type: .chat,
                            title: chatName,
                            subtitle: isGroup ? "Group Chat" : "Direct Message",
                            content: "Chat with \(participants.count) participants",
                            timestamp: Date(),
                            chatId: doc.documentID,
                            metadata: [
                                "isGroup": isGroup,
                                "participantCount": participants.count
                            ]
                        )
                    }
                    return nil
                }
                
                completion(results)
            }
    }
    
    private func searchActionItems(query: String, completion: @escaping ([SearchResult]) -> Void) {
        // This would search through AI-generated action items
        // For now, we'll search through messages that might contain action items
        searchMessages(query: query) { messageResults in
            let actionItemResults = messageResults.filter { result in
                let actionKeywords = ["todo", "task", "action", "assign", "due", "deadline", "follow up", "remember"]
                return actionKeywords.contains { keyword in
                    result.content.lowercased().contains(keyword)
                }
            }.map { result in
                SearchResult(
                    id: result.id + "_action",
                    type: .actionItem,
                    title: "Action Item",
                    subtitle: result.subtitle,
                    content: result.content,
                    timestamp: result.timestamp,
                    chatId: result.chatId,
                    metadata: result.metadata
                )
            }
            completion(actionItemResults)
        }
    }
    
    private func searchDecisions(query: String, completion: @escaping ([SearchResult]) -> Void) {
        // This would search through AI-generated decisions
        // For now, we'll search through messages that might contain decisions
        searchMessages(query: query) { messageResults in
            let decisionResults = messageResults.filter { result in
                let decisionKeywords = ["decide", "decision", "choose", "option", "vote", "agree", "disagree", "conclusion"]
                return decisionKeywords.contains { keyword in
                    result.content.lowercased().contains(keyword)
                }
            }.map { result in
                SearchResult(
                    id: result.id + "_decision",
                    type: .decision,
                    title: "Decision",
                    subtitle: result.subtitle,
                    content: result.content,
                    timestamp: result.timestamp,
                    chatId: result.chatId,
                    metadata: result.metadata
                )
            }
            completion(decisionResults)
        }
    }
    
    private func searchMeetings(query: String, completion: @escaping ([SearchResult]) -> Void) {
        // This would search through AI-generated meeting summaries
        // For now, we'll search through messages that might contain meeting-related content
        searchMessages(query: query) { messageResults in
            let meetingResults = messageResults.filter { result in
                let meetingKeywords = ["meeting", "call", "zoom", "teams", "schedule", "agenda", "minutes", "discuss"]
                return meetingKeywords.contains { keyword in
                    result.content.lowercased().contains(keyword)
                }
            }.map { result in
                SearchResult(
                    id: result.id + "_meeting",
                    type: .meeting,
                    title: "Meeting",
                    subtitle: result.subtitle,
                    content: result.content,
                    timestamp: result.timestamp,
                    chatId: result.chatId,
                    metadata: result.metadata
                )
            }
            completion(meetingResults)
        }
    }
    
    // MARK: - Helper Functions
    
    private func getSenderName(senderId: String) -> String {
        // Use UserService to get the actual user name
        return UserService.shared.getUserName(for: senderId)
    }
    
    private func sortResults(_ results: [SearchResult], for query: String) -> [SearchResult] {
        return results.sorted { first, second in
            // Sort by relevance first (exact matches, then partial matches)
            let firstRelevance = calculateRelevance(first, query: query)
            let secondRelevance = calculateRelevance(second, query: query)
            
            if firstRelevance != secondRelevance {
                return firstRelevance > secondRelevance
            }
            
            // Then sort by timestamp (newest first)
            return first.timestamp > second.timestamp
        }
    }
    
    private func calculateRelevance(_ result: SearchResult, query: String) -> Int {
        var score = 0
        
        // Exact match in title gets highest score
        if result.title.lowercased().contains(query) {
            score += 100
        }
        
        // Exact match in content gets medium score
        if result.content.lowercased().contains(query) {
            score += 50
        }
        
        // Partial match gets lower score
        if result.subtitle.lowercased().contains(query) {
            score += 25
        }
        
        // Recent results get slight boost
        let daysSinceResult = Calendar.current.dateComponents([.day], from: result.timestamp, to: Date()).day ?? 0
        if daysSinceResult < 7 {
            score += 10
        }
        
        return score
    }
    
    // MARK: - Public Methods
    
    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
    
    func updateFilters(_ newFilters: SearchFilters) {
        searchFilters = newFilters
        if !searchQuery.isEmpty {
            performSearch(query: searchQuery)
        }
    }
}
