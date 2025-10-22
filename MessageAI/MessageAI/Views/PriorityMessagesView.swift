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
            VStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Analyzing message priority...")
                            .font(.headline)
                        Text("This may take a few moments")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !priorityMessages.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(priorityMessages) { priorityMessage in
                                PriorityMessageCard(priorityMessage: priorityMessage)
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
                            analyzePriorityMessages()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Priority Message Detection")
                            .font(.headline)
                        
                        Text("Analyze messages in this conversation for priority and urgency")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Analyze Messages") {
                            analyzePriorityMessages()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Priority Messages")
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

struct PriorityMessageCard: View {
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
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Priority Message")
                        .font(.headline)
                        .foregroundColor(priorityColor)
                    
                    Text("Detected at \(priorityMessage.timestamp.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                PriorityBadge(priority: priorityMessage.priority)
            }
            
            // Original Message Content
            if let message = originalMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message Content")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(message.content)
                        .font(.subheadline)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // Reason
            VStack(alignment: .leading, spacing: 4) {
                Text("Why it's priority:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(priorityMessage.reason)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Suggested Action
            VStack(alignment: .leading, spacing: 4) {
                Text("Suggested Action:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(priorityMessage.suggestedAction)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(priorityColor.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(priorityColor.opacity(0.3), lineWidth: 2)
        )
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

struct PriorityBadge: View {
    let priority: Priority
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: priorityIcon)
                .font(.caption)
            Text(priority.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(priorityColor.opacity(0.2))
        .foregroundColor(priorityColor)
        .cornerRadius(6)
    }
    
    private var priorityIcon: String {
        switch priority {
        case .low: return "arrow.down.circle"
        case .medium: return "minus.circle"
        case .high: return "arrow.up.circle"
        case .urgent: return "exclamationmark.triangle"
        }
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

struct PriorityMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        PriorityMessagesView(chatId: "preview")
            .environmentObject(AIService())
            .environmentObject(MessageService())
    }
}
