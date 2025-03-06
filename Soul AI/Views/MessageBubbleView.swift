import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if message.role == .assistant {
                HStack(alignment: .top) {
                    assistantIcon
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Soul AI")
                            .font(.caption)
                            .foregroundColor(Color.brandMint.opacity(0.7))
                        
                        Text(message.content)
                            .foregroundColor(Color.AppTheme.primaryText)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            } else {
                HStack(alignment: .top) {
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("You")
                            .font(.caption)
                            .foregroundColor(Color.brandMint.opacity(0.7))
                        
                        Text(message.content)
                            .foregroundColor(Color.AppTheme.primaryText)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    userIcon
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
        }
        .background(message.role == .assistant ? 
                    (colorScheme == .dark ? Color.AppTheme.darkModeCardBackground : Color.AppTheme.lightModeCardBackground) : 
                    (colorScheme == .dark ? Color(.systemGray6).opacity(0.1) : Color(.systemGray6).opacity(0.2)))
    }
    
    private var assistantIcon: some View {
        Image(systemName: "cross.fill")
            .foregroundColor(Color.brandMint)
            .font(.system(size: 16))
            .frame(width: 24, height: 24)
            .background(Circle().fill(colorScheme == .dark ? Color.black : Color.white))
            .overlay(
                Circle()
                    .stroke(Color.brandMint.opacity(0.5), lineWidth: 1)
            )
    }
    
    private var userIcon: some View {
        Image(systemName: "person.circle.fill")
            .foregroundColor(Color.brandMint)
            .font(.system(size: 16))
            .frame(width: 24, height: 24)
    }
}

#Preview {
    Group {
        VStack {
            MessageBubbleView(message: Message(content: "Hello, how can I help you today with your faith journey? I'm here to provide guidance and support based on Christian teachings.", role: .assistant))
            MessageBubbleView(message: Message(content: "I have a question about faith and doubt. How do I handle moments of uncertainty?", role: .user))
        }
        .background(Color.AppTheme.background)
    }
} 