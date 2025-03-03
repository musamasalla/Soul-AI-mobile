import SwiftUI
import Combine

struct MeditationView: View {
    @State private var selectedTopic: String = "Peace"
    @State private var meditationTitle: String = ""
    @State private var meditationContent: String = ""
    @State private var meditationDuration: Int = 0
    @State private var isLoading: Bool = false
    @State private var isPlaying: Bool = false
    @State private var progress: Float = 0.0
    @State private var timer: Timer?
    
    private var topics = ["Peace", "Faith", "Hope", "Love", "Forgiveness", "Gratitude", "Wisdom"]
    private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ZStack {
            // Background
            Color.brandBackground
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                Text("Christian Meditation")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.brandMint)
                    .padding(.top, 20)
                
                // Topic selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select a topic:")
                        .font(.headline)
                        .foregroundColor(.brandMint)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(topics, id: \.self) { topic in
                                Button(action: {
                                    selectedTopic = topic
                                }) {
                                    Text(topic)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(selectedTopic == topic ? Color.brandMint : Color(.systemGray6).opacity(0.3))
                                        .foregroundColor(selectedTopic == topic ? .black : .white)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 5)
                    }
                }
                .padding(.horizontal)
                
                // Generate button
                Button(action: {
                    generateMeditation()
                }) {
                    HStack {
                        Text("Generate Meditation")
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(0.8)
                        }
                    }
                    .foregroundColor(.black)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 30)
                    .background(Color.brandMint)
                    .cornerRadius(10)
                }
                .disabled(isLoading || isPlaying)
                .opacity((isLoading || isPlaying) ? 0.5 : 1.0)
                
                // Meditation content
                if !meditationTitle.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            Text(meditationTitle)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.brandMint)
                                .padding(.bottom, 5)
                            
                            Text(meditationContent)
                                .font(.body)
                                .foregroundColor(.white)
                                .lineSpacing(8)
                            
                            Text("Duration: \(meditationDuration) minutes")
                                .font(.subheadline)
                                .foregroundColor(.brandMint.opacity(0.8))
                                .padding(.top, 10)
                        }
                        .padding()
                        .background(Color(.systemGray6).opacity(0.2))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.brandMint.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    
                    // Player controls
                    VStack(spacing: 15) {
                        // Progress bar
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .brandMint))
                            .padding(.horizontal)
                        
                        // Play/Pause button
                        Button(action: {
                            togglePlayPause()
                        }) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.brandMint)
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func generateMeditation() {
        isLoading = true
        
        SupabaseService.shared.generateMeditation(topic: selectedTopic)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error generating meditation: \(error.localizedDescription)")
                    // Use fallback content
                    meditationTitle = "Meditation on \(selectedTopic)"
                    meditationContent = "Take a deep breath and reflect on God's love. Remember that in all things, God works for the good of those who love him."
                    meditationDuration = 5
                }
                isLoading = false
            }, receiveValue: { response in
                meditationTitle = response.title
                meditationContent = response.content
                meditationDuration = response.duration
                progress = 0.0
                isPlaying = false
                timer?.invalidate()
                timer = nil
            })
            .store(in: &cancellables)
    }
    
    private func togglePlayPause() {
        isPlaying.toggle()
        
        if isPlaying {
            // Start the timer
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                let totalSeconds = Float(meditationDuration * 60)
                progress += 1.0 / totalSeconds
                
                if progress >= 1.0 {
                    isPlaying = false
                    timer?.invalidate()
                    timer = nil
                    progress = 1.0
                }
            }
        } else {
            // Pause the timer
            timer?.invalidate()
        }
    }
}

#Preview {
    MeditationView()
} 