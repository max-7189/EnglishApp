import SwiftUI

struct SpeechView: View {
    @StateObject private var speechManager = SpeechManager()
    @Environment(\.managedObjectContext) private var viewContext
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                // 对话区域
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(Array(speechManager.messages.enumerated()), id: \.offset) { index, message in
                                let displayText = getDisplayText(message: message, index: index)
                                ChatBubble(isUser: message.isUser, text: displayText)
                                    .id(index)
                            }
                        }
                        .padding()
                    }
                    .frame(maxHeight: .infinity)
                    .background(Color(.systemGray6).opacity(0.3))
                    .onChange(of: speechManager.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(speechManager.messages.count - 1, anchor: .bottom)
                        }
                    }
                    .onAppear {
                        self.scrollProxy = proxy
                        // 添加AI的欢迎消息
                        if speechManager.messages.isEmpty {
                            let welcomeMessage = "Hello! I'm Grace, Let's start today's speaking practice!"
                            speechManager.messages.append(Message(isUser: false, text: welcomeMessage, isRecording: false))
                            speechManager.speakText(welcomeMessage)
                        }
                    }
                }
                
                // 评分区域
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("语法分析")
                            .font(.headline)
                            .padding(.bottom, 5)
                        let analysisText = getAnalysisText()
                        Text(analysisText)
                            .foregroundColor(speechManager.deepseekAnalysis.isEmpty ? .gray : .primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 3)
                    .padding()
                }
                .frame(height: 200)
                .background(Color(.systemGray6))
                
                // 录音按钮
                HStack(spacing: 30) {
                    Button(action: handleRecordButton) {
                        let isRecording = speechManager.isRecording
                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(isRecording ? .red : .blue)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("口语练习")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func getDisplayText(message: Message, index: Int) -> String {
        if message.isRecording && index == speechManager.messages.count - 1 {
            return speechManager.currentTranscription
        }
        return message.text
    }
    
    private func getAnalysisText() -> String {
        return speechManager.deepseekAnalysis.isEmpty ? "录音结束后将显示分析结果" : speechManager.deepseekAnalysis
    }
    
    private func handleRecordButton() {
        if speechManager.isRecording {
            speechManager.stopRecording()
            saveRecord()
        } else {
            speechManager.startRecording()
        }
    }
    
    private func saveRecord() {
        let newRecord = SpeechRecord(context: viewContext)
        newRecord.timestamp = Date()
        newRecord.transcription = speechManager.transcribedText
        newRecord.deepseekAnalysis = speechManager.deepseekAnalysis
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving record: \(error)")
        }
    }
}

struct SpeechView_Previews: PreviewProvider {
    static var previews: some View {
        SpeechView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}