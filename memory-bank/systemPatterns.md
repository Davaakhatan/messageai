# MessageAI - System Patterns

## Architecture Overview

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

### Core Design Patterns

#### 1. MVVM Architecture
- **Models**: Data structures and business logic
- **Views**: SwiftUI UI components
- **ViewModels**: ObservableObject classes that manage state and business logic
- **Services**: Repository pattern for data access

#### 2. Repository Pattern
```swift
protocol MessageRepository {
    func sendMessage(_ message: Message) async throws
    func observeMessages(for chatId: String) -> AsyncThrowingStream<[Message], Error>
    func markAsRead(messageId: String) async throws
}
```

#### 3. Service Layer Pattern
```swift
class MessageService: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isConnected: Bool = false
    
    private let repository: MessageRepository
    private let aiRepository: AIRepository
}
```

### Data Layer Patterns

#### 1. Model Definitions
```swift
struct Message: Codable, Identifiable {
    let id: String
    let content: String
    let senderId: String
    let timestamp: Date
    let type: MessageType
    let deliveryStatus: DeliveryStatus
}
```

#### 2. SwiftData Integration
- Local caching for offline support
- Optimistic updates for instant UI feedback
- Background synchronization with Firebase

#### 3. Async/Await Concurrency
- Modern Swift concurrency for API calls
- Proper error handling with try/catch
- Background task management

### UI Layer Patterns

#### 1. SwiftUI Views
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

#### 2. ObservableObject State Management
- Published properties for reactive UI updates
- State management across view hierarchy
- Proper lifecycle management

#### 3. Custom View Components
- Reusable UI components
- Consistent design patterns
- Accessibility support

## Firebase Backend Patterns

### Database Structure

#### 1. Firestore Collections
```javascript
// Users collection
users: {
  [userId]: {
    displayName: string,
    profileImageURL: string,
    isOnline: boolean,
    lastSeen: timestamp,
    preferences: object
  }
}

// Chats collection
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

// Messages collection
messages: {
  [messageId]: {
    chatId: string,
    content: string,
    senderId: string,
    timestamp: timestamp,
    type: string,
    deliveryStatus: string,
    aiProcessed: boolean
  }
}
```

#### 2. Real-time Listeners
- Firestore real-time listeners for live updates
- Proper listener cleanup and management
- Error handling and reconnection logic

#### 3. Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /messages/{messageId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
    }
  }
}
```

### Cloud Functions Patterns

#### 1. Event-Driven Functions
```javascript
exports.processMessage = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    // Process with AI
    const aiResponse = await processWithAI(message);
    // Update context
    await updateAIContext(chatId, aiResponse);
  });
```

#### 2. HTTP Callable Functions
```javascript
exports.updateDeliveryStatus = functions.https
  .onCall(async (data, context) => {
    const { messageId, status } = data;
    await admin.firestore()
      .collection('messages')
      .doc(messageId)
      .update({ deliveryStatus: status });
  });
```

## AI Integration Patterns

### AI Service Architecture

#### 1. Context Management
```swift
class ConversationContextManager {
    func getRelevantContext(for chatId: String, limit: Int = 50) async throws -> [Message] {
        let recentMessages = try await messageRepository.getRecentMessages(chatId: chatId, limit: limit)
        let relevantMessages = await filterRelevantMessages(recentMessages)
        return relevantMessages
    }
}
```

#### 2. RAG Pipeline
- Retrieve relevant conversation context
- Augment prompts with context
- Generate contextually aware responses
- Cache responses for cost optimization

#### 3. Persona-Specific Processing
```swift
class AIService {
    private func buildPrompt(for message: Message, context: [Message]) -> String {
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

## Data Flow Patterns

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

## Error Handling Patterns

### 1. Graceful Degradation
- App continues to function when AI features fail
- Fallback to basic messaging when services unavailable
- Clear error messages to users

### 2. Retry Mechanisms
- Exponential backoff for failed API calls
- Automatic reconnection for real-time listeners
- Queue management for offline messages

### 3. User Feedback
- Loading states for async operations
- Error messages with actionable suggestions
- Success confirmations for important actions

## Performance Patterns

### 1. Optimistic Updates
- Instant UI updates for better perceived performance
- Background synchronization with server
- Rollback on failure

### 2. Caching Strategies
- Local SwiftData cache for messages
- AI response caching to reduce costs
- Image compression and optimization

### 3. Background Processing
- AI processing in background
- Message synchronization when app backgrounded
- Proper task management

## Security Patterns

### 1. Authentication
- Firebase Auth for user management
- JWT token validation
- Secure API key storage

### 2. Data Protection
- Firestore security rules
- Client-side data validation
- Secure API communication

### 3. Privacy
- Local storage for sensitive data
- User consent for AI processing
- Data retention policies

## Testing Patterns

### 1. Unit Testing
- Service layer testing
- Model validation
- Business logic testing

### 2. Integration Testing
- Firebase integration testing
- AI service testing
- End-to-end user flows

### 3. Performance Testing
- Message delivery performance
- AI response times
- Memory usage monitoring

## Deployment Patterns

### 1. Environment Management
- Development, staging, production environments
- Environment-specific configuration
- Feature flags for gradual rollouts

### 2. CI/CD Pipeline
- Automated testing
- Build and deployment automation
- Rollback capabilities

### 3. Monitoring
- Performance metrics
- Error tracking
- User analytics
