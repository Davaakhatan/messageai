import Foundation
import SwiftUI
import Combine

// MARK: - Error Types
enum MessageAIError: LocalizedError {
    case networkUnavailable
    case authenticationFailed
    case messageSendFailed
    case userNotFound
    case chatCreationFailed
    case imageUploadFailed
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Please check your network and try again."
        case .authenticationFailed:
            return "Authentication failed. Please sign in again."
        case .messageSendFailed:
            return "Failed to send message. Please try again."
        case .userNotFound:
            return "User not found. Please check the username and try again."
        case .chatCreationFailed:
            return "Failed to create chat. Please try again."
        case .imageUploadFailed:
            return "Failed to upload image. Please try again."
        case .unknown(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .authenticationFailed:
            return "Please sign out and sign in again."
        case .messageSendFailed:
            return "Check your connection and try sending the message again."
        case .userNotFound:
            return "Make sure the username is correct and the user exists."
        case .chatCreationFailed:
            return "Please try creating the chat again."
        case .imageUploadFailed:
            return "Try selecting a smaller image or check your connection."
        case .unknown:
            return "Please try again or contact support if the problem persists."
        }
    }
}

// MARK: - Error Handler
class ErrorHandler: ObservableObject {
    @Published var currentError: MessageAIError?
    @Published var showingAlert = false
    
    func handle(_ error: Error) {
        DispatchQueue.main.async {
            if let messageAIError = error as? MessageAIError {
                self.currentError = messageAIError
            } else {
                self.currentError = .unknown(error.localizedDescription)
            }
            self.showingAlert = true
        }
    }
    
    func clearError() {
        currentError = nil
        showingAlert = false
    }
}

// MARK: - Error View Modifier
struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorHandler.showingAlert) {
                Button("OK") {
                    errorHandler.clearError()
                }
            } message: {
                if let error = errorHandler.currentError {
                    Text(error.errorDescription ?? "An unknown error occurred")
                }
            }
    }
}

// MARK: - Loading States
enum LoadingState {
    case idle
    case loading
    case success
    case failed(MessageAIError)
}

// MARK: - Loading View
struct LoadingView: View {
    let message: String
    let isLoading: Bool
    
    var body: some View {
        if isLoading {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(20)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
}

// MARK: - View Extensions
extension View {
    func withErrorHandling(_ errorHandler: ErrorHandler) -> some View {
        self.modifier(ErrorAlertModifier(errorHandler: errorHandler))
    }
}
