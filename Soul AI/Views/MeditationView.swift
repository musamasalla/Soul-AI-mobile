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
    @State private var showCopyConfirmation: Bool = false
    
    private var topics = ["Peace", "Faith", "Hope", "Love", "Forgiveness", "Gratitude", "Wisdom"]
    
    var body: some View {
        ZStack {
            // Background
            Color.brandBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Christian Meditation")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.brandMint)
                        .padding(.top, 20)
                    
                    // Input Section
                    VStack(spacing: 20) {
                        // Mood input
                        VStack(alignment: .leading, spacing: 10) {
                            Text("How are you feeling today?")
                                .font(.headline)
                                .foregroundColor(.brandMint)
                            
                            TextEditor(text: $viewModel.moodText)
                                .frame(height: 100)
                                .padding(12)
                                .background(Color(.systemGray6).opacity(0.3))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.brandMint.opacity(0.5), lineWidth: 1)
                                )
                                .font(.body)
                        }
                        .padding(.horizontal)
                        
                        // Energy level slider
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Energy Level: \(Int(viewModel.energyLevel))/10")
                                .font(.subheadline)
                                .foregroundColor(.brandMint)
                            
                            Slider(value: $viewModel.energyLevel, in: 1...10, step: 1)
                                .accentColor(.brandMint)
                        }
                        .padding(.horizontal)
                        
                        // Stress level slider
                        VStack(alignment: .leading, spacing: 8) {
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
                                    .fontWeight(.semibold)
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                        .scaleEffect(0.8)
                                }
                            }
                            .foregroundColor(.black)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 30)
                            .background(Color.brandMint)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                        .disabled(viewModel.isLoading || isPlaying)
                        .opacity((viewModel.isLoading || isPlaying) ? 0.5 : 1.0)
                        .padding(.top, 8)
                    }
                    
                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 5)
                    }
                    
                    // Meditation content
                    if !viewModel.meditationTitle.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            // Title and copy button
                            HStack {
                                Text(viewModel.meditationTitle)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.brandMint)
                                
                                Spacer()
                                
                                Button(action: {
                                    UIPasteboard.general.string = viewModel.meditationContent
                                    showCopyConfirmation = true
                                    
                                    // Hide confirmation after 2 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showCopyConfirmation = false
                                    }
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.brandMint)
                                        .padding(8)
                                        .background(Color.brandMint.opacity(0.2))
                                        .clipShape(Circle())
                                }
                                .overlay(
                                    Group {
                                        if showCopyConfirmation {
                                            Text("Copied!")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                                .padding(6)
                                                .background(Color.brandMint)
                                                .cornerRadius(4)
                                                .offset(y: 30)
                                                .transition(.opacity)
                                        }
                                    }
                                )
                            }
                            .padding(.bottom, 5)
                            
                            // Paragraphs
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(viewModel.meditationParagraphs.indices, id: \.self) { index in
                                    ParagraphCard(text: viewModel.meditationParagraphs[index], index: index)
                                }
                            }
                            
                            // Duration
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.brandMint)
                                
                                Text("Duration: \(viewModel.meditationDuration) minutes")
                                    .font(.subheadline)
                                    .foregroundColor(.brandMint.opacity(0.9))
                            }
                            .padding(.top, 10)
                        }
                        .padding()
                        .background(Color(.systemGray6).opacity(0.15))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.brandMint.opacity(0.4), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        // Player controls
                        VStack(spacing: 15) {
                            // Progress bar
                            HStack {
                                Text(formatTime(seconds: Int(progress * Float(viewModel.meditationDuration * 60))))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                ProgressView(value: progress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: .brandMint))
                                
                                Text(formatTime(seconds: viewModel.meditationDuration * 60))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            
                            // Play/Pause button
                            Button(action: {
                                togglePlayPause()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.brandMint.opacity(0.2))
                                        .frame(width: 70, height: 70)
                                    
                                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.brandMint)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.bottom, 20)
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
    
    private func formatTime(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// Custom paragraph card component
struct ParagraphCard: View {
    let text: String
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .font(.body)
                .foregroundColor(.white)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.brandMint.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.brandMint.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    MeditationView()
} 