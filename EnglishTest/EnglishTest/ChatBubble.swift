import SwiftUI

struct ChatBubble: View {
    let isUser: Bool
    let text: String
    
    var body: some View {
        HStack {
            if isUser { Spacer() }
            
            Text(text)
                .padding(12)
                .background(isUser ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: isUser ? .trailing : .leading)
            
            if !isUser { Spacer() }
        }
    }
}

#Preview {
    VStack {
        ChatBubble(isUser: true, text: "Hello, how are you?")
        ChatBubble(isUser: false, text: "I'm doing great! How about you?")
    }
    .padding()
}