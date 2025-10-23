import SwiftUI
import OpenAI

struct AIAssistantView: View {
    @EnvironmentObject var messageService: MessageService
    @EnvironmentObject var authService: AuthService
    @StateObject private var aiService = AIService()
    @State private var aiMessage = ""
    @State private var aiResponse = ""
    @State private var isLoading = false
    @State private var conversationHistory: [AIMessage] = []
    @State private var showingAPIKeyAlert = false
    @State private var apiKey = ""
    
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
                
                VStack(spacing: 0) {
                    // API Key Status
                    if UserDefaults.standard.string(forKey: "openai_api_key") == nil {
                        ModernAPIKeyWarning(
                            onConfigure: {
                                showingAPIKeyAlert = true
                            }
                        )
                    }
                    
                    // AI Conversation
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(conversationHistory) { message in
                                ModernAIBubbleView(message: message)
                            }
                            
                            if isLoading {
                                ModernAILoadingView()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    
                    // AI Input
                    ModernAIInputView(
                        message: $aiMessage,
                        onSend: sendToAI,
                        isLoading: isLoading
                    )
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingAPIKeyAlert = true
                    }
                    .fontWeight(.medium)
                }
            }
            .onAppear {
                addWelcomeMessage()
            }
            .alert("OpenAI API Key", isPresented: $showingAPIKeyAlert) {
                TextField("Enter API Key", text: $apiKey)
                    .keyboardType(.default)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                Button("Save") {
                    aiService.setAPIKey(apiKey)
                    apiKey = ""
                }
                Button("Cancel", role: .cancel) {
                    apiKey = ""
                }
            } message: {
                Text("Enter your OpenAI API key to enable AI features. You can get one from platform.openai.com")
            }
        }
    }
    
    private func addWelcomeMessage() {
        if conversationHistory.isEmpty {
            let welcomeMessage = AIMessage(
                content: "Hello! I'm your AI assistant. I can help you with:\n\n• Summarizing conversations\n• Extracting action items\n• Translating messages\n• Smart search\n• And much more!\n\nHow can I help you today?",
                isFromUser: false,
                timestamp: Date()
            )
            conversationHistory.append(welcomeMessage)
        }
    }
    
    private func sendToAI() {
        guard !aiMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = AIMessage(
            content: aiMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            isFromUser: true,
            timestamp: Date()
        )
        
        conversationHistory.append(userMessage)
        let userInput = aiMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        aiMessage = ""
        isLoading = true
        
        // Check if API key is configured
        guard UserDefaults.standard.string(forKey: "openai_api_key") != nil else {
            let errorMessage = AIMessage(
                content: "Please configure your OpenAI API key in settings to use AI features.",
                isFromUser: false,
                timestamp: Date()
            )
            conversationHistory.append(errorMessage)
            isLoading = false
            return
        }
        
        // Call actual AI service
        Task {
            do {
                let response = try await callOpenAI(userInput: userInput)
                await MainActor.run {
                    let aiMessage = AIMessage(
                        content: response,
                        isFromUser: false,
                        timestamp: Date()
                    )
                    conversationHistory.append(aiMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = AIMessage(
                        content: "Sorry, I encountered an error: \(error.localizedDescription)",
                        isFromUser: false,
                        timestamp: Date()
                    )
                    conversationHistory.append(errorMessage)
                    isLoading = false
                }
            }
        }
    }
    
    private func callOpenAI(userInput: String) async throws -> String {
        guard let apiKey = UserDefaults.standard.string(forKey: "openai_api_key"), !apiKey.isEmpty else {
            throw NSError(domain: "AIAssistant", code: 1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not configured"])
        }
        
        let openAI = OpenAI(apiToken: apiKey)
        
        do {
            let query = ChatQuery(
                messages: [.user(.init(content: .string(userInput)))],
                model: .gpt3_5Turbo,
                temperature: 0.7
            )
            
            let result = try await openAI.chats(query: query)
            return result.choices.first?.message.content ?? "No response from AI"
        } catch {
            print("OpenAI API Error: \(error)")
            throw error
        }
    }
}

// MARK: - Modern Component Views

struct ModernAPIKeyWarning: View {
    let onConfigure: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("OpenAI API Key Required")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Configure your API key to enable AI features")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Button(action: onConfigure) {
                HStack(spacing: 6) {
                    Image(systemName: "key.fill")
                    Text("Configure")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

struct ModernAIBubbleView: View {
    let message: AIMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !message.isFromUser {
                // AI Avatar
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
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 8) {
                // Message Content
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                message.isFromUser 
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    : AnyShapeStyle(Color(.systemBackground))
                            )
                            .shadow(
                                color: message.isFromUser ? .blue.opacity(0.3) : .black.opacity(0.05),
                                radius: message.isFromUser ? 8 : 2,
                                x: 0,
                                y: message.isFromUser ? 4 : 1
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                message.isFromUser ? Color.clear : Color.gray.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                
                // Timestamp
                HStack {
                    if message.isFromUser {
                        Spacer()
                    }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.1))
                        )
                    
                    if !message.isFromUser {
                        Spacer()
                    }
                }
            }
            
            if message.isFromUser {
                // User Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ModernAILoadingView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI Avatar
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
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.0)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: true
                            )
                    }
                    
                    Text("AI is thinking...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            
            Spacer()
        }
    }
}

struct ModernAIInputView: View {
    @Binding var message: String
    let onSend: () -> Void
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.2))
            
            HStack(spacing: 12) {
                // Input Field
                HStack(spacing: 8) {
                    TextField("Ask AI anything...", text: $message, axis: .vertical)
                        .font(.body)
                        .lineLimit(1...4)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemGray6))
                        )
                        .onSubmit {
                            if !message.isEmpty && !isLoading {
                                onSend()
                            }
                        }
                    
                    // Send Button
                    Button(action: onSend) {
                        ZStack {
                            Circle()
                                .fill(
                                    message.isEmpty || isLoading
                                        ? AnyShapeStyle(Color.gray.opacity(0.3))
                                        : AnyShapeStyle(LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                )
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(message.isEmpty || isLoading ? .gray : .white)
                        }
                    }
                    .disabled(message.isEmpty || isLoading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }
}

struct AIMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

#Preview {
    AIAssistantView()
        .environmentObject(MessageService())
        .environmentObject(AuthService())
}