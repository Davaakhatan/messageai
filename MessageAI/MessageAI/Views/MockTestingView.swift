import SwiftUI

struct MockTestingView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var messageService: MessageService
    @State private var isOnline = false
    @State private var mockMessages: [MockMessage] = []
    @State private var autoMessageTimer: Timer?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MessageAI Testing Lab")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Test messaging features, AI capabilities, and edge cases for MessageAI.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Connection Status Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Connection Status")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        HStack {
                            Circle()
                                .fill(isOnline ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text(isOnline ? "Online" : "Offline")
                                .foregroundColor(isOnline ? .green : .red)
                            
                            Spacer()
                            
                            Button(isOnline ? "Go Offline" : "Go Online") {
                                isOnline.toggle()
                                messageService.setOfflineMode(!isOnline)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Message Management Controls
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Message Management")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            Button("Mark All Read") {
                                markAllAsRead()
                            }
                            .buttonStyle(TestButtonStyle())
                            
                            Button("Mark All Unread") {
                                markAllAsUnread()
                            }
                            .buttonStyle(TestButtonStyle())
                            
                            Button("Clear Messages") {
                                clearAllMessages()
                            }
                            .buttonStyle(TestButtonStyle())
                            
                            Button("Delete Failed") {
                                deleteFailedMessages()
                            }
                            .buttonStyle(TestButtonStyle())
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Notification Testing
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notification Testing")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Button("Test Notification") {
                            ProductionNotificationManager.shared.testNotification()
                        }
                        .buttonStyle(TestButtonStyle())
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Message Type Testing
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Message Types")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            Button("Text Message") {
                                addMockMessage(type: .text)
                            }
                            .buttonStyle(TestButtonStyle())
                            
                            Button("AI Response") {
                                addMockMessage(type: .aiResponse)
                            }
                            .buttonStyle(TestButtonStyle())
                            
                            Button("Image Message") {
                                addMockMessage(type: .image)
                            }
                            .buttonStyle(TestButtonStyle())
                            
                            Button("Voice Message") {
                                addMockMessage(type: .voice)
                            }
                            .buttonStyle(TestButtonStyle())
                            
                            Button("File Message") {
                                addMockMessage(type: .file)
                            }
                            .buttonStyle(TestButtonStyle())
                            
                            Button("Location") {
                                addMockMessage(type: .location)
                            }
                            .buttonStyle(TestButtonStyle())
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    
                    // Priority Testing
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Priority Testing")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            Button("Low Priority") {
                                addPriorityMessage(.low)
                            }
                            .buttonStyle(TestButtonStyle())
                            
                            Button("Normal Priority") {
                                addPriorityMessage(.normal)
                            }
                            .buttonStyle(TestButtonStyle())
                            
                            Button("High Priority") {
                                addPriorityMessage(.high)
                            }
                            .buttonStyle(TestButtonStyle())
                            
                            Button("Urgent Message") {
                                addPriorityMessage(.urgent)
                            }
                            .buttonStyle(TestButtonStyle())
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 1)
                    .padding(.horizontal)
                    
                    // MessageAI Core Features Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MessageAI Core Features")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            MockScenarioButton(
                                title: "AI Summary",
                                icon: "brain.head.profile",
                                color: .purple,
                                action: { simulateAISummary() }
                            )
                            
                            MockScenarioButton(
                                title: "Smart Search",
                                icon: "magnifyingglass.circle",
                                color: .blue,
                                action: { simulateSmartSearch() }
                            )
                            
                            MockScenarioButton(
                                title: "Priority Detection",
                                icon: "exclamationmark.triangle",
                                color: .orange,
                                action: { simulatePriorityDetection() }
                            )
                            
                            MockScenarioButton(
                                title: "Action Items",
                                icon: "checklist",
                                color: .green,
                                action: { simulateActionItems() }
                            )
                            
                            MockScenarioButton(
                                title: "Team Insights",
                                icon: "person.3",
                                color: .cyan,
                                action: { simulateTeamInsights() }
                            )
                            
                            MockScenarioButton(
                                title: "Decision Tracking",
                                icon: "target",
                                color: .indigo,
                                action: { simulateDecisionTracking() }
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 1)
                    .padding(.horizontal)
                    
                    // MessageAI Edge Cases Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MessageAI Edge Cases")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 12) {
                            PresetScenarioButton(
                                title: "Long Messages",
                                icon: "text.alignleft",
                                color: .blue,
                                action: { simulateLongMessages() }
                            )
                            
                            PresetScenarioButton(
                                title: "AI Errors",
                                icon: "brain.head.profile",
                                color: .red,
                                action: { simulateAIErrors() }
                            )
                            
                            PresetScenarioButton(
                                title: "Network Issues",
                                icon: "wifi.slash",
                                color: .orange,
                                action: { simulateNetworkIssues() }
                            )
                            
                            PresetScenarioButton(
                                title: "Load Test",
                                icon: "speedometer",
                                color: .green,
                                action: { simulateLoadTest() }
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 1)
                    .padding(.horizontal)
                    
                    // MessageAI Test Results Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("MessageAI Test Results (\(mockMessages.count))")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        if mockMessages.isEmpty {
                            Text("No mock messages yet")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(mockMessages) { message in
                                MockMessageRow(message: message)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 1)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Mock Testing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - MessageAI Test Actions
    
    private func simulateAISummary() {
        let message = MockMessage(
            content: "🤖 AI Summary: Meeting discussed Q4 goals, budget approval needed, next review on Friday",
            sender: "MessageAI Assistant",
            timestamp: Date(),
            status: .aiGenerated
        )
        mockMessages.append(message)
    }
    
    private func simulateSmartSearch() {
        let message = MockMessage(
            content: "🔍 Smart Search: Found 3 messages about 'budget' from last week",
            sender: "MessageAI Search",
            timestamp: Date(),
            status: .searchResult
        )
        mockMessages.append(message)
    }
    
    private func simulatePriorityDetection() {
        let message = MockMessage(
            content: "⚠️ Priority Alert: Message contains urgent keywords: 'deadline', 'ASAP'",
            sender: "MessageAI Priority",
            timestamp: Date(),
            status: .priority
        )
        mockMessages.append(message)
    }
    
    private func simulateActionItems() {
        let message = MockMessage(
            content: "✅ Action Items: 1) Review budget proposal 2) Schedule team meeting 3) Update project timeline",
            sender: "MessageAI Actions",
            timestamp: Date(),
            status: .actionItem
        )
        mockMessages.append(message)
    }
    
    private func simulateTeamInsights() {
        let message = MockMessage(
            content: "👥 Team Insights: Sarah is most active, 5 unread messages from John, meeting participation: 85%",
            sender: "MessageAI Analytics",
            timestamp: Date(),
            status: .insight
        )
        mockMessages.append(message)
    }
    
    private func simulateDecisionTracking() {
        let message = MockMessage(
            content: "🎯 Decision Tracked: 'Use React for frontend' - Status: Approved by 3/4 team members",
            sender: "MessageAI Decisions",
            timestamp: Date(),
            status: .decision
        )
        mockMessages.append(message)
    }
    
    private func simulateLongMessages() {
        let longContent = "This is a very long message to test how MessageAI handles extensive content. It includes multiple paragraphs, detailed information, and various formatting elements. The AI should be able to summarize this effectively and extract key insights. This tests the system's ability to process large amounts of text while maintaining performance and accuracy."
        
        let message = MockMessage(
            content: longContent,
            sender: "Test User",
            timestamp: Date(),
            status: .longMessage
        )
        mockMessages.append(message)
    }
    
    private func simulateAIErrors() {
        let errorMessages = [
            MockMessage(content: "❌ AI Error: OpenAI API rate limit exceeded", sender: "MessageAI System", timestamp: Date(), status: .aiError),
            MockMessage(content: "❌ AI Error: Failed to generate summary - insufficient context", sender: "MessageAI System", timestamp: Date(), status: .aiError),
            MockMessage(content: "❌ AI Error: Smart search timeout - please try again", sender: "MessageAI System", timestamp: Date(), status: .aiError)
        ]
        mockMessages.append(contentsOf: errorMessages)
    }
    
    private func simulateNetworkIssues() {
        let networkMessages = [
            MockMessage(content: "🌐 Network: Connection lost - messages queued", sender: "MessageAI Network", timestamp: Date(), status: .networkIssue),
            MockMessage(content: "🌐 Network: Reconnected - 3 messages synced", sender: "MessageAI Network", timestamp: Date(), status: .networkRecovered),
            MockMessage(content: "🌐 Network: Poor connection - AI features may be slow", sender: "MessageAI Network", timestamp: Date(), status: .networkSlow)
        ]
        mockMessages.append(contentsOf: networkMessages)
    }
    
    private func simulateLoadTest() {
        for i in 1...10 {
            let message = MockMessage(
                content: "Load test message \(i) - testing MessageAI performance under high volume",
                sender: "Load Test",
                timestamp: Date(),
                status: .loadTest
            )
            mockMessages.append(message)
        }
    }
    
    private func clearAllMessages() {
        mockMessages.removeAll()
    }
    
    // MARK: - Message Management Functions
    
    private func markAllAsRead() {
        for i in mockMessages.indices {
            mockMessages[i].isRead = true
        }
    }
    
    private func markAllAsUnread() {
        for i in mockMessages.indices {
            mockMessages[i].isRead = false
        }
    }
    
    private func deleteFailedMessages() {
        mockMessages.removeAll { $0.status == .failed }
    }
    
    private func addMockMessage(type: MessageType) {
        let content = getContentForType(type)
        let sender = getRandomSender()
        
        let message = MockMessage(
            content: content,
            sender: sender,
            timestamp: Date(),
            status: isOnline ? .received : .queued,
            isRead: false,
            isOnline: isOnline,
            messageType: type,
            priority: .normal
        )
        
        mockMessages.append(message)
    }
    
    private func addPriorityMessage(_ priority: MessagePriority) {
        let content = getPriorityContent(priority)
        let sender = getRandomSender()
        
        let message = MockMessage(
            content: content,
            sender: sender,
            timestamp: Date(),
            status: isOnline ? .received : .queued,
            isRead: false,
            isOnline: isOnline,
            messageType: .text,
            priority: priority
        )
        
        mockMessages.append(message)
    }
    
    private func getContentForType(_ type: MessageType) -> String {
        switch type {
        case .text:
            return "This is a test text message"
        case .aiResponse:
            return "AI: I can help you with that. Here's what I suggest..."
        case .image:
            return "📷 Image message sent"
        case .voice:
            return "🎤 Voice message (0:15)"
        case .file:
            return "📄 Document.pdf (2.3 MB)"
        case .location:
            return "📍 Location shared"
        case .video:
            return "🎥 Video message (0:30)"
        }
    }
    
    private func getPriorityContent(_ priority: MessagePriority) -> String {
        switch priority {
        case .low:
            return "Low priority: Just a casual message"
        case .normal:
            return "Normal priority: Regular conversation"
        case .high:
            return "HIGH PRIORITY: Important update needed"
        case .urgent:
            return "🚨 URGENT: Immediate attention required!"
        }
    }
    
    private func getRandomSender() -> String {
        let senders = ["Alice", "Bob", "Charlie", "Diana", "Eve", "Frank", "Grace", "Henry"]
        return senders.randomElement() ?? "Unknown"
    }
}

struct MockScenarioButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PresetScenarioButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TestButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct MockMessageRow: View {
    let message: MockMessage
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Priority indicator
                    if message.priority != .normal {
                        priorityIndicator
                    }
                }
                
                HStack {
                    Text(message.sender)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(DateFormatter.timeFormatter.string(from: message.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Message type indicator
                    messageTypeIndicator
                    
                    Spacer()
                    
                    // Read/Unread indicator
                    if !message.isRead {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                    
                    // Status indicator
                    Image(systemName: message.status.icon)
                        .foregroundColor(message.status.color)
                        .font(.title3)
                }
            }
        }
        .padding(.vertical, 4)
        .background(message.isRead ? Color.clear : Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var priorityIndicator: some View {
        Group {
            switch message.priority {
            case .low:
                Image(systemName: "arrow.down")
                    .foregroundColor(.gray)
                    .font(.caption)
            case .normal:
                EmptyView()
            case .high:
                Image(systemName: "arrow.up")
                    .foregroundColor(.orange)
                    .font(.caption)
            case .urgent:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
    
    private var messageTypeIndicator: some View {
        Group {
            switch message.messageType {
            case .text:
                EmptyView()
            case .image:
                Image(systemName: "photo")
                    .foregroundColor(.blue)
                    .font(.caption)
            case .voice:
                Image(systemName: "mic")
                    .foregroundColor(.green)
                    .font(.caption)
            case .file:
                Image(systemName: "doc")
                    .foregroundColor(.orange)
                    .font(.caption)
            case .video:
                Image(systemName: "video")
                    .foregroundColor(.purple)
                    .font(.caption)
            case .location:
                Image(systemName: "location")
                    .foregroundColor(.red)
                    .font(.caption)
            case .aiResponse:
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .font(.caption)
            }
        }
    }
}

struct MockMessage: Identifiable {
    let id = UUID()
    let content: String
    let sender: String
    let timestamp: Date
    var status: MessageStatus
    var isRead: Bool = false
    var isOnline: Bool = true
    var messageType: MessageType = .text
    var priority: MessagePriority = .normal
}

enum MessageType {
    case text
    case image
    case file
    case voice
    case video
    case location
    case aiResponse
}

enum MessagePriority {
    case low
    case normal
    case high
    case urgent
}

enum MessageStatus {
    case sent
    case received
    case failed
    case queued
    case updating
    case aiGenerated
    case searchResult
    case priority
    case actionItem
    case insight
    case decision
    case longMessage
    case aiError
    case networkIssue
    case networkRecovered
    case networkSlow
    case loadTest
    
    var icon: String {
        switch self {
        case .sent: return "checkmark.circle"
        case .received: return "person.circle"
        case .failed: return "exclamationmark.triangle"
        case .queued: return "clock"
        case .updating: return "arrow.clockwise"
        case .aiGenerated: return "brain.head.profile"
        case .searchResult: return "magnifyingglass.circle"
        case .priority: return "exclamationmark.triangle.fill"
        case .actionItem: return "checklist"
        case .insight: return "chart.bar.fill"
        case .decision: return "target"
        case .longMessage: return "text.alignleft"
        case .aiError: return "brain.head.profile"
        case .networkIssue: return "wifi.slash"
        case .networkRecovered: return "wifi"
        case .networkSlow: return "tortoise"
        case .loadTest: return "speedometer"
        }
    }
    
    var color: Color {
        switch self {
        case .sent: return .green
        case .received: return .blue
        case .failed: return .red
        case .queued: return .orange
        case .updating: return .blue
        case .aiGenerated: return .purple
        case .searchResult: return .cyan
        case .priority: return .orange
        case .actionItem: return .green
        case .insight: return .indigo
        case .decision: return .mint
        case .longMessage: return .brown
        case .aiError: return .red
        case .networkIssue: return .red
        case .networkRecovered: return .green
        case .networkSlow: return .yellow
        case .loadTest: return .pink
        }
    }
}

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}

#Preview {
    MockTestingView()
}
