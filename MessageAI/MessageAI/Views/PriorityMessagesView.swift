import SwiftUI

struct PriorityMessagesView: View {
    let chatId: String
    @EnvironmentObject var aiService: AIService
    @EnvironmentObject var messageService: MessageService
    @Environment(\.dismiss) private var dismiss
    @State private var priorityMessages: [PriorityMessage] = []
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
                            Text("Analyzing Message Priority")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("AI is scanning your conversation for high-priority messages...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !priorityMessages.isEmpty {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header
                            ModernPriorityHeader(priorityCount: priorityMessages.count)
                            
                            // Priority Messages List
                            LazyVStack(spacing: 16) {
                                ForEach(priorityMessages) { priorityMessage in
                                    ModernPriorityMessageCard(priorityMessage: priorityMessage)
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
                        onRetry: analyzePriorityMessages
                    )
                } else {
                    ModernPriorityInputView(
                        onAnalyze: analyzePriorityMessages
                    )
                }
            }
            .navigationTitle("Priority Detection")
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
            if let existingPriorityMessages = aiService.priorityMessages[chatId] {
                priorityMessages = existingPriorityMessages
            }
        }
    }
    
    private func analyzePriorityMessages() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Get messages directly from Firestore like other AI functions
                let messages = await aiService.getConversationContext(for: chatId)
                
                // Analyze each message for priority
                var newPriorityMessages: [PriorityMessage] = []
                
                for message in messages {
                    if let priorityMessage = try await aiService.analyzeMessagePriority(message, in: chatId) {
                        newPriorityMessages.append(priorityMessage)
                    }
                }
                
                await MainActor.run {
                    self.priorityMessages = newPriorityMessages
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

struct ModernPriorityHeader: View {
    let priorityCount: Int
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Priority Messages")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(priorityCount) high-priority message\(priorityCount == 1 ? "" : "s") detected")
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

struct ModernPriorityMessageCard: View {
    let priorityMessage: PriorityMessage
    @EnvironmentObject var messageService: MessageService
    
    private var originalMessage: Message? {
        // Find the original message by ID
        for messages in messageService.messages.values {
            if let message = messages.first(where: { $0.id == priorityMessage.messageId }) {
                return message
            }
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: priorityIcon)
                            .font(.system(size: 16))
                            .foregroundColor(priorityColor)
                        
                        Text("Priority Message")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(priorityColor)
                    }
                    
                    Text("Detected at \(priorityMessage.timestamp.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                ModernPriorityBadge(priority: priorityMessage.priority)
            }
            
            // Original Message Content
            if let message = originalMessage {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "message.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        
                        Text("Original Message")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    
                    Text(message.content)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
            }
            
            // Reason
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                    
                    Text("Why This Is Priority")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                
                Text(priorityMessage.reason)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            
            // Suggested Action
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                    
                    Text("Suggested Action")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                Text(priorityMessage.suggestedAction)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(16)
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(priorityColor.opacity(0.3), lineWidth: 2)
        )
    }
    
    private var priorityIcon: String {
        switch priorityMessage.priority {
        case .low: return "arrow.down.circle.fill"
        case .medium: return "minus.circle.fill"
        case .high: return "arrow.up.circle.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
    
    private var priorityColor: Color {
        switch priorityMessage.priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

struct ModernPriorityBadge: View {
    let priority: Priority
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            
            Text(priority.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(priorityColor.opacity(0.15))
        )
        .foregroundColor(priorityColor)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

struct ModernErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 12) {
                Text("Priority Analysis Failed")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct ModernPriorityInputView: View {
    let onAnalyze: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.red.opacity(0.1), .orange.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 8) {
                    Text("Priority Detection")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("AI will analyze your conversation to identify high-priority messages")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Button(action: onAnalyze) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                    Text("Analyze Priority")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.red, .orange],
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

struct PriorityMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        PriorityMessagesView(chatId: "preview")
            .environmentObject(AIService())
            .environmentObject(MessageService())
    }
}