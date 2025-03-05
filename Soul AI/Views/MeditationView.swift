import SwiftUI
import Combine

// Add a class to hold cancellables
private class CancellableHolder: ObservableObject {
    var cancellables = Set<AnyCancellable>()
}

struct MeditationView: View {
    @StateObject private var viewModel = MeditationViewModel()
    @State private var isPlaying: Bool = false
    @State private var progress: Float = 0.0
    @State private var timer: Timer?
    
    private var topics = ["Peace", "Faith", "Hope", "Love", "Forgiveness", "Gratitude", "Wisdom"]
    
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
                
                // Mood input
                VStack(alignment: .leading, spacing: 10) {
                    Text("How are you feeling today?")
                        .font(.headline)
                        .foregroundColor(.brandMint)
                    
                    TextEditor(text: $viewModel.moodText)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6).opacity(0.3))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.brandMint.opacity(0.5), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                
                // Energy level slider
                VStack(alignment: .leading, spacing: 5) {
                    Text("Energy Level: \(Int(viewModel.energyLevel))/10")
                        .font(.subheadline)
                        .foregroundColor(.brandMint)
                    
                    Slider(value: $viewModel.energyLevel, in: 1...10, step: 1)
                        .accentColor(.brandMint)
                }
                .padding(.horizontal)
                
                // Stress level slider
                VStack(alignment: .leading, spacing: 5) {
                    Text("Stress Level: \(Int(viewModel.stressLevel))/10")
                        .font(.subheadline)
                        .foregroundColor(.brandMint)
                    
                    Slider(value: $viewModel.stressLevel, in: 1...10, step: 1)
                        .accentColor(.brandMint)
                }
                .padding(.horizontal)
                
                // Generate button
                Button(action: {
                    viewModel.generateMeditation()
                }) {
                    HStack {
                        Text("Generate Meditation")
                        if viewModel.isLoading {
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
                .disabled(viewModel.isLoading || isPlaying)
                .opacity((viewModel.isLoading || isPlaying) ? 0.5 : 1.0)
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 5)
                }
                
                // Meditation content
                if !viewModel.meditationTitle.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            Text(viewModel.meditationTitle)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.brandMint)
                                .padding(.bottom, 5)
                            
                            ForEach(viewModel.meditationParagraphs.indices, id: \.self) { index in
                                Text(viewModel.meditationParagraphs[index])
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .lineSpacing(8)
                                    .padding(.bottom, 5)
                            }
                            
                            Text("Duration: \(viewModel.meditationDuration) minutes")
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
    
    private func togglePlayPause() {
        isPlaying.toggle()
        
        if isPlaying {
            // Start the timer
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                let totalSeconds = Float(viewModel.meditationDuration * 60)
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