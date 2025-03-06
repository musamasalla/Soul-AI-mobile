import SwiftUI

struct PremiumPodcastView: View {
    @StateObject private var viewModel = PremiumPodcastViewModel()
    @State private var showingVoiceSelector = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.AppTheme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with usage info
                    usageInfoHeader
                    
                    // Podcast generation form
                    podcastGenerationForm
                    
                    // List of podcasts
                    podcastList
                }
                .padding(.horizontal)
            }
            .navigationTitle("Premium Podcasts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.fetchPodcasts()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.AppTheme.primaryText)
                    }
                }
            }
            .alert(item: Binding<AlertItem?>(
                get: { viewModel.errorMessage.map { AlertItem(message: $0) } },
                set: { _ in viewModel.errorMessage = nil }
            )) { alertItem in
                Alert(
                    title: Text("Error"),
                    message: Text(alertItem.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingVoiceSelector) {
                voiceSelectorView
            }
        }
    }
    
    // Usage info header
    private var usageInfoHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Monthly Character Usage")
                    .font(.headline)
                    .foregroundColor(.AppTheme.primaryText)
                
                Spacer()
                
                Text("\(viewModel.remainingMinutes) min remaining")
                    .font(.subheadline)
                    .foregroundColor(.AppTheme.brandMint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.AppTheme.brandMint.opacity(0.1))
                    .cornerRadius(8)
            }
            
            HStack {
                Text("\(viewModel.remainingCharacters) / 45,000 characters")
                    .font(.subheadline)
                    .foregroundColor(.AppTheme.secondaryText)
                
                Spacer()
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 8)
                        .opacity(0.3)
                        .foregroundColor(Color.AppTheme.inputBackground)
                    
                    Rectangle()
                        .frame(width: min(CGFloat(viewModel.remainingCharacters) / 45000.0 * geometry.size.width, geometry.size.width), height: 8)
                        .foregroundColor(Color.AppTheme.brandMint)
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
            .padding(.bottom, 8)
        }
        .padding()
        .background(Color.AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.top)
    }
    
    // Podcast generation form
    private var podcastGenerationForm: some View {
        VStack(spacing: 16) {
            // Topic selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Topic")
                    .font(.headline)
                    .foregroundColor(.AppTheme.primaryText)
                
                Picker("Select a topic", selection: $viewModel.selectedTopic) {
                    ForEach(PremiumPodcastTopics.topics, id: \.self) { topic in
                        Text(topic).tag(topic)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(8)
                .background(Color.AppTheme.inputBackground)
                .cornerRadius(8)
            }
            
            // Duration selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration (minutes)")
                    .font(.headline)
                    .foregroundColor(.AppTheme.primaryText)
                
                Picker("Select duration", selection: $viewModel.selectedDuration) {
                    ForEach(viewModel.availableDurations, id: \.self) { duration in
                        Text("\(duration) min").tag(duration)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .accentColor(Color.AppTheme.brandMint)
            }
            
            // Voice selection
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Voices (\(viewModel.selectedVoices.count) selected)")
                        .font(.headline)
                        .foregroundColor(.AppTheme.primaryText)
                    
                    Spacer()
                    
                    Button(action: {
                        showingVoiceSelector = true
                    }) {
                        Text("Select")
                            .font(.subheadline)
                            .foregroundColor(Color.AppTheme.brandMint)
                    }
                }
                
                // Show selected voices
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.selectedVoices) { voice in
                            Text(voice.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.AppTheme.brandMint.opacity(0.2))
                                .foregroundColor(Color.AppTheme.brandMint)
                                .cornerRadius(12)
                        }
                    }
                }
            }
            
            // Generate button
            Button(action: {
                Task {
                    await viewModel.generatePodcast()
                }
            }) {
                HStack {
                    Spacer()
                    if viewModel.isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                            .padding(.trailing, 5)
                    }
                    Text("Generate Podcast")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .background(viewModel.canGeneratePodcast ? Color.AppTheme.brandMint : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!viewModel.canGeneratePodcast || viewModel.isGenerating)
            .opacity(viewModel.canGeneratePodcast ? 1.0 : 0.7)
            .shadow(color: viewModel.canGeneratePodcast ? Color.AppTheme.brandMint.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 2)
        }
        .padding()
        .background(Color.AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.vertical)
    }
    
    // List of podcasts
    private var podcastList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading && viewModel.podcasts.isEmpty {
                    ProgressView()
                        .padding()
                } else if viewModel.podcasts.isEmpty {
                    Text("No podcasts yet. Generate your first premium podcast!")
                        .foregroundColor(.AppTheme.secondaryText)
                        .padding()
                } else {
                    ForEach(viewModel.podcasts) { podcast in
                        PremiumPodcastCard(
                            podcast: podcast,
                            isPlaying: viewModel.isPlaying && viewModel.currentPodcastId == podcast.id,
                            onPlay: {
                                viewModel.playPodcast(podcast: podcast)
                            }
                        )
                    }
                }
            }
            .padding(.bottom, 16)
        }
    }
    
    // Voice selector view
    private var voiceSelectorView: some View {
        NavigationView {
            List {
                ForEach(PodcastVoice.allCases) { voice in
                    Button(action: {
                        toggleVoice(voice)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(voice.displayName)
                                    .font(.headline)
                                
                                Text(voice.description)
                                    .font(.caption)
                                    .foregroundColor(.AppTheme.secondaryText)
                            }
                            
                            Spacer()
                            
                            if viewModel.selectedVoices.contains(voice) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.AppTheme.brandMint)
                                    .font(.title3)
                            } else {
                                Circle()
                                    .strokeBorder(Color.AppTheme.secondaryText.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .foregroundColor(.AppTheme.primaryText)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Select Voices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingVoiceSelector = false
                    }
                    .foregroundColor(Color.AppTheme.brandMint)
                }
            }
        }
    }
    
    // Toggle voice selection
    private func toggleVoice(_ voice: PodcastVoice) {
        if viewModel.selectedVoices.contains(voice) {
            // Don't allow deselecting if we would have less than 2 voices
            if viewModel.selectedVoices.count > 2 {
                viewModel.selectedVoices.removeAll { $0 == voice }
            }
        } else {
            // Add the voice
            viewModel.selectedVoices.append(voice)
        }
    }
}

// Premium podcast card
struct PremiumPodcastCard: View {
    let podcast: PremiumPodcast
    let isPlaying: Bool
    let onPlay: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and duration
            HStack {
                Text(podcast.title)
                    .font(.headline)
                    .foregroundColor(.AppTheme.primaryText)
                    .lineLimit(2)
                
                Spacer()
                
                Text("\(podcast.duration) min")
                    .font(.caption)
                    .foregroundColor(.AppTheme.secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.AppTheme.inputBackground)
                    .cornerRadius(12)
            }
            
            // Description
            Text(podcast.description)
                .font(.subheadline)
                .foregroundColor(.AppTheme.secondaryText)
                .lineLimit(3)
            
            // Status and play button
            HStack {
                if podcast.status == .generating {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        
                        Text("Generating...")
                            .font(.caption)
                            .foregroundColor(.AppTheme.secondaryText)
                    }
                } else if podcast.status == .failed {
                    Text("Generation failed")
                        .font(.caption)
                        .foregroundColor(Color.AppTheme.brandPurple)
                } else {
                    Text("Topic: \(podcast.topic)")
                        .font(.caption)
                        .foregroundColor(.AppTheme.secondaryText)
                }
                
                Spacer()
                
                if podcast.status == .ready {
                    Button(action: onPlay) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title)
                            .foregroundColor(Color.AppTheme.brandMint)
                    }
                }
            }
        }
        .padding()
        .background(Color.AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.AppTheme.brandMint.opacity(0.1), lineWidth: 1)
        )
    }
}

// Helper for alerts
struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

struct PremiumPodcastView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumPodcastView()
    }
}