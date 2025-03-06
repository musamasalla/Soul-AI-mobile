import Foundation
import Combine
import AVFoundation

class PremiumPodcastViewModel: ObservableObject {
    @Published var podcasts: [PremiumPodcast] = []
    @Published var isLoading: Bool = false
    @Published var selectedTopic: String = PremiumPodcastTopics.topics.first ?? "Faith and Spirituality"
    @Published var selectedDuration: Int = 15 // Default 15 minutes
    @Published var selectedVoices: [PodcastVoice] = [.alloy, .echo] // Default 2 voices
    @Published var errorMessage: String? = nil
    @Published var error: PremiumPodcastError? = nil
    
    @Published var isPlaying: Bool = false
    @Published var currentPodcastId: String? = nil
    @Published var isGenerating: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var audioPlayer: AVPlayer?
    private var pollingTimer: Timer?
    private var pendingPodcastIds: Set<String> = []
    
    // Available durations in minutes
    let availableDurations = [5, 10, 15, 30, 45, 60]
    
    // User preferences for character usage tracking
    private let preferences = UserPreferences()
    
    // Error types
    enum PremiumPodcastError: Error {
        case emptyTopic
        case insufficientVoices
        case exceedsCharacterLimit
        case serverError
    }
    
    // MARK: - Initialization
    
    init() {
        loadPremiumPodcasts()
    }
    
    deinit {
        stopPolling()
    }
    
    // MARK: - Computed Properties
    
    // Calculate character limit based on duration
    var characterLimit: Int {
        return selectedDuration * 750
    }
    
    // MARK: - Public Methods
    
    // Validate inputs before generating podcast
    func validateInputs() -> Bool {
        // Check if topic is empty
        if selectedTopic.isEmpty {
            error = .emptyTopic
            return false
        }
        
        // Check if we have at least 2 voices
        if selectedVoices.count < 2 {
            error = .insufficientVoices
            return false
        }
        
        // Check if user has enough characters
        if !preferences.hasEnoughCharactersFor(duration: selectedDuration) {
            error = .exceedsCharacterLimit
            return false
        }
        
        error = nil
        return true
    }
    
    // Generate podcast
    func generatePodcast() async {
        guard validateInputs() else {
            return
        }
        
        isGenerating = true
        
        // Convert voice enums to strings
        let voiceStrings = selectedVoices.map { $0.rawValue }
        
        let result = await SupabaseService.shared.generatePremiumPodcast(
            topic: selectedTopic,
            duration: selectedDuration,
            voices: voiceStrings
        )
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isGenerating = false
            
            switch result {
            case .success(let podcast):
                // Add the new podcast to the list
                self.podcasts.insert(podcast, at: 0)
                
                // Add the character usage to the user's total
                self.preferences.addCharacterUsage(podcast.characterCount)
                
                // If the podcast is still generating, add it to pending list and start polling
                if podcast.status == .generating {
                    self.pendingPodcastIds.insert(podcast.id)
                    self.startPolling()
                }
                
            case .failure:
                self.error = .serverError
            }
        }
    }
    
    // Fetch podcasts
    func fetchPodcasts() async {
        isLoading = true
        error = nil
        
        let result = await SupabaseService.shared.fetchPremiumPodcasts()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let podcasts):
                self.podcasts = podcasts
                
                // Check for pending podcasts
                let generatingPodcasts = podcasts.filter { $0.status == .generating }
                if !generatingPodcasts.isEmpty {
                    for podcast in generatingPodcasts {
                        self.pendingPodcastIds.insert(podcast.id)
                    }
                    self.startPolling()
                }
                
            case .failure:
                self.error = .serverError
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadPremiumPodcasts() {
        Task {
            await fetchPodcasts()
        }
    }
    
    // Start polling for updates to pending podcasts
    private func startPolling() {
        // Stop any existing polling
        stopPolling()
        
        // Only start polling if we have pending podcasts
        guard !pendingPodcastIds.isEmpty else { return }
        
        // Create a timer that polls every 5 seconds
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkPendingPodcasts()
        }
    }
    
    // Stop polling
    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
    
    // Check for updates to pending podcasts
    private func checkPendingPodcasts() {
        guard !pendingPodcastIds.isEmpty else {
            stopPolling()
            return
        }
        
        // Fetch the latest podcast data
        Task {
            await fetchPodcasts()
        }
    }
    
    func playPodcast(podcast: PremiumPodcast) {
        guard let audioUrl = podcast.audioUrl else {
            return
        }
        
        // Fix double slash issue in URL
        let fixedAudioUrl = audioUrl.replacingOccurrences(of: "podcasts//", with: "podcasts/")
        
        guard let url = URL(string: fixedAudioUrl) else {
            return
        }
        
        // If we're already playing this podcast, pause it
        if currentPodcastId == podcast.id && isPlaying {
            audioPlayer?.pause()
            isPlaying = false
            return
        }
        
        // If we're playing a different podcast, stop it
        if currentPodcastId != podcast.id {
            audioPlayer?.pause()
            audioPlayer = AVPlayer(url: url)
        }
        
        // Start playing
        audioPlayer?.play()
        isPlaying = true
        currentPodcastId = podcast.id
    }
    
    func stopPlayback() {
        audioPlayer?.pause()
        isPlaying = false
    }
    
    // Get the remaining character count for the user
    var remainingCharacters: Int {
        return preferences.remainingCharacters
    }
    
    // Get the remaining minutes the user can generate
    var remainingMinutes: Int {
        return preferences.remainingPodcastMinutes
    }
    
    // Check if the user can generate a podcast of the selected duration
    var canGeneratePodcast: Bool {
        return preferences.hasEnoughCharactersFor(duration: selectedDuration)
    }
} 