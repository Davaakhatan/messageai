import SwiftUI

struct TypingIndicatorView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .offset(y: animationOffset)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animationOffset
                    )
            }
        }
        .onAppear {
            animationOffset = -4
        }
    }
}

struct TypingBubbleView: View {
    let senderName: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(senderName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 16)
                
                HStack(spacing: 8) {
                    TypingIndicatorView()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.gray.opacity(0.2))
                        )
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack {
        TypingIndicatorView()
            .padding()
        
        TypingBubbleView(senderName: "John")
            .padding()
    }
}
