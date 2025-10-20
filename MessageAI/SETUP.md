# MessageAI Setup Instructions

## Prerequisites
- Xcode 15.0+ (for iOS 17+ support)
- iOS Simulator or physical device
- Firebase account
- OpenAI API key (for AI features)

## Firebase Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: "MessageAI"
4. Enable Google Analytics (optional)
5. Create project

### 2. Configure iOS App
1. In Firebase Console, click "Add app" → iOS
2. Enter bundle ID: `com.messageai.app`
3. Download `GoogleService-Info.plist`
4. Replace the template file in `MessageAI/GoogleService-Info.plist` with your downloaded file

### 3. Enable Firebase Services
1. **Authentication**:
   - Go to Authentication → Sign-in method
   - Enable "Email/Password"
   - Enable "Apple" (optional)

2. **Firestore Database**:
   - Go to Firestore Database
   - Create database in production mode
   - The security rules are already configured in `firestore.rules`

3. **Cloud Functions**:
   - Go to Functions
   - Click "Get started"
   - Follow the setup instructions

4. **Cloud Messaging**:
   - Go to Cloud Messaging
   - No additional setup required

### 4. Skip Cloud Functions (Not Required)
Since Cloud Functions require a paid plan, we'll use direct API calls from the iOS app instead. This approach is simpler and works with the free Firebase plan.

## OpenAI Setup

### 1. Get API Key
1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Create account or sign in
3. Go to API Keys section
4. Create new secret key
5. Copy the key

### 2. Configure API Key in App
1. Run the MessageAI app
2. Go to AI Assistant tab
3. Tap "Settings" or "Add API Key"
4. Enter your OpenAI API key
5. The key will be stored locally on your device

## Xcode Setup

### 1. Open Project
1. Open `MessageAI.xcodeproj` in Xcode
2. Select your development team
3. Update bundle identifier if needed

### 2. Install Dependencies
1. Xcode will automatically resolve Swift Package Manager dependencies
2. Wait for packages to download

### 3. Configure Signing
1. Select the MessageAI target
2. Go to "Signing & Capabilities"
3. Select your development team
4. Enable "Automatically manage signing"

### 4. Build and Run
1. Select a simulator or device
2. Press Cmd+R to build and run
3. The app should launch successfully

## Testing the App

### 1. Create Test Users
1. Run the app
2. Tap "Sign Up"
3. Create 2-3 test accounts with different emails
4. Sign in with different accounts on different simulators/devices

### 2. Test Messaging
1. Create a new chat between users
2. Send messages and verify real-time delivery
3. Test group chats with 3+ users
4. Test offline/online scenarios

### 3. Test AI Features
1. Go to AI Assistant tab
2. Ask questions and verify responses
3. Test conversation context

## Troubleshooting

### Common Issues

1. **Build Errors**:
   - Clean build folder (Cmd+Shift+K)
   - Reset package caches (File → Packages → Reset Package Caches)
   - Check bundle identifier matches Firebase configuration

2. **Firebase Connection Issues**:
   - Verify `GoogleService-Info.plist` is correct
   - Check Firebase project configuration
   - Ensure all required services are enabled

3. **Authentication Issues**:
   - Check email/password authentication is enabled
   - Verify user creation in Firebase Console
   - Check security rules

4. **Real-time Issues**:
   - Check Firestore security rules
   - Verify network connectivity
   - Check Firebase project quotas

### Debug Mode
- Enable debug logging in Xcode console
- Check Firebase Console for errors
- Monitor Cloud Functions logs

## Next Steps

1. **Persona Selection**: Choose target persona for AI features
2. **AI Integration**: Implement persona-specific AI features
3. **Testing**: Comprehensive testing on real devices
4. **Deployment**: TestFlight setup for beta testing

## Support

- Check Firebase documentation for backend issues
- Check SwiftUI documentation for UI issues
- Check OpenAI documentation for AI integration issues
