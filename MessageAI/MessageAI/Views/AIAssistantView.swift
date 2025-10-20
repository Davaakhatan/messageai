import SwiftUI

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
            VStack(spacing: 0) {
                // API Key Status
                if UserDefaults.standard.string(forKey: "openai_api_key") == nil {
                    VStack {
                        Text("⚠️ OpenAI API Key Required")
                            .foregroundColor(.orange)
                            .font(.headline)
                        Text("Tap to configure your OpenAI API key for AI features")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Add API Key") {
                            showingAPIKeyAlert = true
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // AI Conversation
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(conversationHistory) { message in
                            AIBubbleView(message: message)
                        }
                        
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("AI is thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                
                // AI Input
                AIInputView(
                    message: $aiMessage,
                    onSend: sendToAI,
                    isLoading: isLoading
                )
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingAPIKeyAlert = true
                    }
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
        // OpenAI integration temporarily disabled
        // This will be implemented when AI features are added
        
        // Simulate AI response for now
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        return "AI features are temporarily disabled. This is a placeholder response to: '\(userInput)'. AI integration will be added in the next phase."
    }
}

struct AIMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

struct AIBubbleView: View {
    let message: AIMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        message.isFromUser ? Color.blue : Color.gray.opacity(0.2)
                    )
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .cornerRadius(18)
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !message.isFromUser {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AIInputView: View {
    @Binding var message: String
    let onSend: () -> Void
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Ask AI anything...", text: $message)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.default)
                .onSubmit {
                    onSend()
                }
            
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(message.isEmpty || isLoading ? .gray : .blue)
            }
            .disabled(message.isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

#Preview {
    AIAssistantView()
        .environmentObject(MessageService())
        .environmentObject(AuthService())
}
