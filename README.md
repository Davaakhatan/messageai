# MessageAI

**Advanced AI-Powered Messaging App for iOS**

*Developed by: Davaakhatan Zorigtbaatar*

## 🚀 Overview

MessageAI is a cutting-edge iOS messaging application that integrates advanced AI capabilities to provide intelligent, proactive assistance in real-time conversations. Built with SwiftUI and Firebase, it offers a seamless messaging experience with AI-powered features that enhance productivity and collaboration.

## ✨ Key Features

### 🤖 AI-Powered Team Features
- **Project Status Analysis**: AI-generated project status reports with team insights
- **Meeting Summaries**: Automatic generation of meeting summaries with key points and action items
- **Decision Tracking**: Captures and tracks important decisions made during discussions
- **Priority Detection**: Identifies and highlights urgent or important messages
- **Team Insights**: Collaboration analytics and team performance metrics
- **Smart Search**: Intelligent search across messages, users, chats, and AI-generated content
- **AI Assistant Chat**: Direct interaction with AI for project assistance and insights

### 📱 Core Messaging
- **Real-time Chat**: Instant messaging with Firebase Firestore integration
- **Group & 1-on-1 Chats**: Support for both individual and group conversations
- **Message Status**: Delivery and read receipts for all messages
- **User Search**: Find users by email or display name
- **Message Reactions**: Emoji reactions with real-time updates
- **Offline Messaging**: Queue messages when offline, auto-send when connected

### 🔄 Advanced Features
- **Dark/Light Mode**: Complete theme support with system integration
- **Push Notifications**: Real-time notifications for messages and reactions
- **Read Receipts**: Accurate read status tracking with user names
- **Message Reactions**: Add emoji reactions to any message
- **Offline Support**: Reliable message delivery with retry logic
- **Connection Status**: Visual indicators for network connectivity

### 🎨 Modern UI/UX
- **SwiftUI Design**: Modern, responsive interface
- **Settings Management**: Comprehensive app settings and preferences
- **Mock Testing**: Built-in testing tools for development and debugging
- **Help & Support**: Integrated help system and support features

## 🏗️ Technical Architecture

### Frontend (iOS)
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for data flow
- **Firebase SDK**: Real-time database and authentication
- **UserNotifications**: Local and remote notification handling
- **Network Monitoring**: Real-time connectivity detection

### Backend (Firebase)
- **Firestore**: Real-time NoSQL database with optimized queries
- **Firebase Auth**: User authentication and management
- **Firebase Storage**: Media file storage support
- **Cloud Functions**: Server-side processing capabilities

### AI Integration
- **OpenAI API**: Advanced AI capabilities for content analysis
- **Smart Search**: Intelligent content discovery and filtering
- **Project Analysis**: AI-powered project status generation
- **Content Summarization**: Automatic meeting and conversation summaries

## 📱 Current Features Status

### ✅ Fully Implemented
- **Real-time Messaging**: Complete chat functionality with Firebase
- **User Authentication**: Secure login and user management
- **Group Chats**: Multi-user conversation support
- **Read Receipts**: Accurate read status with proper sender exclusion
- **Message Reactions**: Emoji reactions with notifications
- **Push Notifications**: Local and remote notification system
- **Dark/Light Mode**: Complete theme support
- **Settings Management**: Comprehensive app configuration
- **Mock Testing**: Development and debugging tools
- **AI Team Features**: Project status, meeting summaries, decisions, insights
- **Smart Search**: Cross-content intelligent search
- **Offline Support**: Message queuing and retry logic

### 🔧 Recent Fixes
- **Read Receipt Logic**: Fixed sender exclusion from their own message read counts
- **Notification System**: Optimized notification delivery and display
- **User Name Resolution**: Proper display name handling across all features
- **UI Polish**: Modern design updates for all major views

## 🛠️ Installation & Setup

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Firebase project setup
- OpenAI API key (for AI features)

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

3. **OpenAI Configuration**
   - Get an OpenAI API key from https://platform.openai.com/
   - Configure the API key in the app's Team AI settings

4. **Build and Run**
   - Open `MessageAI.xcodeproj` in Xcode
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

3. **Required Firestore Indexes**
   ```javascript
   // Messages collection
   - chatId (Ascending), timestamp (Descending)
   - chatId (Ascending), senderId (Ascending), timestamp (Descending)
   
   // Chats collection  
   - participants (Arrays), lastMessageAt (Descending)
   
   // Notifications collection
   - userId (Ascending), timestamp (Descending)
   ```

## 🔧 Configuration

### Environment Variables
- Firebase configuration via `GoogleService-Info.plist`
- OpenAI API key configuration in app settings
- No additional environment variables required

### App Settings
- **Theme**: Dark/Light mode toggle
- **Notifications**: Push notification preferences
- **Font Size**: Customizable text size
- **Cache Management**: Clear app cache and data
- **Account Management**: Sign out and account deletion

## 🚀 Features in Detail

### AI Team Features
- **Project Status**: AI-generated project analysis with team member insights
- **Meeting Summaries**: Automatic extraction of key points and action items
- **Decision Tracking**: Capture and organize important decisions
- **Priority Detection**: Identify urgent messages and tasks
- **Team Insights**: Collaboration analytics and performance metrics
- **Smart Search**: Search across all content types with intelligent filtering

### Real-time Messaging
- **Instant Delivery**: Real-time message synchronization
- **Read Receipts**: Accurate read status with user names
- **Message Reactions**: Emoji reactions with notifications
- **Group Management**: Easy group creation and member management
- **User Search**: Find and add users to conversations

### Notification System
- **Push Notifications**: Real-time message and reaction notifications
- **Local Notifications**: Offline notification support
- **Notification Categories**: Different notification types for messages and reactions
- **Simulator Support**: Full notification testing on iOS Simulator

## 🎯 Use Cases

### Business Teams
- **Project Management**: AI-powered project status and insights
- **Meeting Coordination**: Automatic meeting summaries and action items
- **Decision Documentation**: Track and organize important decisions
- **Team Collaboration**: Enhanced communication with AI assistance

### Development Teams
- **Code Reviews**: AI-assisted code discussion and feedback
- **Project Planning**: AI-generated project status and recommendations
- **Task Management**: Automatic task extraction from conversations
- **Knowledge Sharing**: Smart search across all team communications

## 🔮 Future Enhancements

### Planned Features
- **Voice Messages**: Audio message support with transcription
- **File Sharing**: Document and media sharing capabilities
- **Video Calls**: Integrated video calling functionality
- **Calendar Integration**: Direct calendar scheduling from AI suggestions
- **Advanced Analytics**: Detailed usage and collaboration insights

### Technical Improvements
- **Performance Optimization**: Enhanced query performance and caching
- **Security Enhancements**: End-to-end encryption for messages
- **Scalability**: Support for larger teams and organizations
- **Advanced AI**: More sophisticated AI features and integrations

## 🧪 Testing

### Mock Testing Features
- **Connection Simulation**: Test offline/online scenarios
- **Message Generation**: Create test messages and conversations
- **Notification Testing**: Test notification delivery and display
- **User Simulation**: Simulate different user scenarios
- **Debug Tools**: Comprehensive debugging and testing utilities

### Testing Scenarios
- **Read Receipt Testing**: Verify accurate read status tracking
- **Notification Testing**: Test message and reaction notifications
- **Offline Testing**: Test message queuing and retry logic
- **AI Feature Testing**: Test all AI-powered features and responses

## 🤝 Contributing

This is a personal project developed by Davaakhatan Zorigtbaatar. For questions or collaboration opportunities, please contact:

- **GitHub**: [@Davaakhatan](https://github.com/Davaakhatan)
- **Project Repository**: https://github.com/Davaakhatan/messageai

## 📄 License

This project is developed as part of the Gauntlet AI Cohort program. All rights reserved.

## 🙏 Acknowledgments

- **Gauntlet AI**: For the comprehensive AI development program
- **Firebase**: For providing robust backend infrastructure
- **OpenAI**: For advanced AI capabilities and integration
- **SwiftUI Community**: For excellent documentation and examples
- **iOS Development Community**: For continuous learning and inspiration

---

**Developed with ❤️ by Davaakhatan Zorigtbaatar**

*Building the future of intelligent communication*

## 📊 Project Status

**Current Version**: 1.0.0  
**Last Updated**: October 2024  
**Status**: Active Development  
**Platform**: iOS 17.0+  
**Language**: Swift 5.9+  
**Framework**: SwiftUI + Firebase