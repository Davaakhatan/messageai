import SwiftUI

struct CollaborationInsightsView: View {
    let chatId: String
    @EnvironmentObject var aiService: AIService
    @Environment(\.dismiss) private var dismiss
    @State private var insights: [CollaborationInsight] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.purple.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 24) {
                        // Modern Loading Animation
                        ZStack {
                            Circle()
                                .stroke(Color.blue.opacity(0.2), lineWidth: 4)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: 80, height: 80)
                                .rotationEffect(.degrees(isLoading ? 360 : 0))
                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isLoading)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Analyzing Team Collaboration")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("AI is studying your team's communication patterns and collaboration dynamics...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !insights.isEmpty {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            ModernInsightsHeader(insightCount: insights.count)
                            
                            // Insights List
                            LazyVStack(spacing: 16) {
                                ForEach(insights) { insight in
                                    ModernCollaborationInsightCard(insight: insight)
                                }
                            }
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                } else if let error = errorMessage {
                    ModernErrorView(
                        error: error,
                        onRetry: generateInsights
                    )
                } else {
                    ModernInsightsInputView(
                        onGenerate: generateInsights
                    )
                }
            }
            .navigationTitle("Team Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .onAppear {
            if let existingInsights = aiService.collaborationInsights[chatId] {
                insights = existingInsights
            }
        }
    }
    
    private func generateInsights() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let generatedInsights = try await aiService.generateCollaborationInsights(for: chatId)
                await MainActor.run {
                    self.insights = generatedInsights
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Modern Component Views

struct ModernInsightsHeader: View {
    let insightCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Team Insights")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(insightCount) collaboration insight\(insightCount == 1 ? "" : "s") generated")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
}

struct ModernCollaborationInsightCard: View {
    let insight: CollaborationInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ModernInsightTypeIcon(type: insight.insightType)
                        
                        Text(insightTypeTitle)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(insightColor)
                    }
                    
                    Text("Generated at \(insight.timestamp.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Description
            Text(insight.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(4)
            
            // Participants
            if !insight.participants.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        
                        Text("Team Members")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(insight.participants, id: \.self) { participant in
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(
                                            gradient: Gradient(colors: [.blue, .purple]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 24, height: 24)
                                    
                                    Text(participant.prefix(1).uppercased())
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Text(participant)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                }
            }
            
            // Suggestions
            if !insight.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        
                        Text("Recommendations")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(Array(insight.suggestions.enumerated()), id: \.offset) { index, suggestion in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(
                                        Circle()
                                            .fill(Color.orange)
                                    )
                                
                                Text(suggestion)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(insightColor.opacity(0.3), lineWidth: 2)
        )
    }
    
    private var insightTypeTitle: String {
        switch insight.insightType {
        case .meetingOptimization:
            return "Meeting Optimization"
        case .communicationPattern:
            return "Communication Pattern"
        case .workloadBalance:
            return "Workload Balance"
        case .skillGaps:
            return "Skill Gaps"
        case .timeZoneOptimization:
            return "Time Zone Optimization"
        }
    }
    
    private var insightColor: Color {
        switch insight.insightType {
        case .meetingOptimization:
            return .blue
        case .communicationPattern:
            return .green
        case .workloadBalance:
            return .orange
        case .skillGaps:
            return .purple
        case .timeZoneOptimization:
            return .teal
        }
    }
}

struct ModernInsightTypeIcon: View {
    let type: CollaborationType
    
    var body: some View {
        ZStack {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 32, height: 32)
            
            Image(systemName: iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
        }
    }
    
    private var iconName: String {
        switch type {
        case .meetingOptimization:
            return "calendar.badge.clock"
        case .communicationPattern:
            return "bubble.left.and.bubble.right"
        case .workloadBalance:
            return "scalemass"
        case .skillGaps:
            return "graduationcap"
        case .timeZoneOptimization:
            return "globe"
        }
    }
    
    private var iconColor: Color {
        switch type {
        case .meetingOptimization:
            return .blue
        case .communicationPattern:
            return .green
        case .workloadBalance:
            return .orange
        case .skillGaps:
            return .purple
        case .timeZoneOptimization:
            return .teal
        }
    }
}



struct ModernInsightsInputView: View {
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple.opacity(0.1), .blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 8) {
                    Text("Team Collaboration Insights")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Analyze team communication patterns and discover collaboration opportunities")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Button(action: onGenerate) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                    Text("Generate Insights")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }
}

struct CollaborationInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        CollaborationInsightsView(chatId: "preview")
            .environmentObject(AIService())
    }
}