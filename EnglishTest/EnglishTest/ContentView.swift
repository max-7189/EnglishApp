import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    NavigationLink(destination: SpeechView()) {
                        FeatureCard(
                            title: "口语练习",
                            description: "练习英语口语，获取即时反馈",
                            systemImage: "waveform"
                        )
                    }
                    
                    NavigationLink(destination: ScenarioView()) {
                        FeatureCard(
                            title: "情景对话",
                            description: "体验真实英语对话场景",
                            systemImage: "bubble.left.and.bubble.right"
                        )
                    }
                    
                    NavigationLink(destination: VocabularyView()) {
                        FeatureCard(
                            title: "词汇学习",
                            description: "扩展词汇量，提高表达能力",
                            systemImage: "book"
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("英语学习助手")
        }
    }
}

struct FeatureCard: View {
    let title: String
    let description: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .font(.system(size: 30))
                .foregroundColor(.blue)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    ContentView()
}
