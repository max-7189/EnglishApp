import SwiftUI

struct ScenarioView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Scenario.title, ascending: true)])
    private var scenarios: FetchedResults<Scenario>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(scenarios) { scenario in
                    NavigationLink(destination: DialogueView(scenario: scenario)) {
                        VStack(alignment: .leading) {
                            Text(scenario.title ?? "")
                                .font(.headline)
                            Text(scenario.category ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(scenario.scenarioDescription ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("情景对话")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: addSampleScenario) {
                        Label("添加", systemImage: "plus")
                    }
                }
            }
        }
    }
    
    private func addSampleScenario() {
        let newScenario = Scenario(context: viewContext)
        newScenario.title = "机场对话"
        newScenario.category = "旅游"
        newScenario.scenarioDescription = "在机场办理登机手续和安检的对话"
        
        let dialogue1 = Dialogue(context: viewContext)
        dialogue1.speaker = "旅客"
        dialogue1.content = "Excuse me, where is the check-in counter for flight CA123?"
        dialogue1.order = 0
        dialogue1.scenario = newScenario
        
        let dialogue2 = Dialogue(context: viewContext)
        dialogue2.speaker = "工作人员"
        dialogue2.content = "The check-in counter is at Row B, counter number 15."
        dialogue2.order = 1
        dialogue2.scenario = newScenario
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving scenario: \(error)")
        }
    }
}

struct DialogueView: View {
    let scenario: Scenario
    @StateObject private var speechManager = SpeechManager()
    
    var body: some View {
        List {
            ForEach(scenario.dialoguesArray) { dialogue in
                VStack(alignment: .leading) {
                    Text(dialogue.speaker ?? "")
                        .font(.headline)
                    Text(dialogue.content ?? "")
                        .padding(.vertical, 5)
                    HStack {
                        Button(action: {
                            speechManager.speakText(dialogue.content ?? "")
                        }) {
                            Image(systemName: "play.circle.fill")
                                .foregroundColor(.blue)
                        }
                        Button(action: {
                            if speechManager.isRecording {
                                speechManager.stopRecording()
                            } else {
                                speechManager.startRecording()
                            }
                        }) {
                            Image(systemName: speechManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .foregroundColor(speechManager.isRecording ? .red : .blue)
                        }
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .navigationTitle(scenario.title ?? "对话")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: ContentView()) {
                    Image(systemName: "house")
                }
            }
        }
    }
}

extension Scenario {
    var dialoguesArray: [Dialogue] {
        let set = dialogues as? Set<Dialogue> ?? []
        return set.sorted { $0.order < $1.order }
    }
}