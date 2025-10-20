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
            VStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Analyzing collaboration patterns...")
                            .font(.headline)
                        Text("This may take a few moments")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !insights.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(insights) { insight in
                                CollaborationInsightCard(insight: insight)
                            }
                        }
                        .padding()
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        
                        Text("Error")
                            .font(.headline)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Try Again") {
                            generateInsights()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                        
                        Text("Team Collaboration Insights")
                            .font(.headline)
                        
                        Text("Analyze team communication patterns and collaboration opportunities")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Generate Insights") {
                            generateInsights()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Team Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
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

struct CollaborationInsightCard: View {
    let insight: CollaborationInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(insightTypeTitle)
                        .font(.headline)
                        .foregroundColor(insightColor)
                    
                    Text("Generated at \(insight.timestamp.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                InsightTypeIcon(type: insight.insightType)
            }
            
            // Description
            Text(insight.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Participants
            if !insight.participants.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Team Members")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 4) {
                        ForEach(insight.participants, id: \.self) { participant in
                            HStack {
                                Circle()
                                    .fill(insightColor)
                                    .frame(width: 6, height: 6)
                                Text(participant)
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
            
            // Suggestions
            if !insight.suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendations")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(Array(insight.suggestions.enumerated()), id: \.offset) { index, suggestion in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(insightColor)
                                .frame(width: 16, alignment: .leading)
                            
                            Text(suggestion)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(insightColor.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(insightColor.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(insightColor.opacity(0.3), lineWidth: 1)
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

struct InsightTypeIcon: View {
    let type: CollaborationType
    
    var body: some View {
        Image(systemName: iconName)
            .font(.title2)
            .foregroundColor(iconColor)
            .padding(8)
            .background(iconColor.opacity(0.1))
            .cornerRadius(8)
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

struct CollaborationInsightsView_Previews: PreviewProvider {
    static var previews: some View {
        CollaborationInsightsView(chatId: "preview")
            .environmentObject(AIService())
    }
}
