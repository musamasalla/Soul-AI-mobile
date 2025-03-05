import SwiftUI

struct PremiumPodcastView: View {
    @StateObject private var viewModel = PodcastViewModel()
    @State private var selectedTab = 0
    
    // Available topics
    private let topics = ["Faith", "Hope", "Love", "Peace", "Joy", "Wisdom", "Forgiveness", "Prayer", "Gratitude", "Purpose"]
    
    // Available durations
    private let durations = [10, 15, 20, 30, 45, 60]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("Premium AI Podcast")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.brandMint)
                    .padding(.horizontal)
                
                Text("Create long-form Christian podcasts powered by advanced AI")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Topic selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select a topic:")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(topics, id: \.self) { topic in
                                Button(action: {
                                    viewModel.selectedTopic = topic
                                }) {
                                    Text(topic)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(
                                            viewModel.selectedTopic == topic ?
                                            Color.brandMint :
                                            Color.gray.opacity(0.2)
                                        )
                                        .foregroundColor(
                                            viewModel.selectedTopic == topic ?
                                            .white :
                                            .primary
                                        )
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Scripture reference
                VStack(alignment: .leading, spacing: 8) {
                    Text("Specific scripture (optional):")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    TextField("e.g., John 3:16, Romans 8:28", text: $viewModel.scriptureReferences)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                // Duration selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Podcast duration:")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Picker("Duration", selection: $viewModel.podcastDuration) {
                        ForEach(durations, id: \.self) { duration in
                            Text("\(duration) minutes").tag(duration)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                }
                
                // Generate button
                Button(action: {
                    viewModel.generatePremiumPodcast()
                }) {
                    HStack {
                        Text("Generate Premium Podcast")
                            .font(.headline)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.leading, 5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brandMint)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .disabled(viewModel.isLoading)
                .opacity(viewModel.isLoading ? 0.7 : 1.0)
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Display podcast content if available
                if let podcast = viewModel.podcast {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(podcast.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.brandMint)
                            .padding(.horizontal)
                        
                        Text("Duration: \(podcast.duration) minutes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Text(podcast.content)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        
                        // Share button
                        Button(action: {
                            let textToShare = "\(podcast.title)\n\n\(podcast.content)"
                            let activityVC = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
                            
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootViewController = windowScene.windows.first?.rootViewController {
                                rootViewController.present(activityVC, animated: true, completion: nil)
                            }
                        }) {
                            Label("Share Podcast", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Premium Podcast")
        .onAppear {
            // Check subscription status
            if !UserPreferences().isSubscriptionActive {
                viewModel.errorMessage = "Premium subscription required for this feature."
            }
        }
    }
}

struct PremiumPodcastView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PremiumPodcastView()
        }
    }
} 