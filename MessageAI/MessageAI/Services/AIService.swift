import Foundation
import Combine
import OpenAI
import FirebaseFirestore
import FirebaseAuth

class AIService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var aiInsights: [String: AIInsight] = [:]
    
    // Remote Team Professional specific data
    @Published var meetingSummaries: [String: MeetingSummary] = [:]
    @Published var actionItems: [String: [ActionItem]] = [:]
    @Published var projectStatuses: [String: ProjectStatus] = [:]
    @Published var decisions: [String: [Decision]] = [:]
    @Published var priorityMessages: [String: [PriorityMessage]] = [:]
    @Published var collaborationInsights: [String: [CollaborationInsight]] = [:]
    
    private var openAI: OpenAI?
    private let db = Firestore.firestore()
    
    init() {
        // Initialize OpenAI with API key from UserDefaults or environment
        let apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
        if !apiKey.isEmpty {
            self.openAI = OpenAI(apiToken: apiKey)
        }
    }
    
    // MARK: - AI Processing Methods
    
    func processMessage(_ message: Message, in chatId: String) async {
        guard !message.content.isEmpty else { return }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Get conversation context
            let context = await getConversationContext(for: chatId)
            
            // Process with AI based on content
            let insight = try await analyzeMessage(message, context: context)
            
            // Store insight
            await MainActor.run {
                aiInsights[chatId] = insight
                isLoading = false
            }
            
            // Save to Firestore
            await saveAIInsight(chatId: chatId, insight: insight)
            
        } catch {
            await MainActor.run {
                errorMessage = "AI processing failed: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    func summarizeConversation(_ messages: [Message]) async throws -> String {
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        let prompt = await buildSummaryPrompt(context: messages)
        
        let response = try await callOpenAI(userInput: prompt)
        return response
    }
    
    func extractActionItems(_ messages: [Message]) async throws -> [String] {
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        let prompt = await buildActionItemsPrompt(context: messages)
        let response = try await callOpenAI(userInput: prompt)
        
        return parseActionItems(response)
    }
    
    // MARK: - Smart Search Implementation
    
    func performSmartSearch(query: String, in chats: [Chat]) async throws -> [SearchResult] {
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        // Get all messages from the chats
        var allMessages: [Message] = []
        for chat in chats {
            let messages = await getConversationContext(for: chat.id)
            allMessages.append(contentsOf: messages)
        }
        
        let conversationText = allMessages.map { "\($0.senderId): \($0.content)" }.joined(separator: "\n")
        
        let prompt = """
        Perform intelligent search on this conversation data based on the user's query.
        
        User Query: "\(query)"
        
        Conversation Data:
        \(conversationText)
        
        Find relevant messages, topics, or information that match the user's intent.
        Consider synonyms, related concepts, and context.
        
        Provide a JSON response:
        {
            "results": [
                {
                    "messageId": "message_id",
                    "chatId": "chat_id", 
                    "relevance": 0.0-1.0,
                    "summary": "brief summary of why this matches",
                    "context": "surrounding context"
                }
            ]
        }
        
        Only respond with JSON, no additional text.
        """
        
        let response = try await callOpenAI(userInput: prompt)
        return try parseSearchResults(response)
    }
    
    func translateMessage(_ message: String, to language: String) async throws -> String {
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        let prompt = "Translate the following message to \(language): \(message)"
        return try await callOpenAI(userInput: prompt)
    }
    
    // MARK: - Remote Team Professional AI Features
    
    // 1. Meeting Summary & Action Items
    func generateMeetingSummary(for chatId: String) async throws -> MeetingSummary {
        let context = await getConversationContext(for: chatId)
        let participants = Set(context.map { $0.senderId }).map { $0 }
        
        // Resolve user IDs to display names
        let userNames = await resolveUserNames(for: participants)
        let conversationText = context.map { message in
            let userName = userNames[message.senderId] ?? message.senderId
            return "\(userName): \(message.content)"
        }.joined(separator: "\n")
        
        let prompt = """
        Analyze this team conversation and provide a structured meeting summary. 
        Extract key points, action items, and next steps.
        
        Conversation:
        \(conversationText)
        
        Please provide a JSON response with the following structure:
        {
            "agenda": ["item1", "item2"],
            "keyPoints": ["point1", "point2"],
            "actionItems": [
                {
                    "description": "task description",
                    "assignee": "person name or null",
                    "dueDate": "YYYY-MM-DD or null",
                    "priority": "high/medium/low"
                }
            ],
            "nextMeeting": "suggestion for next meeting",
            "duration": 3600
        }
        """
        
        let response = try await callOpenAI(userInput: prompt)
        let summary = try parseMeetingSummary(from: response, chatId: chatId, participants: participants, userNames: userNames)
        
        await MainActor.run {
            meetingSummaries[chatId] = summary
        }
        
        return summary
    }
    
    // 2. Smart Project Status Updates
    func generateProjectStatus(for chatId: String, projectName: String) async throws -> ProjectStatus {
            let context = await getConversationContext(for: chatId)
        let participants = Set(context.map { $0.senderId }).map { $0 }
        
        // Resolve user IDs to display names
        let userNames = await resolveUserNames(for: participants)
        
        // Simulate AI analysis
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second delay
        
        // Convert participant IDs to display names
        let teamMemberNames = participants.compactMap { userNames[$0] ?? $0 }
        
        let status = ProjectStatus(
            projectName: projectName,
            status: .onTrack,
            progress: 0.65,
            blockers: ["Waiting for client feedback", "API integration pending"],
            nextSteps: ["Complete user testing", "Deploy to staging"],
            dependencies: ["Design approval", "Third-party service integration"],
            teamMembers: teamMemberNames
        )
        
        await MainActor.run {
            projectStatuses[chatId] = status
        }
        
        return status
    }
    
    // 3. Decision Tracking
    func extractDecisions(from chatId: String) async throws -> [Decision] {
            let context = await getConversationContext(for: chatId)
        let participants = Set(context.map { $0.senderId }).map { $0 }
        
        // Resolve user IDs to display names
        let userNames = await resolveUserNames(for: participants)
        let conversationText = context.map { message in
            let userName = userNames[message.senderId] ?? message.senderId
            return "\(userName): \(message.content)"
        }.joined(separator: "\n")
        
        let prompt = """
        Analyze this team conversation and extract any decisions that were made.
        Look for statements like "we decided", "let's go with", "I think we should", "agreed", etc.
        
        Conversation:
        \(conversationText)
        
        Provide a JSON response with decisions array:
        {
            "decisions": [
                {
                    "title": "decision title",
                    "description": "what was decided",
                    "decisionMaker": "who made the decision",
                    "status": "active/implemented/reversed/expired",
                    "followUpDate": "YYYY-MM-DD or null",
                    "tags": ["tag1", "tag2"]
                }
            ]
        }
        
        Only respond with JSON, no additional text.
        """
        
        let response = try await callOpenAI(userInput: prompt)
        let decisions = try parseDecisionsResponse(response, participants: Array(Set(context.map { $0.senderId })), userNames: userNames)
        
        await MainActor.run {
            self.decisions[chatId] = decisions
        }
        
        return decisions
    }
    
    // 4. Priority Message Detection
    func analyzeMessagePriority(_ message: Message, in chatId: String) async throws -> PriorityMessage? {
        let prompt = """
        Analyze this message for priority level and urgency. Consider context, tone, and content.
        
        Message: "\(message.content)"
        
        Determine if this message is:
        - urgent (requires immediate attention)
        - high (important but not urgent)
        - medium (normal priority)
        - low (can be addressed later)
        
        Provide a JSON response:
        {
            "priority": "urgent/high/medium/low",
            "reason": "explanation for the priority level",
            "suggestedAction": "recommended action"
        }
        
        Only respond with JSON, no additional text.
        """
        
        let response = try await callOpenAI(userInput: prompt)
        let priorityData = try parsePriorityResponse(response)
        
        if priorityData.priority == .low {
            return nil // Don't create priority messages for low priority
        }
        
        let priorityMessage = PriorityMessage(
            messageId: message.id,
            priority: priorityData.priority,
            reason: priorityData.reason,
            suggestedAction: priorityData.suggestedAction
        )
        
        await MainActor.run {
            if priorityMessages[chatId] == nil {
                priorityMessages[chatId] = []
            }
            priorityMessages[chatId]?.append(priorityMessage)
        }
        
        return priorityMessage
    }
    
    // 5. Team Collaboration Insights
    func generateCollaborationInsights(for chatId: String) async throws -> [CollaborationInsight] {
        let context = await getConversationContext(for: chatId)
        let participants = Array(Set(context.map { $0.senderId }))
        
        // Resolve user IDs to display names
        let userNames = await resolveUserNames(for: participants)
        let participantNames = participants.compactMap { userNames[$0] ?? $0 }
        
        // Simulate AI collaboration analysis
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
        
        let insights = [
            CollaborationInsight(
                chatId: chatId,
                insightType: .meetingOptimization,
                description: "Team communication patterns suggest optimal meeting time is 10 AM - 11 AM",
                suggestions: [
                    "Schedule recurring meetings during peak communication hours",
                    "Consider time zone differences for remote team members"
                ],
                participants: participantNames
            ),
            CollaborationInsight(
                chatId: chatId,
                insightType: .workloadBalance,
                description: "Some team members appear to be handling more communication load",
                suggestions: [
                    "Distribute meeting responsibilities more evenly",
                    "Consider rotating meeting facilitation roles"
                ],
                participants: participantNames
            )
        ]
        
        await MainActor.run {
            collaborationInsights[chatId] = insights
        }
        
        return insights
    }
    
    // MARK: - Private Methods
    
    private func analyzeMessage(_ message: Message, context: [Message]) async throws -> AIInsight {
        // Simulate AI analysis
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        return AIInsight(
            chatId: message.chatId,
            type: .general,
            content: "Message analyzed: '\(message.content)'",
            confidence: 0.8,
            metadata: ["sender": message.senderId, "timestamp": "\(message.timestamp)"]
        )
    }
    
    func getConversationContext(for chatId: String) async -> [Message] {
        return await withCheckedContinuation { continuation in
            db.collection("messages")
                .whereField("chatId", isEqualTo: chatId)
                .order(by: "timestamp", descending: false)
                .limit(to: 50)
                .getDocuments { snapshot, error in
                    let messages = snapshot?.documents.compactMap { Message(from: $0) } ?? []
                    continuation.resume(returning: messages)
                }
        }
    }
    
    private func buildSummaryPrompt(context: [Message]) async -> String {
        let participants = Set(context.map { $0.senderId }).map { $0 }
        let userNames = await resolveUserNames(for: participants)
        let messages = context.map { message in
            let userName = userNames[message.senderId] ?? message.senderId
            return "\(userName): \(message.content)"
        }.joined(separator: "\n")
        return "Conversation:\n\(messages)"
    }
    
    private func buildActionItemsPrompt(context: [Message]) async -> String {
        let participants = Set(context.map { $0.senderId }).map { $0 }
        let userNames = await resolveUserNames(for: participants)
        let messages = context.map { message in
            let userName = userNames[message.senderId] ?? message.senderId
            return "\(userName): \(message.content)"
        }.joined(separator: "\n")
        return "Extract action items from this conversation:\n\(messages)"
    }
    
    // MARK: - Response Parsing
    
    private func parseActionItems(_ response: String) -> [String] {
        do {
            if let data = response.data(using: .utf8),
               let items = try JSONSerialization.jsonObject(with: data) as? [String] {
                return items
            }
        } catch {
            print("Failed to parse action items: \(error)")
        }
        
        return []
    }
    
    private func parseMeetingSummary(from response: String, chatId: String, participants: [String], userNames: [String: String]) throws -> MeetingSummary {
        // Extract JSON from response (handle cases where AI adds extra text)
        let jsonStart = response.range(of: "{")
        let jsonEnd = response.range(of: "}", options: .backwards)
        
        guard let start = jsonStart?.lowerBound, let end = jsonEnd?.upperBound else {
            throw AIError.apiError("Invalid JSON response from AI")
        }
        
        let jsonString = String(response[start..<end])
        
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIError.apiError("Failed to parse JSON response")
        }
        
        let agenda = json["agenda"] as? [String] ?? []
        let keyPoints = json["keyPoints"] as? [String] ?? []
        let nextMeeting = json["nextMeeting"] as? String
        let duration = json["duration"] as? TimeInterval ?? 3600
        
        // Parse action items
        var actionItems: [ActionItem] = []
        if let actionItemsData = json["actionItems"] as? [[String: Any]] {
            for item in actionItemsData {
                let description = item["description"] as? String ?? ""
                let assignee = item["assignee"] as? String
                let priorityString = item["priority"] as? String ?? "medium"
                let priority = Priority(rawValue: priorityString) ?? .medium
                
                var dueDate: Date?
                if let dueDateString = item["dueDate"] as? String {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    dueDate = formatter.date(from: dueDateString)
                }
                
                actionItems.append(ActionItem(
                    description: description,
                    assignee: assignee,
                    dueDate: dueDate,
                    priority: priority
                ))
            }
        }
        
        // Convert participant IDs to display names
        let participantNames = participants.compactMap { userNames[$0] ?? $0 }
        
        return MeetingSummary(
            chatId: chatId,
            participants: participantNames,
            agenda: agenda,
            keyPoints: keyPoints,
            actionItems: actionItems,
            nextMeeting: nextMeeting,
            duration: duration
        )
    }
    
    private func parsePriorityResponse(_ response: String) throws -> (priority: Priority, reason: String, suggestedAction: String) {
        // Extract JSON from response
        let jsonStart = response.range(of: "{")
        let jsonEnd = response.range(of: "}", options: .backwards)
        
        guard let start = jsonStart?.lowerBound, let end = jsonEnd?.upperBound else {
            throw AIError.apiError("Invalid JSON response from AI")
        }
        
        let jsonString = String(response[start..<end])
        
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIError.apiError("Failed to parse JSON response")
        }
        
        let priorityString = json["priority"] as? String ?? "medium"
        let priority = Priority(rawValue: priorityString) ?? .medium
        let reason = json["reason"] as? String ?? "AI analysis"
        let suggestedAction = json["suggestedAction"] as? String ?? "Review message"
        
        return (priority: priority, reason: reason, suggestedAction: suggestedAction)
    }
    
    private func parseDecisionsResponse(_ response: String, participants: [String], userNames: [String: String]) throws -> [Decision] {
        // Extract JSON from response
        let jsonStart = response.range(of: "{")
        let jsonEnd = response.range(of: "}", options: .backwards)
        
        guard let start = jsonStart?.lowerBound, let end = jsonEnd?.upperBound else {
            throw AIError.apiError("Invalid JSON response from AI")
        }
        
        let jsonString = String(response[start..<end])
        
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIError.apiError("Failed to parse JSON response")
        }
        
        var decisions: [Decision] = []
        
        if let decisionsData = json["decisions"] as? [[String: Any]] {
            for decisionData in decisionsData {
                let title = decisionData["title"] as? String ?? "Untitled Decision"
                let description = decisionData["description"] as? String ?? ""
                let decisionMaker = decisionData["decisionMaker"] as? String ?? participants.first ?? "Unknown"
                let statusString = decisionData["status"] as? String ?? "active"
                let status = DecisionStatus(rawValue: statusString) ?? .active
                let tags = decisionData["tags"] as? [String] ?? []
                
                var followUpDate: Date?
                if let followUpDateString = decisionData["followUpDate"] as? String {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    followUpDate = formatter.date(from: followUpDateString)
                }
                
                // Convert participant IDs to display names
                let participantNames = participants.compactMap { userNames[$0] ?? $0 }
                
                let decision = Decision(
                    title: title,
                    description: description,
                    decisionMaker: decisionMaker,
                    participants: participantNames,
                    status: status,
                    followUpDate: followUpDate,
                    tags: tags
                )
                
                decisions.append(decision)
            }
        }
        
        return decisions
    }
    
    private func parseSearchResults(_ response: String) throws -> [SearchResult] {
        // Extract JSON from response
        let jsonStart = response.range(of: "{")
        let jsonEnd = response.range(of: "}", options: .backwards)
        
        guard let start = jsonStart?.lowerBound, let end = jsonEnd?.upperBound else {
            throw AIError.apiError("Invalid JSON response from AI")
        }
        
        let jsonString = String(response[start..<end])
        
        guard let data = jsonString.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIError.apiError("Failed to parse JSON response")
        }
        
        var results: [SearchResult] = []
        
        if let resultsData = json["results"] as? [[String: Any]] {
            for resultData in resultsData {
                let messageId = resultData["messageId"] as? String ?? ""
                let chatId = resultData["chatId"] as? String ?? ""
                let relevance = resultData["relevance"] as? Double ?? 0.0
                let summary = resultData["summary"] as? String ?? ""
                let context = resultData["context"] as? String ?? ""
                
                let result = SearchResult(
                    id: UUID().uuidString,
                    type: .message,
                    title: summary,
                    subtitle: context,
                    content: summary,
                    timestamp: Date(),
                    chatId: chatId,
                    metadata: ["relevance": "\(relevance)", "messageId": messageId]
                )
                
                results.append(result)
            }
        }
        
        return results
    }
    
    // MARK: - Firestore Integration
    
    private func saveAIInsight(chatId: String, insight: AIInsight) async {
        let data: [String: Any] = [
            "chatId": insight.chatId,
            "type": insight.type.rawValue,
            "content": insight.content,
            "confidence": insight.confidence,
            "metadata": insight.metadata,
            "timestamp": Timestamp(date: insight.timestamp)
        ]
        
        db.collection("aiInsights").document(chatId).setData(data, merge: true) { error in
            if let error = error {
                print("Failed to save AI insight: \(error.localizedDescription)")
            }
        }
    }
    
    func loadAIInsight(for chatId: String) async {
        db.collection("aiInsights").document(chatId).getDocument { [weak self] document, error in
            guard let document = document, document.exists,
                  let data = document.data() else { return }
            
            let insight = AIInsight(
                chatId: data["chatId"] as? String ?? chatId,
                type: AIInsightType(rawValue: data["type"] as? String ?? "general") ?? .general,
                content: data["content"] as? String ?? "",
                confidence: data["confidence"] as? Double ?? 0.8,
                metadata: data["metadata"] as? [String: String] ?? [:]
            )
            
            DispatchQueue.main.async {
                self?.aiInsights[chatId] = insight
            }
        }
    }
    
    // MARK: - API Key Management
    
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "openai_api_key")
        // Reinitialize OpenAI with new key
        self.openAI = OpenAI(apiToken: key)
        print("✅ OpenAI API key configured successfully")
    }
    
    private func callOpenAI(userInput: String) async throws -> String {
        guard let openAI = openAI else {
            throw AIError.noAPIKey
        }
        
        do {
            let query = ChatQuery(
                messages: [.user(.init(content: .string(userInput)))],
                model: .gpt3_5Turbo,
                temperature: 0.7
            )
            
            let result = try await openAI.chats(query: query)
            return result.choices.first?.message.content ?? "No response from AI"
        } catch {
            print("OpenAI API Error: \(error)")
            throw AIError.apiError(error.localizedDescription)
        }
    }
    
    // MARK: - User Name Resolution
    
    private func resolveUserNames(for userIds: [String]) async -> [String: String] {
        var userNames: [String: String] = [:]
        
        await withTaskGroup(of: (String, String?).self) { group in
            for userId in userIds {
                group.addTask {
                    let userName = await self.fetchUserName(for: userId)
                    return (userId, userName)
                }
            }
            
            for await (userId, userName) in group {
                if let userName = userName {
                    userNames[userId] = userName
                }
            }
        }
        
        return userNames
    }
    
    private func fetchUserName(for userId: String) async -> String? {
        return await withCheckedContinuation { continuation in
            db.collection("users").document(userId).getDocument { document, error in
                if let document = document, document.exists,
                   let data = document.data(),
                   let displayName = data["displayName"] as? String {
                    continuation.resume(returning: displayName)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    enum AIError: LocalizedError {
        case noAPIKey
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "OpenAI API key not configured"
            case .apiError(let message):
                return "OpenAI API error: \(message)"
            }
        }
    }
}