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
                            Text("Extracting Decisions")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("AI is analyzing your conversation to identify key decisions...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !decisions.isEmpty {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            ModernDecisionsHeader(decisionCount: decisions.count)
                            
                            // Decisions List
                            LazyVStack(spacing: 16) {
                                ForEach(decisions) { decision in
                                    ModernDecisionCard(decision: decision)
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
                        onRetry: extractDecisions
                    )
                } else {
                    ModernDecisionsInputView(
                        onExtract: extractDecisions
                    )
                }
            }
            .navigationTitle("Decisions")
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

// MARK: - Modern Component Views

struct ModernDecisionsHeader: View {
    let decisionCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
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
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Team Decisions")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(decisionCount) decision\(decisionCount == 1 ? "" : "s") identified")
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

struct ModernDecisionCard: View {
    let decision: Decision
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(decision.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("Made by \(decision.decisionMaker)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                ModernDecisionStatusBadge(status: decision.status)
            }
            
            // Description
            Text(decision.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
            
            // Participants
            if !decision.participants.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        
                        Text("Participants")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(decision.participants, id: \.self) { participant in
                            HStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 16, height: 16)
                                    
                                    Text(participant.prefix(1).uppercased())
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Text(participant)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.05))
                            )
                        }
                    }
                }
            }
            
            // Tags
            if !decision.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        
                        Text("Tags")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(decision.tags, id: \.self) { tag in
                                ModernTagChip(tag: tag)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            
            // Follow-up and Timestamp
            VStack(spacing: 8) {
                if let followUpDate = decision.followUpDate {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 14))
                            .foregroundColor(.purple)
                        
                        Text("Follow-up: \(followUpDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.purple)
                        
                        Spacer()
                    }
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text("Created: \(decision.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
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

struct ModernDecisionStatusBadge: View {
    let status: DecisionStatus
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(status.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.15))
        )
        .foregroundColor(statusColor)
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


struct ModernTagChip: View {
    let tag: String
    
    var body: some View {
        Text(tag)
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
}


struct ModernDecisionsInputView: View {
    let onExtract: () -> Void
    
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
                    
                    Image(systemName: "checkmark.circle.fill")
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
                    Text("Decision Tracking")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Extract and track team decisions from your conversation")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Button(action: onExtract) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                    Text("Extract Decisions")
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

struct DecisionTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        DecisionTrackingView(chatId: "preview")
            .environmentObject(AIService())
    }
}