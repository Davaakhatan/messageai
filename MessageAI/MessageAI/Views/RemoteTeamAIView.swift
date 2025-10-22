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
    @State private var showingSmartSearch = false
    @State private var projectName = ""
    @State private var animateCards = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Modern Header with Gradient
                    VStack(spacing: 16) {
                        // Hero Section
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Team AI Assistant")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    
                                    Text("AI-powered collaboration tools for remote teams")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // AI Status Indicator
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                        .scaleEffect(animateCards ? 1.2 : 1.0)
                                        .animation(.easeInOut(duration: 1.5).repeatForever(), value: animateCards)
                                    
                                    Text("AI Active")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.green.opacity(0.1))
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                
                        // Chat Selection Section
                        if !messageService.chats.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Select a chat to analyze")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(messageService.chats.count) chats")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.blue.opacity(0.1))
                                        )
                                }
                                .padding(.horizontal, 20)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(Array(messageService.chats.enumerated()), id: \.element.id) { index, chat in
                                            ModernChatSelectionCard(
                                                chat: chat,
                                                isSelected: selectedChatId == chat.id,
                                                index: index
                                            ) {
                                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                                    selectedChatId = chat.id
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .padding(.trailing, 20) // Extra padding to prevent cutoff
                                }
                            }
                        } else {
                            // Empty State with Modern Design
                            VStack(spacing: 24) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 120, height: 120)
                                    
                                    Image(systemName: "message.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                
                                VStack(spacing: 8) {
                                    Text("No conversations yet")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Text("Start a conversation to unlock AI-powered collaboration features")
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                                
                                Button(action: {
                                    // Navigate to new chat
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Start New Chat")
                                    }
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 40)
                            .padding(.vertical, 60)
                        }
                
                        // AI Features Section
                        if selectedChatId != nil {
                            VStack(spacing: 24) {
                                // Section Header
                                HStack {
                                    Text("AI Features")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text("Powered by OpenAI")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.green.opacity(0.1))
                                        )
                                }
                                .padding(.horizontal, 20)
                                
                                // Modern AI Features Grid
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16)
                                ], spacing: 20) {
                                    // 1. Meeting Summary
                                    ModernAIFeatureCard(
                                        title: "Meeting Summary",
                                        icon: "doc.text.fill",
                                        gradient: [.blue, .cyan],
                                        description: "Generate meeting summaries and action items",
                                        delay: 0.1
                                    ) {
                                        showingMeetingSummary = true
                                    }
                                    
                                    // 2. Project Status
                                    ModernAIFeatureCard(
                                        title: "Project Status",
                                        icon: "chart.bar.fill",
                                        gradient: [.green, .mint],
                                        description: "Smart project status updates",
                                        delay: 0.2
                                    ) {
                                        showingProjectStatus = true
                                    }
                                    
                                    // 3. Decision Tracking
                                    ModernAIFeatureCard(
                                        title: "Decisions",
                                        icon: "checkmark.circle.fill",
                                        gradient: [.orange, .yellow],
                                        description: "Track and manage team decisions",
                                        delay: 0.3
                                    ) {
                                        showingDecisions = true
                                    }
                                    
                                    // 4. Priority Messages
                                    ModernAIFeatureCard(
                                        title: "Priority Detection",
                                        icon: "exclamationmark.triangle.fill",
                                        gradient: [.red, .pink],
                                        description: "Identify urgent messages",
                                        delay: 0.4
                                    ) {
                                        showingPriorityMessages = true
                                    }
                                    
                                    // 5. Collaboration Insights
                                    ModernAIFeatureCard(
                                        title: "Team Insights",
                                        icon: "person.3.fill",
                                        gradient: [.purple, .indigo],
                                        description: "Analyze team collaboration patterns",
                                        delay: 0.5
                                    ) {
                                        showingCollaborationInsights = true
                                    }
                                    
                                    // 6. Smart Search
                                    ModernAIFeatureCard(
                                        title: "Smart Search",
                                        icon: "magnifyingglass.circle.fill",
                                        gradient: [.teal, .blue],
                                        description: "Intelligent search across conversations",
                                        delay: 0.6
                                    ) {
                                        // Navigate to smart search
                                        if let chatId = selectedChatId {
                                            showingSmartSearch = true
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.top, 20)
                        }
                
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Team AI")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateCards = true
                }
            }
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
        .sheet(isPresented: $showingSmartSearch) {
            SmartSearchView()
                .environmentObject(aiService)
        }
    }
}

// MARK: - Modern Supporting Views

struct ModernChatSelectionCard: View {
    let chat: Chat
    let isSelected: Bool
    let index: Int
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Chat Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: isSelected ? [.blue, .purple] : [.gray.opacity(0.2), .gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: chat.isGroup ? "person.3.fill" : "person.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(isSelected ? .white : .gray)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(chat.isGroup ? chat.groupName ?? "Group Chat" : "Direct Message")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let lastMessage = chat.lastMessage {
                        Text(lastMessage.content)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        Text(chat.participants.count == 1 ? "1 participant" : "\(chat.participants.count) participants")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if let lastMessage = chat.lastMessage {
                            Text(lastMessage.timestamp, style: .relative)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(16)
            .frame(width: 200, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ? 
                        LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [.gray.opacity(0.05), .gray.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? 
                                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: isSelected ? 2 : 0
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(
                color: isSelected ? .blue.opacity(0.2) : .clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct ModernAIFeatureCard: View {
    let title: String
    let icon: String
    let gradient: [Color]
    let description: String
    let delay: Double
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var animateIn = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            .padding(20)
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                gradient.first?.opacity(0.05) ?? .clear,
                                gradient.last?.opacity(0.1) ?? .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .scaleEffect(animateIn ? 1.0 : 0.8)
            .opacity(animateIn ? 1.0 : 0.0)
            .shadow(
                color: gradient.first?.opacity(0.15) ?? .clear,
                radius: 12,
                x: 0,
                y: 6
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                animateIn = true
            }
        }
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
