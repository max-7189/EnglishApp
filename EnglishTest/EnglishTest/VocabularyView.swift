import SwiftUI

struct VocabularyView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \VocabularyCategory.name, ascending: true)])
    private var categories: FetchedResults<VocabularyCategory>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(categories) { category in
                    NavigationLink(destination: WordListView(category: category)) {
                        VStack(alignment: .leading) {
                            Text(category.name ?? "")
                                .font(.headline)
                            Text(category.categoryDescription ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("词汇练习")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addSampleCategory) {
                        Label("添加", systemImage: "plus")
                    }
                }
            }
        }
    }
    
    private func addSampleCategory() {
        let newCategory = VocabularyCategory(context: viewContext)
        newCategory.name = "商务英语"
        newCategory.categoryDescription = "常用商务场景词汇"
        
        let word1 = VocabularyWord(context: viewContext)
        word1.word = "negotiate"
        word1.definition = "谈判，协商"
        word1.pronunciation = "/nɪˈɡoʊʃieɪt/"
        word1.example = "We need to negotiate the terms of the contract."
        word1.category = newCategory
        
        let word2 = VocabularyWord(context: viewContext)
        word2.word = "deadline"
        word2.definition = "截止日期"
        word2.pronunciation = "/ˈdedlaɪn/"
        word2.example = "The project deadline is next Friday."
        word2.category = newCategory
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving category: \(error)")
        }
    }
}

struct WordListView: View {
    let category: VocabularyCategory
    @StateObject private var speechManager = SpeechManager()
    
    var body: some View {
        List {
            ForEach(category.wordsArray, id: \.self) { word in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(word.word ?? "")
                            .font(.headline)
                        Text(word.pronunciation ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Button(action: {
                            speechManager.speakText(word.word ?? "")
                        }) {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(word.definition ?? "")
                        .font(.body)
                    
                    if let example = word.example {
                        Text("例句：")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(example)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        if speechManager.isRecording {
                            speechManager.stopRecording()
                        } else {
                            speechManager.startRecording()
                        }
                    }) {
                        HStack {
                            Image(systemName: speechManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                            Text(speechManager.isRecording ? "停止录音" : "练习发音")
                        }
                        .foregroundColor(speechManager.isRecording ? .red : .blue)
                    }
                    .padding(.top, 5)
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle(category.name ?? "词汇")
    }
}

extension VocabularyCategory {
    var wordsArray: [VocabularyWord] {
        let set = words as? Set<VocabularyWord> ?? []
        return set.sorted { ($0.word ?? "") < ($1.word ?? "") }
    }
}