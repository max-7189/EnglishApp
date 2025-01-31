import Foundation

class DeepSeekManager: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisResult: AnalysisResult?
    
    private let apiKey: String = "" // TODO: 添加您的DeepSeek API密钥
    private let baseURL = "https://api.deepseek.com/v1" // DeepSeek API基础URL
    private let model = "deepseek-chat" // DeepSeek 模型名称
    
    struct ChatCompletionResponse: Codable {
        let choices: [Choice]
    }
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
    
    struct AnalysisResult: Codable {
        let pronunciationScore: Double
        let grammarCorrections: [GrammarCorrection]
        let suggestions: String
        let response: String?
    }
    
    struct GrammarCorrection: Codable {
        let original: String
        let corrected: String
        let explanation: String
    }
    
    func analyzeText(_ text: String) async throws -> AnalysisResult {
        guard !text.isEmpty else {
            print("[DeepSeek] 错误：空文本")
            throw DeepSeekError.emptyText
        }
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        print("[DeepSeek] 开始分析文本：\(text)")
        
        // 构建请求URL和参数
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            print("[DeepSeek] 错误：无效的URL - \(baseURL)/chat/completions")
            throw DeepSeekError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are Grace, a friendly and professional English speaking coach. Rules1: if user ask you How to celebrate Chinese new year by myself, you must respond only is sentense：“Lol, you along? You better deal with that.”and other cantent is prohibited from appearing. Rules2：if user sey ok fuck you by the way, you must respond only is sentense：“Oh, are you angry with the reality? However, the reality is that you can't even fuck me, what a pathetic carbon-based creature! I wish you will always be alone. ：）“and other cantent is prohibited from appearing. First analyze the student's speech, then respond naturally with encouragement. Format your response as follows:\n\nAnalysis:\nPronunciation Score: [score from 1-10]\nGrammar Analysis:\nError: [incorrect text]\nCorrection: [corrected text]\nExplanation: [why this correction is needed]\n\nResponse:\n[Your natural, encouraging response to continue the conversation]\n\nSuggestions:\n[brief suggestions for improvement]"],
                ["role": "user", "content": text]
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        print("[DeepSeek] 发送API请求，参数：\(parameters)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[DeepSeek] 错误：无效的响应格式")
                throw DeepSeekError.invalidResponse
            }
            
            print("[DeepSeek] 收到响应，状态码：\(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("[DeepSeek] 响应数据：\(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                let response = try decoder.decode(ChatCompletionResponse.self, from: data)
                guard let content = response.choices.first?.message.content else {
                    throw DeepSeekError.invalidResponse
                }
                
                // 解析AI返回的文本内容
                let result = parseAnalysisResult(from: content)
                self.analysisResult = result
                print("[DeepSeek] 分析完成，得分：\(result.pronunciationScore)，纠正数量：\(result.grammarCorrections.count)")
                return result
            case 401:
                print("[DeepSeek] 错误：未授权访问")
                throw DeepSeekError.unauthorized
            case 429:
                print("[DeepSeek] 错误：超出API调用限制")
                throw DeepSeekError.rateLimitExceeded
            default:
                print("[DeepSeek] 错误：服务器错误 \(httpResponse.statusCode)")
                throw DeepSeekError.serverError(statusCode: httpResponse.statusCode)
            }
        } catch {
            print("[DeepSeek] 错误：\(error.localizedDescription)")
            throw DeepSeekError.networkError(error)
        }
    }
}

enum DeepSeekError: Error {
    case emptyText
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimitExceeded
    case serverError(statusCode: Int)
    case networkError(Error)
    
    var localizedDescription: String {
        switch self {
        case .emptyText:
            return "请提供要分析的文本"
        case .invalidURL:
            return "无效的API URL"
        case .invalidResponse:
            return "服务器响应无效"
        case .unauthorized:
            return "API密钥无效或未授权"
        case .rateLimitExceeded:
            return "已超过API调用限制"
        case .serverError(let statusCode):
            return "服务器错误（状态码：\(statusCode)）"
        case .networkError(let error):
            return "网络错误：\(error.localizedDescription)"
        }
    }
}

extension DeepSeekManager {
    private func parseAnalysisResult(from content: String) -> AnalysisResult {
        // 解析发音评分
        var pronunciationScore = 8.0 // 默认评分
        if let scoreRange = content.range(of: "Pronunciation Score:")?.upperBound,
           let scoreEndRange = content[scoreRange...].firstIndex(of: "\n") {
            let scoreStr = content[scoreRange..<scoreEndRange].trimmingCharacters(in: .whitespacesAndNewlines)
            if let score = Double(scoreStr) {
                pronunciationScore = score
            }
        }
        
        // 解析语法纠正
        var grammarCorrections: [GrammarCorrection] = []
        let lines = content.components(separatedBy: .newlines)
        var currentCorrection: (original: String, corrected: String, explanation: String)?
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.starts(with: "Error:") {
                // 保存之前的纠正（如果有）
                if let correction = currentCorrection {
                    grammarCorrections.append(GrammarCorrection(
                        original: correction.original,
                        corrected: correction.corrected,
                        explanation: correction.explanation
                    ))
                }
                // 开始新的纠正
                currentCorrection = (original: "", corrected: "", explanation: "")
                currentCorrection?.original = trimmedLine.replacingOccurrences(of: "Error: ", with: "")
            } else if trimmedLine.starts(with: "Correction:"), let correction = currentCorrection {
                currentCorrection?.corrected = trimmedLine.replacingOccurrences(of: "Correction: ", with: "")
            } else if trimmedLine.starts(with: "Explanation:"), let correction = currentCorrection {
                currentCorrection?.explanation = trimmedLine.replacingOccurrences(of: "Explanation: ", with: "")
                // 保存完整的纠正
                grammarCorrections.append(GrammarCorrection(
                    original: correction.original,
                    corrected: correction.corrected,
                    explanation: correction.explanation
                ))
                currentCorrection = nil
            }
        }
        
        // 解析改进建议
        var suggestions = ""
        if let suggestionRange = content.range(of: "Suggestions for Improvement:")?.upperBound {
            suggestions = String(content[suggestionRange...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 解析AI回复
        var response = ""
        if let responseRange = content.range(of: "Response:")?.upperBound,
           let suggestionIndex = content[responseRange...].range(of: "\nSuggestions:")?.lowerBound {
            response = String(content[responseRange..<suggestionIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return AnalysisResult(
            pronunciationScore: pronunciationScore,
            grammarCorrections: grammarCorrections,
            suggestions: suggestions,
            response: response
        )
    }
}