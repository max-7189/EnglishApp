import Foundation

struct Message: Identifiable {
    let id = UUID()
    let isUser: Bool
    let text: String
    let isRecording: Bool
    
    init(isUser: Bool, text: String, isRecording: Bool = false) {
        self.isUser = isUser
        self.text = text
        self.isRecording = isRecording
    }
}