import SwiftUI

struct TypingIndicatorView: View {
    let chatId: String
    @EnvironmentObject var messageService: MessageService
    
    private var typingUsers: [String] {
        messageService.getTypingUsers(for: chatId)
    }
    
    var body: some View {
        if !typingUsers.isEmpty {
            HStack {
                // Animated typing dots
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 6, height: 6)
                            .scaleEffect(typingAnimation ? 1.2 : 0.8)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: typingAnimation
                            )
                    }
                }
                
                // Typing text
                Text(typingText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .onAppear {
                typingAnimation = true
            }
        }
    }
    
    @State private var typingAnimation = false
    
    private var typingText: String {
        if typingUsers.count == 1 {
            return "\(typingUsers[0]) is typing..."
        } else if typingUsers.count == 2 {
            return "\(typingUsers[0]) and \(typingUsers[1]) are typing..."
        } else {
            return "\(typingUsers.count) people are typing..."
        }
    }
}

#Preview {
    TypingIndicatorView(chatId: "test-chat")
        .environmentObject(MessageService())
}
