import SwiftUI

struct RemoteTeamAIView: View {
    @EnvironmentObject var messageService: MessageService
    @EnvironmentObject var authService: AuthService
    @StateObject private var aiService = AIService()
    @State private var selectedChatId: String?
    @State private var showingMeetingSummary = false
    @State private var showingProjectStatus = false
    @State private var showingDecisions = false
    @State private var showingPriorityMessages = false
    @State private var showingCollaborationInsights = false
    @State private var projectName = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Remote Team AI Assistant")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("AI-powered features for remote team collaboration")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Chat Selection
                if !messageService.chats.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select a chat to analyze:")
                            .font(.headline)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(messageService.chats) { chat in
                                    ChatSelectionCard(
                                        chat: chat,
                                        isSelected: selectedChatId == chat.id
                                    ) {
                                        selectedChatId = chat.id
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "message.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No chats available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Start a conversation to use AI features")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // AI Features Grid
                if selectedChatId != nil {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        // 1. Meeting Summary
                        AIFeatureCard(
                            title: "Meeting Summary",
                            icon: "doc.text",
                            color: .blue,
                            description: "Generate meeting summaries and action items"
                        ) {
                            showingMeetingSummary = true
                        }
                        
                        // 2. Project Status
                        AIFeatureCard(
                            title: "Project Status",
                            icon: "chart.bar",
                            color: .green,
                            description: "Smart project status updates"
                        ) {
                            showingProjectStatus = true
                        }
                        
                        // 3. Decision Tracking
                        AIFeatureCard(
                            title: "Decisions",
                            icon: "checkmark.circle",
                            color: .orange,
                            description: "Track and manage team decisions"
                        ) {
                            showingDecisions = true
                        }
                        
                        // 4. Priority Messages
                        AIFeatureCard(
                            title: "Priority Detection",
                            icon: "exclamationmark.triangle",
                            color: .red,
                            description: "Identify urgent messages"
                        ) {
                            showingPriorityMessages = true
                        }
                        
                        // 5. Collaboration Insights
                        AIFeatureCard(
                            title: "Team Insights",
                            icon: "person.3",
                            color: .purple,
                            description: "Analyze team collaboration patterns"
                        ) {
                            showingCollaborationInsights = true
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Team AI")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingMeetingSummary) {
            if let chatId = selectedChatId {
                MeetingSummaryView(chatId: chatId)
                    .environmentObject(aiService)
            }
        }
        .sheet(isPresented: $showingProjectStatus) {
            if let chatId = selectedChatId {
                ProjectStatusView(chatId: chatId, projectName: projectName)
                    .environmentObject(aiService)
            }
        }
        .sheet(isPresented: $showingDecisions) {
            if let chatId = selectedChatId {
                DecisionTrackingView(chatId: chatId)
                    .environmentObject(aiService)
            }
        }
        .sheet(isPresented: $showingPriorityMessages) {
            if let chatId = selectedChatId {
                PriorityMessagesView(chatId: chatId)
                    .environmentObject(aiService)
            }
        }
        .sheet(isPresented: $showingCollaborationInsights) {
            if let chatId = selectedChatId {
                CollaborationInsightsView(chatId: chatId)
                    .environmentObject(aiService)
            }
        }
    }
}

// MARK: - Supporting Views

struct ChatSelectionCard: View {
    let chat: Chat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.isGroup ? chat.groupName ?? "Group Chat" : "Direct Message")
                    .font(.headline)
                    .lineLimit(1)
                
                if let lastMessage = chat.lastMessage {
                    Text(lastMessage.content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text(chat.participants.count == 1 ? "1 participant" : "\(chat.participants.count) participants")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 200, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AIFeatureCard: View {
    let title: String
    let icon: String
    let color: Color
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding()
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct RemoteTeamAIView_Previews: PreviewProvider {
    static var previews: some View {
        RemoteTeamAIView()
            .environmentObject(MessageService())
            .environmentObject(AuthService())
    }
}
