# MessageAI - System Architecture

## Overview
MessageAI follows a modern iOS architecture combining SwiftUI, Firebase backend, and AI integration. The system is designed for real-time messaging with intelligent AI features.

## High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   iOS Client    │    │  Firebase       │    │   AI Services   │
│   (SwiftUI)     │◄──►│  Backend        │◄──►│   (OpenAI/      │
│                 │    │                 │    │    Claude)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## iOS Architecture (MVVM + SwiftUI)

### Core Components

#### 1. Data Layer
```swift
// Models
struct Message: Codable, Identifiable {
    let id: String
    let content: String
    let senderId: String
    let timestamp: Date
    let type: MessageType
    let deliveryStatus: DeliveryStatus
}

struct User: Codable, Identifiable {
    let id: String
    let displayName: String
    let profileImageURL: String?
    let isOnline: Bool
    let lastSeen: Date
}

struct Chat: Codable, Identifiable {
    let id: String
    let participants: [String]
    let lastMessage: Message?
    let isGroup: Bool
    let groupName: String?
}
```

#### 2. Repository Layer
```swift
protocol MessageRepository {
    func sendMessage(_ message: Message) async throws
    func observeMessages(for chatId: String) -> AsyncThrowingStream<[Message], Error>
    func markAsRead(messageId: String) async throws
}

protocol UserRepository {
    func getCurrentUser() async throws -> User
    func searchUsers(query: String) async throws -> [User]
    func updateUserPresence(isOnline: Bool) async throws
}

protocol AIRepository {
    func processMessage(_ message: String, context: [Message]) async throws -> AIResponse
    func summarizeConversation(_ messages: [Message]) async throws -> String
    func extractActionItems(_ messages: [Message]) async throws -> [ActionItem]
}
```

#### 3. Service Layer
```swift
class MessageService: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isConnected: Bool = false
    
    private let repository: MessageRepository
    private let aiRepository: AIRepository
    
    func sendMessage(_ content: String, to chatId: String) async {
        // Optimistic update
        let tempMessage = Message(/* ... */)
        messages.append(tempMessage)
        
        do {
            let message = try await repository.sendMessage(tempMessage)
            // Update with server response
        } catch {
            // Handle error, revert optimistic update
        }
    }
}

class AIService: ObservableObject {
    @Published var aiSuggestions: [AISuggestion] = []
    
    func processConversation(_ messages: [Message]) async {
        // Implement AI processing based on chosen persona
    }
}
```

#### 4. View Layer (SwiftUI)
```swift
struct ChatView: View {
    @StateObject private var messageService = MessageService()
    @StateObject private var aiService = AIService()
    
    var body: some View {
        VStack {
            MessageList(messages: messageService.messages)
            MessageInput(onSend: messageService.sendMessage)
            AISuggestionsBar(suggestions: aiService.aiSuggestions)
        }
    }
}
```

## Firebase Backend Architecture

### Firestore Database Structure
```javascript
// Collections
users: {
  [userId]: {
    displayName: string,
    profileImageURL: string,
    isOnline: boolean,
    lastSeen: timestamp,
    preferences: object
  }
}

chats: {
  [chatId]: {
    participants: [userId1, userId2, ...],
    isGroup: boolean,
    groupName: string,
    createdAt: timestamp,
    lastMessage: {
      content: string,
      senderId: string,
      timestamp: timestamp
    }
  }
}

messages: {
  [messageId]: {
    chatId: string,
    content: string,
    senderId: string,
    timestamp: timestamp,
    type: string, // text, image, etc.
    deliveryStatus: string,
    aiProcessed: boolean
  }
}

aiContext: {
  [chatId]: {
    conversationSummary: string,
    actionItems: [object],
    sentiment: string,
    lastProcessed: timestamp
  }
}
```

### Cloud Functions
```javascript
// AI Processing Function
exports.processMessage = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const chatId = message.chatId;
    
    // Get conversation context
    const conversation = await getConversationContext(chatId);
    
    // Process with AI based on persona
    const aiResponse = await processWithAI(message, conversation);
    
    // Update AI context
    await updateAIContext(chatId, aiResponse);
    
    // Send push notification if needed
    if (aiResponse.requiresNotification) {
      await sendPushNotification(chatId, aiResponse);
    }
  });

// Message Delivery Function
exports.updateDeliveryStatus = functions.https
  .onCall(async (data, context) => {
    const { messageId, status } = data;
    
    await admin.firestore()
      .collection('messages')
      .doc(messageId)
      .update({ deliveryStatus: status });
  });
```

## AI Integration Architecture

### AI Service Layer
```swift
class AIService {
    private let openAIClient: OpenAIClient
    private let contextManager: ConversationContextManager
    
    func processMessage(_ message: Message, context: [Message]) async throws -> AIResponse {
        let prompt = buildPrompt(for: message, context: context)
        let response = try await openAIClient.generateResponse(prompt: prompt)
        return parseAIResponse(response)
    }
    
    private func buildPrompt(for message: Message, context: [Message]) -> String {
        // Build context-aware prompt based on chosen persona
        switch selectedPersona {
        case .remoteTeamProfessional:
            return buildTeamProfessionalPrompt(message, context)
        case .internationalCommunicator:
            return buildInternationalCommunicatorPrompt(message, context)
        // ... other personas
        }
    }
}
```

### RAG Pipeline
```swift
class ConversationContextManager {
    func getRelevantContext(for chatId: String, limit: Int = 50) async throws -> [Message] {
        // Retrieve recent messages
        let recentMessages = try await messageRepository.getRecentMessages(chatId: chatId, limit: limit)
        
        // Filter and rank by relevance
        let relevantMessages = await filterRelevantMessages(recentMessages)
        
        return relevantMessages
    }
    
    private func filterRelevantMessages(_ messages: [Message]) async -> [Message] {
        // Implement relevance filtering based on content, timestamps, etc.
        return messages
    }
}
```

## Data Flow

### Message Sending Flow
1. User types message in UI
2. SwiftUI updates local state (optimistic update)
3. MessageService sends to Firebase
4. Cloud Function processes message
5. AI processing (if enabled)
6. Real-time update to all participants
7. Delivery status updates

### AI Processing Flow
1. Message received in Firestore
2. Cloud Function triggers AI processing
3. Retrieve conversation context (RAG)
4. Process with OpenAI/Claude
5. Update AI context in Firestore
6. Send AI suggestions to clients
7. Update UI with AI features

## Security Architecture

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Messages are readable by chat participants
    match /messages/{messageId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
    }
    
    // Chats are readable by participants
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
    }
  }
}
```

### API Key Management
- OpenAI/Claude API keys stored in Firebase Cloud Functions
- Client never directly accesses AI APIs
- Rate limiting implemented in Cloud Functions
- User authentication required for all AI features

## Performance Optimizations

### Client-Side
- SwiftData for local message caching
- Image compression before upload
- Lazy loading of message history
- Background processing for AI features

### Server-Side
- Firestore indexing for efficient queries
- Cloud Function cold start optimization
- AI response caching
- Batch operations for multiple messages

## Scalability Considerations

### Horizontal Scaling
- Firebase automatically scales Firestore
- Cloud Functions scale based on demand
- CDN for media storage

### Data Partitioning
- Messages partitioned by chatId
- User data partitioned by userId
- AI context partitioned by chatId

## Monitoring & Analytics

### Client-Side
- Message delivery success rates
- AI feature usage analytics
- Performance metrics
- Error tracking

### Server-Side
- Cloud Function execution metrics
- Firestore read/write operations
- AI API usage and costs
- Push notification delivery rates

## Deployment Architecture

### iOS App
- Xcode project with SwiftUI
- Firebase SDK integration
- TestFlight for beta testing
- App Store for production

### Backend
- Firebase project with multiple environments
- Cloud Functions deployed via Firebase CLI
- Firestore with production security rules
- FCM for push notifications

### AI Services
- OpenAI/Claude API integration
- Function calling for tool use
- RAG pipeline for context retrieval
- Response caching for cost optimization
