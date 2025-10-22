import Foundation

// MARK: - AI Insight Models for Remote Team Professional

struct AIInsight: Codable, Identifiable {
    let id = UUID()
    let chatId: String
    let timestamp: Date
    let type: AIInsightType
    let content: String
    let confidence: Double
    let metadata: [String: String]
    
    init(chatId: String, type: AIInsightType, content: String, confidence: Double = 0.8, metadata: [String: String] = [:]) {
        self.chatId = chatId
        self.timestamp = Date()
        self.type = type
        self.content = content
        self.confidence = confidence
        self.metadata = metadata
    }
}

enum AIInsightType: String, Codable, CaseIterable {
    case meetingSummary = "meeting_summary"
    case actionItems = "action_items"
    case projectStatus = "project_status"
    case decision = "decision"
    case priority = "priority"
    case collaboration = "collaboration"
    case general = "general"
}

// MARK: - Meeting Summary Models

struct MeetingSummary: Codable, Identifiable {
    let id = UUID()
    let chatId: String
    let timestamp: Date
    let participants: [String]
    let agenda: [String]
    let keyPoints: [String]
    let actionItems: [ActionItem]
    let nextMeeting: String?
    let duration: TimeInterval?
    
    init(chatId: String, participants: [String], agenda: [String], keyPoints: [String], actionItems: [ActionItem], nextMeeting: String? = nil, duration: TimeInterval? = nil) {
        self.chatId = chatId
        self.timestamp = Date()
        self.participants = participants
        self.agenda = agenda
        self.keyPoints = keyPoints
        self.actionItems = actionItems
        self.nextMeeting = nextMeeting
        self.duration = duration
    }
}

struct ActionItem: Codable, Identifiable {
    let id = UUID()
    let description: String
    let assignee: String?
    let dueDate: Date?
    let priority: Priority
    let status: ActionStatus
    let createdAt: Date
    
    init(description: String, assignee: String? = nil, dueDate: Date? = nil, priority: Priority = .medium, status: ActionStatus = .pending) {
        self.description = description
        self.assignee = assignee
        self.dueDate = dueDate
        self.priority = priority
        self.status = status
        self.createdAt = Date()
    }
}

enum Priority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case urgent = "urgent"
}

enum ActionStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
}

// MARK: - Project Status Models

struct ProjectStatus: Codable, Identifiable {
    let id = UUID()
    let projectName: String
    let status: ProjectStatusType
    let progress: Double // 0.0 to 1.0
    let blockers: [String]
    let nextSteps: [String]
    let dependencies: [String]
    let lastUpdated: Date
    let teamMembers: [String]
    
    init(projectName: String, status: ProjectStatusType, progress: Double, blockers: [String] = [], nextSteps: [String] = [], dependencies: [String] = [], teamMembers: [String] = []) {
        self.projectName = projectName
        self.status = status
        self.progress = progress
        self.blockers = blockers
        self.nextSteps = nextSteps
        self.dependencies = dependencies
        self.lastUpdated = Date()
        self.teamMembers = teamMembers
    }
}

enum ProjectStatusType: String, Codable, CaseIterable {
    case onTrack = "on_track"
    case atRisk = "at_risk"
    case delayed = "delayed"
    case completed = "completed"
    case onHold = "on_hold"
}

// MARK: - Decision Tracking Models

struct Decision: Codable, Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let decisionMaker: String
    let participants: [String]
    let status: DecisionStatus
    let createdAt: Date
    let followUpDate: Date?
    let tags: [String]
    
    init(title: String, description: String, decisionMaker: String, participants: [String] = [], status: DecisionStatus = .active, followUpDate: Date? = nil, tags: [String] = []) {
        self.title = title
        self.description = description
        self.decisionMaker = decisionMaker
        self.participants = participants
        self.status = status
        self.createdAt = Date()
        self.followUpDate = followUpDate
        self.tags = tags
    }
}

enum DecisionStatus: String, Codable, CaseIterable {
    case active = "active"
    case implemented = "implemented"
    case reversed = "reversed"
    case expired = "expired"
}

// MARK: - Priority Message Models

struct PriorityMessage: Codable, Identifiable {
    let id = UUID()
    let messageId: String
    let priority: Priority
    let reason: String
    let suggestedAction: String
    let timestamp: Date
    
    init(messageId: String, priority: Priority, reason: String, suggestedAction: String) {
        self.messageId = messageId
        self.priority = priority
        self.reason = reason
        self.suggestedAction = suggestedAction
        self.timestamp = Date()
    }
}

// MARK: - Collaboration Insights Models

struct CollaborationInsight: Codable, Identifiable {
    let id = UUID()
    let chatId: String
    let insightType: CollaborationType
    let description: String
    let suggestions: [String]
    let participants: [String]
    let timestamp: Date
    
    init(chatId: String, insightType: CollaborationType, description: String, suggestions: [String], participants: [String] = []) {
        self.chatId = chatId
        self.insightType = insightType
        self.description = description
        self.suggestions = suggestions
        self.participants = participants
        self.timestamp = Date()
    }
}

enum CollaborationType: String, Codable, CaseIterable {
    case meetingOptimization = "meeting_optimization"
    case communicationPattern = "communication_pattern"
    case workloadBalance = "workload_balance"
    case skillGaps = "skill_gaps"
    case timeZoneOptimization = "timezone_optimization"
}

// MARK: - Search Result Models
// Note: SearchResult is already defined in SmartSearchService.swift
