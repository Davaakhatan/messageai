import SwiftUI

struct MeetingSummaryView: View {
    let chatId: String
    @EnvironmentObject var aiService: AIService
    @Environment(\.dismiss) private var dismiss
    @State private var meetingSummary: MeetingSummary?
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
                            Text("Generating Meeting Summary")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("AI is analyzing your conversation and extracting key insights...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let summary = meetingSummary {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Modern Header
                            ModernMeetingHeader(
                                timestamp: summary.timestamp,
                                duration: summary.duration
                            )
                            
                            // Participants Card
                            ModernParticipantsCard(participants: summary.participants)
                            
                            // Agenda Card
                            if !summary.agenda.isEmpty {
                                ModernAgendaCard(agenda: summary.agenda)
                            }
                            
                            // Key Points Card
                            if !summary.keyPoints.isEmpty {
                                ModernKeyPointsCard(keyPoints: summary.keyPoints)
                            }
                            
                            // Action Items Card
                            if !summary.actionItems.isEmpty {
                                ModernActionItemsCard(actionItems: summary.actionItems)
                            }
                            
                            // Next Meeting Card
                            if let nextMeeting = summary.nextMeeting {
                                ModernNextMeetingCard(nextMeeting: nextMeeting)
                            }
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                } else if let error = errorMessage {
                    ModernErrorView(
                        error: error,
                        onRetry: generateSummary
                    )
                } else {
                    ModernMeetingInputView(
                        onGenerate: generateSummary
                    )
                }
            }
            .navigationTitle("Meeting Summary")
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
            if let existingSummary = aiService.meetingSummaries[chatId] {
                meetingSummary = existingSummary
            }
        }
    }
    
    private func generateSummary() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let summary = try await aiService.generateMeetingSummary(for: chatId)
                await MainActor.run {
                    self.meetingSummary = summary
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
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Modern Component Views

struct ModernMeetingHeader: View {
    let timestamp: Date
    let duration: TimeInterval?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with Icon
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Meeting Summary")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Generated on \(timestamp.formatted(date: .abbreviated, time: .shortened))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Duration Card
            if let duration = duration {
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                    
                    Text("Duration: \(formatDuration(duration))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct ModernParticipantsCard: View {
    let participants: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                Text("Participants")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(participants.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                    .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(participants, id: \.self) { participant in
                    ModernParticipantRow(participant: participant)
                }
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

struct ModernParticipantRow: View {
    let participant: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Text(participant.prefix(1).uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(participant)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

struct ModernAgendaCard: View {
    let agenda: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.clipboard.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                
                Text("Agenda")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(agenda.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.1))
                    )
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 12) {
                ForEach(Array(agenda.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(
                                Circle()
                                    .fill(Color.green)
                            )
                        
                        Text(item)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
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

struct ModernKeyPointsCard: View {
    let keyPoints: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                
                Text("Key Points")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(keyPoints.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.1))
                    )
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 12) {
                ForEach(keyPoints, id: \.self) { point in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                            .padding(.top, 2)
                        
                        Text(point)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
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

struct ModernActionItemsCard: View {
    let actionItems: [ActionItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.square.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
                
                Text("Action Items")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(actionItems.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.1))
                    )
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 12) {
                ForEach(actionItems) { item in
                    ModernActionItemRow(actionItem: item)
                }
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

struct ModernActionItemRow: View {
    let actionItem: ActionItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.red)
                    .padding(.top, 6)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(actionItem.description)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        if let assignee = actionItem.assignee {
                            HStack(spacing: 4) {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text(assignee)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if let dueDate = actionItem.dueDate {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Spacer()
                        
                        ModernActionPriorityBadge(priority: actionItem.priority)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ModernActionPriorityBadge: View {
    let priority: Priority
    
    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(priorityColor.opacity(0.2))
            )
            .foregroundColor(priorityColor)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .urgent: return .purple
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

struct ModernNextMeetingCard: View {
    let nextMeeting: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 20))
                    .foregroundColor(.purple)
                
                Text("Next Meeting")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.purple)
                
                Text(nextMeeting)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
}


struct ModernMeetingInputView: View {
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
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
                    
                    Image(systemName: "doc.text.fill")
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
                    Text("Meeting Summary")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Generate an AI-powered summary of your team conversation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Button(action: onGenerate) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                    Text("Generate Summary")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
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

struct MeetingSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        MeetingSummaryView(chatId: "preview")
            .environmentObject(AIService())
    }
}