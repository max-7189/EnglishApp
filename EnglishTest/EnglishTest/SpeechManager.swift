import Foundation
import Speech
import AVFoundation

class SpeechManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var currentTranscription = ""
    @Published var deepseekAnalysis = ""
    @Published var messages: [Message] = []
    private let deepseekManager = DeepSeekManager()
    
    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let synthesizer = AVSpeechSynthesizer()
    
    override init() {
        super.init()
        requestPermissions()
    }
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech recognition authorized")
                default:
                    print("Speech recognition authorization denied")
                }
            }
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            print("Microphone permission granted: \(granted)")
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            let inputNode = audioEngine.inputNode
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }
            recognitionRequest.shouldReportPartialResults = true
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                if let result = result {
                    self.currentTranscription = result.bestTranscription.formattedString
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            
            // 开始录音时添加一条用户消息
            messages.append(Message(isUser: true, text: "", isRecording: true))
        } catch {
            print("Recording failed: \(error)")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        isRecording = false
        transcribedText = currentTranscription
        
        // 更新最后一条用户消息
        if !messages.isEmpty {
            messages[messages.count - 1] = Message(isUser: true, text: currentTranscription, isRecording: false)
        }
        
        currentTranscription = ""
        analyzeWithDeepseek()
    }
    
    private func analyzeWithDeepseek() {
        print("[Speech] 开始DeepSeek分析，文本内容：\(transcribedText)")
        Task {
            do {
                print("[Speech] 调用DeepSeek API分析文本")
                let result = try await deepseekManager.analyzeText(transcribedText)
                print("[Speech] DeepSeek分析完成，更新UI显示结果")
                DispatchQueue.main.async {
                    self.deepseekAnalysis = "发音评分：\(result.pronunciationScore)\n\n" +
                        "语法纠正：\n" + result.grammarCorrections.map { "• \($0.original) → \($0.corrected)\n  说明：\($0.explanation)" }.joined(separator: "\n\n") +
                        "\n\n改进建议：\n\(result.suggestions)"
                    
                    // 添加AI回复消息并播放
                    if let response = result.response {
                        self.messages.append(Message(isUser: false, text: response, isRecording: false))
                        self.speakText(response)
                    }
                }
            } catch {
                print("[Speech] DeepSeek分析失败：\(error)")
                DispatchQueue.main.async {
                    self.deepseekAnalysis = "分析失败：\(error.localizedDescription)"
                }
            }
        }
    }
    
    func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
}