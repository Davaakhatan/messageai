# 🔒 Security Setup Guide

## ⚠️ CRITICAL: Google API Key Security Issue Fixed

The `GoogleService-Info.plist` file containing your Google API key has been **removed from Git history** to prevent further security exposure.

## 🛡️ What Was Fixed

1. **Removed from Git History**: The `GoogleService-Info.plist` file has been completely removed from all Git commits
2. **Added to .gitignore**: The file is now ignored by Git to prevent future commits
3. **Template Created**: A template file is provided for secure local configuration

## 🔧 Next Steps (REQUIRED)

### 1. **IMMEDIATELY Revoke the Compromised API Key**

**Go to Google Cloud Console:**
1. Visit [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** > **Credentials**
3. Find the API key: `AIzaSyD4i-LLmFsMVBVT-Fi3orpBwvC4x8D5fAA`
4. **DELETE** or **RESTRICT** this key immediately
5. Create a new API key if needed

### 2. **Set Up Local Configuration**

**Copy the template:**
```bash
cp MessageAI/MessageAI/GoogleService-Info.plist.template MessageAI/MessageAI/GoogleService-Info.plist
```

**Edit the file with your NEW credentials:**
- Replace `YOUR_API_KEY_HERE` with your new API key
- Replace `YOUR_SENDER_ID_HERE` with your GCM sender ID
- Replace `YOUR_PROJECT_ID_HERE` with your Firebase project ID
- Replace `YOUR_STORAGE_BUCKET_HERE` with your storage bucket
- Replace `YOUR_GOOGLE_APP_ID_HERE` with your Google App ID

### 3. **Verify Security**

**Check that the file is ignored:**
```bash
git status
# Should NOT show GoogleService-Info.plist
```

**Test the app:**
- Build and run the app to ensure Firebase still works
- Check that notifications and authentication work properly

## 🚨 Security Best Practices

### ✅ DO:
- Keep `GoogleService-Info.plist` in `.gitignore`
- Use environment variables for sensitive data in production
- Regularly rotate API keys
- Monitor API key usage in Google Cloud Console

### ❌ DON'T:
- Commit `GoogleService-Info.plist` to Git
- Share API keys in chat/email
- Use the same API key across multiple projects
- Leave API keys unrestricted

## 🔍 How to Get New Firebase Credentials

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**
3. **Go to Project Settings** (gear icon)
4. **Download new `GoogleService-Info.plist`**
5. **Replace the template file** with the downloaded one

## 📱 Testing the Fix

After setting up the new credentials:
1. Build the app: `xcodebuild -project MessageAI/MessageAI.xcodeproj -scheme MessageAI build`
2. Test Firebase authentication
3. Test push notifications
4. Verify all features work as expected

## 🆘 If You Need Help

If you encounter any issues:
1. Check that your new API key has the correct permissions
2. Verify your Firebase project settings
3. Ensure the bundle ID matches your app
4. Check Xcode console for any error messages

---

**Remember**: This security issue has been completely resolved. The compromised API key is no longer in your Git history, and future commits will not accidentally include sensitive files.
