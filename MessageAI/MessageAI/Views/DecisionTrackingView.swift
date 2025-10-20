import SwiftUI

struct DecisionTrackingView: View {
    let chatId: String
    @EnvironmentObject var aiService: AIService
    @Environment(\.dismiss) private var dismiss
    @State private var decisions: [Decision] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Extracting decisions...")
                            .font(.headline)
                        Text("This may take a few moments")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !decisions.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(decisions) { decision in
                                DecisionCard(decision: decision)
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
                            extractDecisions()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Decision Tracking")
                            .font(.headline)
                        
                        Text("Extract and track team decisions from this conversation")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Extract Decisions") {
                            extractDecisions()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Decisions")
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
            if let existingDecisions = aiService.decisions[chatId] {
                decisions = existingDecisions
            }
        }
    }
    
    private func extractDecisions() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let extractedDecisions = try await aiService.extractDecisions(from: chatId)
                await MainActor.run {
                    self.decisions = extractedDecisions
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

struct DecisionCard: View {
    let decision: Decision
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(decision.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text("Made by \(decision.decisionMaker)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                DecisionStatusBadge(status: decision.status)
            }
            
            // Description
            Text(decision.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            // Participants
            if !decision.participants.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Participants")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 4) {
                        ForEach(decision.participants, id: \.self) { participant in
                            HStack {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: 6)
                                Text(participant)
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
            
            // Tags
            if !decision.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(decision.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            // Follow-up Date
            if let followUpDate = decision.followUpDate {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("Follow-up: \(followUpDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // Timestamp
            Text("Created: \(decision.createdAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct DecisionStatusBadge: View {
    let status: DecisionStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(4)
    }
    
    private var statusColor: Color {
        switch status {
        case .active: return .green
        case .implemented: return .blue
        case .reversed: return .red
        case .expired: return .gray
        }
    }
}

struct DecisionTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        DecisionTrackingView(chatId: "preview")
            .environmentObject(AIService())
    }
}
