import SwiftUI
import AVFoundation

struct BibleStudyView: View {
    // State variables
    @State private var selectedTopic: String = "Faith"
    @State private var selectedDuration: String = "1-5 minutes"
    @State private var selectedScripture: String = "Select scripture"
    @State private var isGenerating: Bool = false
    @State private var previousStudies: [BibleStudyEntry] = []
    @State private var showTopicPicker: Bool = false
    @State private var showScripturePicker: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    // Audio player
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying: Bool = false
    @State private var currentlyPlayingIndex: Int?
    
    // Topics and durations
    let topics = ["Faith", "Hope", "Love", "Forgiveness", "Prayer", "Wisdom", "Patience", "Kindness", "Peace", "Joy"]
    let durations = ["1-5 minutes", "5-10 minutes", "10-15 minutes", "15-20 minutes"]
    let scriptures = ["John 3:16", "Psalm 23", "Romans 8:28", "Philippians 4:13", "Jeremiah 29:11", "Proverbs 3:5-6", "Matthew 6:33", "Isaiah 40:31", "2 Corinthians 5:17", "Galatians 5:22-23"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.AppTheme.background.edgesIgnoringSafeArea(.all)
                
                VStack(alignment: .leading, spacing: 20) {
                    // Bible Study Topic
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bible Study Topic")
                            .font(.headline)
                            .foregroundColor(Color.AppTheme.primaryText)
                        
                        Button(action: {
                            showTopicPicker.toggle()
                        }) {
                            HStack {
                                Text(selectedTopic)
                                    .foregroundColor(Color.AppTheme.primaryText)
                                    .padding()
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color.AppTheme.primaryText)
                                    .padding(.trailing)
                            }
                            .background(Color.AppTheme.inputBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.AppTheme.brandMint.opacity(0.5), lineWidth: 1)
                            )
                            .cornerRadius(10)
                        }
                        .sheet(isPresented: $showTopicPicker) {
                            VStack {
                                Text("Select a Topic")
                                    .font(.headline)
                                    .padding()
                                
                                List {
                                    ForEach(topics, id: \.self) { topic in
                                        Button(action: {
                                            selectedTopic = topic
                                            showTopicPicker = false
                                        }) {
                                            Text(topic)
                                                .foregroundColor(selectedTopic == topic ? .AppTheme.brandMint : .primary)
                                        }
                                    }
                                }
                                
                                Button("Cancel") {
                                    showTopicPicker = false
                                }
                                .padding()
                            }
                            .presentationDetents([.medium])
                        }
                    }
                    
                    // Duration
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration")
                            .font(.headline)
                            .foregroundColor(Color.AppTheme.primaryText)
                        
                        Menu {
                            ForEach(durations, id: \.self) { duration in
                                Button(action: {
                                    selectedDuration = duration
                                }) {
                                    Text(duration)
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedDuration)
                                    .foregroundColor(Color.AppTheme.primaryText)
                                    .padding()
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color.AppTheme.inputBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.AppTheme.brandMint.opacity(0.5), lineWidth: 1)
                            )
                            .cornerRadius(10)
                        }
                    }
                    
                    // Scripture Reference
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Scripture Reference")
                                .font(.headline)
                                .foregroundColor(Color.AppTheme.primaryText)
                            
                            Text("(Premium)")
                                .font(.subheadline)
                                .foregroundColor(Color.AppTheme.secondaryText)
                        }
                        
                        Button(action: {
                            showScripturePicker.toggle()
                        }) {
                            HStack {
                                Text(selectedScripture)
                                    .foregroundColor(Color.AppTheme.primaryText)
                                    .padding()
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color.AppTheme.primaryText)
                                    .padding(.trailing)
                            }
                            .background(Color.AppTheme.inputBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.AppTheme.brandMint.opacity(0.5), lineWidth: 1)
                            )
                            .cornerRadius(10)
                        }
                        .sheet(isPresented: $showScripturePicker) {
                            VStack {
                                Text("Select a Scripture")
                                    .font(.headline)
                                    .padding()
                                
                                List {
                                    ForEach(scriptures, id: \.self) { scripture in
                                        Button(action: {
                                            selectedScripture = scripture
                                            showScripturePicker = false
                                        }) {
                                            Text(scripture)
                                                .foregroundColor(selectedScripture == scripture ? .AppTheme.brandMint : .primary)
                                        }
                                    }
                                }
                                
                                Button("Cancel") {
                                    showScripturePicker = false
                                }
                                .padding()
                            }
                            .presentationDetents([.medium])
                        }
                    }
                    
                    // Generate Button
                    Button(action: {
                        generateBibleStudy()
                    }) {
                        Text("Generate Bible Study")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.AppTheme.brandMint)
                            .cornerRadius(10)
                    }
                    .padding(.vertical)
                    .disabled(isGenerating)
                    .overlay(
                        Group {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .AppTheme.brandMint))
                                    .scaleEffect(1.5)
                            }
                        }
                    )
                    
                    // Previous Bible Studies
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Previous Bible Studies")
                            .font(.headline)
                            .foregroundColor(Color.AppTheme.primaryText)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(previousStudies.indices, id: \.self) { index in
                                    BibleStudyCard(
                                        study: previousStudies[index],
                                        isPlaying: currentlyPlayingIndex == index && isPlaying,
                                        onPlay: {
                                            togglePlayback(for: index)
                                        }
                                    )
                                    .frame(width: 200, height: 180)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Bible Study")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadPreviousStudies()
            }
        }
    }
    
    // Function to generate a new Bible study
    private func generateBibleStudy() {
        isGenerating = true
        
        // Simulate API call with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Create a new Bible study entry
            let newStudy = BibleStudyEntry(
                id: UUID().uuidString,
                title: "Exploring the Depths of \(selectedTopic)",
                scripture: scriptures.randomElement() ?? "John 3:16",
                audioUrl: nil,
                duration: selectedDuration,
                createdAt: Date()
            )
            
            // Add to previous studies
            previousStudies.insert(newStudy, at: 0)
            
            // Save to UserDefaults
            savePreviousStudies()
            
            isGenerating = false
        }
    }
    
    // Function to toggle audio playback
    private func togglePlayback(for index: Int) {
        // If already playing this study, pause it
        if currentlyPlayingIndex == index && isPlaying {
            audioPlayer?.pause()
            isPlaying = false
            return
        }
        
        // If playing a different study, stop it
        audioPlayer?.stop()
        
        // Set the current study
        currentlyPlayingIndex = index
        
        // Simulate playing audio
        isPlaying = true
        
        // In a real app, you would load and play the audio file here
        // For now, we'll just simulate it with a timer
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if self.isPlaying && self.currentlyPlayingIndex == index {
                self.isPlaying = false
            }
        }
    }
    
    // Load previous studies from UserDefaults
    private func loadPreviousStudies() {
        if let data = UserDefaults.standard.data(forKey: "previousBibleStudies"),
           let decoded = try? JSONDecoder().decode([BibleStudyEntry].self, from: data) {
            previousStudies = decoded
        } else {
            // Add some sample studies if none exist
            previousStudies = [
                BibleStudyEntry(
                    id: "1",
                    title: "Exploring the Depths of Faith",
                    scripture: "John 15",
                    audioUrl: nil,
                    duration: "5-10 minutes",
                    createdAt: Date().addingTimeInterval(-86400)
                ),
                BibleStudyEntry(
                    id: "2",
                    title: "Exploring the Depths of Hope",
                    scripture: "John 14",
                    audioUrl: nil,
                    duration: "5-10 minutes",
                    createdAt: Date().addingTimeInterval(-172800)
                )
            ]
            savePreviousStudies()
        }
    }
    
    // Save previous studies to UserDefaults
    private func savePreviousStudies() {
        if let encoded = try? JSONEncoder().encode(previousStudies) {
            UserDefaults.standard.set(encoded, forKey: "previousBibleStudies")
        }
    }
}

// Bible Study Entry Model
struct BibleStudyEntry: Identifiable, Codable {
    let id: String
    let title: String
    let scripture: String
    let audioUrl: String?
    let duration: String
    let createdAt: Date
}

struct BibleStudyCard: View {
    let study: BibleStudyEntry
    let isPlaying: Bool
    let onPlay: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(study.title)
                .font(.headline)
                .foregroundColor(Color.AppTheme.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Text(study.scripture)
                .font(.subheadline)
                .foregroundColor(Color.AppTheme.secondaryText)
            
            HStack {
                Button(action: onPlay) {
                    ZStack {
                        Circle()
                            .fill(Color.AppTheme.brandMint.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .foregroundColor(Color.AppTheme.brandMint)
                    }
                }
                
                if isPlaying {
                    // Audio wave animation
                    BibleStudyAudioWaveView()
                }
            }
        }
        .padding()
        .background(Color.AppTheme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.AppTheme.brandMint.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(10)
    }
}

// Audio Wave Animation View
struct BibleStudyAudioWaveView: View {
    @State private var phase: CGFloat = 0
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5) { index in
                BibleStudyAudioBar(height: self.barHeight(index: index, phase: phase))
            }
        }
        .frame(height: 20)
        .onReceive(timer) { _ in
            withAnimation {
                phase += 0.1
                if phase > 2 * .pi {
                    phase = 0
                }
            }
        }
    }
    
    func barHeight(index: Int, phase: CGFloat) -> CGFloat {
        let height = sin(phase + CGFloat(index) * 0.5) * 0.5 + 0.5
        return height * 20
    }
}

struct BibleStudyAudioBar: View {
    let height: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.AppTheme.brandMint)
            .frame(width: 3, height: height)
    }
}

#Preview {
    BibleStudyView()
} 