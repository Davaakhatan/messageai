# MessageAI

**Advanced AI-Powered Messaging App for iOS**

*Developed by: Davaakhatan Zorigtbaatar*

## 🚀 Overview

MessageAI is a cutting-edge iOS messaging application that integrates advanced AI capabilities to provide intelligent, proactive assistance in real-time conversations. Built with SwiftUI and Firebase, it offers a seamless messaging experience with AI-powered features that enhance productivity and collaboration.

## ✨ Key Features

### 🤖 Proactive AI Assistant
- **Intelligent Conversation Monitoring**: Automatically analyzes conversations to detect scheduling opportunities, action items, and important decisions
- **Smart Suggestions**: Provides context-aware recommendations without explicit user requests
- **Real-time Analysis**: Monitors chat patterns and suggests optimal meeting times, action items, and conversation summaries

### 📱 Core Messaging
- **Real-time Chat**: Instant messaging with Firebase Firestore integration
- **Group & 1-on-1 Chats**: Support for both individual and group conversations
- **Message Status**: Delivery and read receipts for all messages
- **User Search**: Find users by email or display name

### 🔄 Offline Support
- **Message Queuing**: Automatically queues messages when offline
- **Auto-send**: Sends queued messages when connection is restored
- **Connection Status**: Visual indicator of network connectivity
- **Reliable Delivery**: Ensures no messages are lost during network issues

### 📊 AI Insights
- **Meeting Summaries**: Automatic generation of meeting summaries with key points and action items
- **Action Item Detection**: Identifies and tracks tasks mentioned in conversations
- **Decision Tracking**: Captures important decisions made during discussions
- **Priority Messages**: Highlights urgent or important messages

### 🎯 Task Management
- **AI-Generated Tasks**: Automatically creates tasks from conversation analysis
- **Task Integration**: Seamless integration with AI Assistant for task management
- **Due Date Tracking**: Smart due date suggestions based on conversation context

## 🏗️ Technical Architecture

### Frontend (iOS)
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for data flow
- **Network Framework**: Real-time connectivity monitoring
- **UserDefaults**: Local storage for offline message queuing

### Backend (Firebase)
- **Firestore**: Real-time NoSQL database
- **Firebase Auth**: User authentication and management
- **Firebase Storage**: Media file storage (future enhancement)
- **Cloud Functions**: Server-side AI processing (future enhancement)

### AI Integration
- **Proactive Monitoring**: Real-time conversation analysis
- **Keyword Detection**: Smart pattern recognition for scheduling and action items
- **Context Awareness**: Understanding conversation flow and context
- **Suggestion Engine**: Intelligent recommendation system

## 📱 Screenshots

*Screenshots will be added here*

## 🛠️ Installation & Setup

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Firebase project setup
- CocoaPods (for Firebase dependencies)

### Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Davaakhatan/messageai.git
   cd messageai
   ```

2. **Firebase Configuration**
   - Create a new Firebase project
   - Enable Authentication (Email/Password)
   - Enable Firestore Database
   - Download `GoogleService-Info.plist` and add to the project
   - Update Firestore security rules (see `firestore.rules`)

3. **Install Dependencies**
   ```bash
   cd MessageAI
   pod install
   ```

4. **Build and Run**
   - Open `MessageAI.xcworkspace` in Xcode
   - Select your target device or simulator
   - Build and run the project

### Firebase Setup

1. **Authentication**
   - Enable Email/Password authentication
   - Configure sign-in methods

2. **Firestore Database**
   - Create database in production mode
   - Deploy security rules from `firestore.rules`
   - Create required indexes for optimal performance

3. **Security Rules**
   ```javascript
   // Users can read all user data for search functionality
   // Users can only write to their own data
   // Chat participants can read/write messages and chat data
   ```

## 🔧 Configuration

### Environment Variables
- Firebase configuration is handled through `GoogleService-Info.plist`
- No additional environment variables required

### Firestore Indexes
The following composite indexes are required for optimal performance:
- `messages`: `deliveryStatus` (Ascending), `timestamp` (Descending)
- `chats`: `participants` (Arrays), `lastMessageAt` (Descending)
- `proactiveSuggestions`: `chatId` (Ascending), `actedOn` (Ascending), `dismissed` (Ascending)

## 🚀 Features in Detail

### Proactive AI Assistant
The AI assistant continuously monitors conversations and provides intelligent suggestions:

- **Scheduling Detection**: Identifies when users are trying to schedule meetings
- **Action Item Extraction**: Automatically detects and suggests action items
- **Conversation Summaries**: Generates summaries for long conversations
- **Smart Recommendations**: Suggests optimal meeting times and follow-up actions

### Offline Message Queue
Robust offline support ensures no messages are lost:

- **Automatic Queuing**: Messages are stored locally when offline
- **Smart Retry Logic**: Exponential backoff for failed message delivery
- **Connection Monitoring**: Real-time network status detection
- **Seamless Sync**: Automatic synchronization when connection is restored

### Real-time Collaboration
Enhanced collaboration features:

- **Live Typing Indicators**: See when others are typing
- **Message Status**: Delivery and read receipts
- **User Presence**: Online/offline status indicators
- **Group Management**: Easy group creation and member management

## 🎯 Use Cases

### Business Teams
- **Meeting Coordination**: AI suggests optimal meeting times
- **Action Item Tracking**: Automatic task creation from conversations
- **Decision Documentation**: Captures and tracks important decisions
- **Project Updates**: Smart summaries of project discussions

### Personal Use
- **Smart Scheduling**: AI helps coordinate personal meetings
- **Task Management**: Converts conversations into actionable tasks
- **Memory Aid**: Summarizes important conversations
- **Productivity Boost**: Reduces manual task management

## 🔮 Future Enhancements

### Planned Features
- **Voice Messages**: Audio message support with transcription
- **File Sharing**: Document and media sharing capabilities
- **Video Calls**: Integrated video calling functionality
- **Advanced AI**: GPT integration for more sophisticated AI features
- **Push Notifications**: Real-time notification system
- **Calendar Integration**: Direct calendar scheduling from AI suggestions

### Technical Improvements
- **Performance Optimization**: Enhanced query performance and caching
- **Security Enhancements**: End-to-end encryption for messages
- **Scalability**: Support for larger teams and organizations
- **Analytics**: Usage analytics and insights dashboard

## 🤝 Contributing

This is a personal project developed by Davaakhatan Zorigtbaatar. For questions or collaboration opportunities, please contact:

- **Email**: [Your Email]
- **LinkedIn**: [Your LinkedIn]
- **GitHub**: [@Davaakhatan](https://github.com/Davaakhatan)

## 📄 License

This project is developed as part of the Gauntlet AI Cohort program. All rights reserved.

## 🙏 Acknowledgments

- **Gauntlet AI**: For the comprehensive AI development program
- **Firebase**: For providing robust backend infrastructure
- **SwiftUI Community**: For excellent documentation and examples
- **iOS Development Community**: For continuous learning and inspiration

---

**Developed with ❤️ by Davaakhatan Zorigtbaatar**

*Building the future of intelligent communication*
