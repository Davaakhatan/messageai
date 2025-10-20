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
            VStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Generating meeting summary...")
                            .font(.headline)
                        Text("This may take a few moments")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let summary = meetingSummary {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Meeting Summary")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("Generated on \(summary.timestamp.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Participants
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Participants")
                                    .font(.headline)
                                
                                ForEach(summary.participants, id: \.self) { participant in
                                    HStack {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 8, height: 8)
                                        Text(participant)
                                            .font(.subheadline)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Agenda
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Agenda")
                                    .font(.headline)
                                
                                ForEach(summary.agenda, id: \.self) { item in
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .foregroundColor(.blue)
                                        Text(item)
                                            .font(.subheadline)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Key Points
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Key Points")
                                    .font(.headline)
                                
                                ForEach(summary.keyPoints, id: \.self) { point in
                                    HStack(alignment: .top) {
                                        Text("•")
                                            .foregroundColor(.green)
                                        Text(point)
                                            .font(.subheadline)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Action Items
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Action Items")
                                    .font(.headline)
                                
                                ForEach(summary.actionItems) { item in
                                    ActionItemRow(actionItem: item)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Next Meeting
                            if let nextMeeting = summary.nextMeeting {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Next Meeting")
                                        .font(.headline)
                                    
                                    Text(nextMeeting)
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // Duration
                            if let duration = summary.duration {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Meeting Duration")
                                        .font(.headline)
                                    
                                    Text(formatDuration(duration))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
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
                            generateSummary()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Generate Meeting Summary")
                            .font(.headline)
                        
                        Text("Tap the button below to generate a summary of this conversation")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Generate Summary") {
                            generateSummary()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Meeting Summary")
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

struct ActionItemRow: View {
    let actionItem: ActionItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(actionItem.description)
                    .font(.subheadline)
                
                Spacer()
                
                PriorityBadge(priority: actionItem.priority)
            }
            
            if let assignee = actionItem.assignee {
                Text("Assigned to: \(assignee)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let dueDate = actionItem.dueDate {
                Text("Due: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}


struct MeetingSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        MeetingSummaryView(chatId: "preview")
            .environmentObject(AIService())
    }
}
