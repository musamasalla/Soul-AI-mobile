import Foundation
import Combine
import AVFoundation
import UIKit

class PodcastViewModel: ObservableObject {
    @Published var podcasts: [PodcastEntry] = []
    @Published var isLoading: Bool = false
    @Published var selectedTestament: String = "Old Testament"
    @Published var selectedBook: String = ""
    @Published var selectedChapter: String = ""
    @Published var errorMessage: String? = nil
    
    @Published var isPlaying: Bool = false
    @Published var currentPodcastId: String? = nil
    
    @Published var selectedTopic: String = "Faith"
    @Published var scriptureReferences: String = ""
    @Published var podcastDuration: Int = 15
    @Published var podcast: Podcast?
    @Published var showPodcast: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var audioPlayer: AVPlayer?
    private var pollingTimer: Timer?
    private var pendingPodcastIds: Set<String> = []
    
    // Get available books based on selected testament
    var availableBooks: [BibleStructure.Book] {
        guard let testament = BibleStructure.structure.first(where: { $0.name == selectedTestament }) else {
            return []
        }
        return testament.books
    }
    
    // Get available chapters based on selected book
    var availableChapters: Int {
        guard let book = availableBooks.first(where: { $0.name == selectedBook }) else {
            return 0
        }
        return book.chapters
    }
    
    init() {
        loadPodcasts()
    }
    
    deinit {
        stopPolling()
    }
    
    func loadPodcasts() {
        isLoading = true
        errorMessage = nil
        
        SupabaseService.shared.fetchPodcasts()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                if case .failure(let error) = completion {
                    print("Error fetching podcasts: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load Bible studies. Please try again later."
                }
                
                self.isLoading = false
            }, receiveValue: { [weak self] podcasts in
                guard let self = self else { return }
                
                self.podcasts = podcasts
                
                // Check if there are any podcasts in generating status
                let generatingPodcasts = podcasts.filter { $0.status == .generating }
                if !generatingPodcasts.isEmpty {
                    // Add their IDs to pending list
                    for podcast in generatingPodcasts {
                        self.pendingPodcastIds.insert(podcast.id)
                    }
                    // Start polling if we have pending podcasts
                    self.startPolling()
                }
            })
            .store(in: &cancellables)
    }
    
    func generatePodcast() {
        isLoading = true
        errorMessage = nil
        
        // Create request body
        let requestBody: [String: Any] = [
            "topic": selectedTopic,
            "duration": 5 // Basic podcasts are fixed at 5 minutes
        ]
        
        SupabaseService.shared.generatePremiumPodcast(requestBody: requestBody)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                guard let self = self else { return }
                
                if case .failure(let error) = completion {
                    print("Error generating podcast: \(error.localizedDescription)")
                    self.errorMessage = "Failed to generate podcast. Please try again."
                    
                    // Use fallback content
                    self.podcast = Podcast(
                        title: "Podcast on \(self.selectedTopic)",
                        content: "Welcome to Soul AI. Today we're discussing \(self.selectedTopic) and how it relates to our Christian walk.",
                        duration: 5
                    )
                }
                
                self.isLoading = false
            }, receiveValue: { [weak self] (response: PodcastResponse) in
                guard let self = self else { return }
                
                // Clean up title but preserve formatting for content
                var title = response.title
                title = title.replacingOccurrences(of: "###", with: "")
                title = title.replacingOccurrences(of: "**", with: "")
                title = title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                // Create podcast object
                self.podcast = Podcast(
                    title: title,
                    content: response.content,
                    duration: response.duration > 0 ? response.duration : 5
                )
                
                self.showPodcast = true
            })
            .store(in: &cancellables)
    }
    
    // Generate premium podcast using a hybrid template system with Claude
    func generatePremiumPodcast() {
        guard UserPreferences().isSubscriptionActive else {
            errorMessage = "Premium subscription required for advanced podcasts."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Create request body with all premium options
        var requestBody: [String: Any] = [
            "topic": selectedTopic,
            "duration": podcastDuration,
            "isPremium": true
        ]
        
        // Add scripture references if provided
        if !scriptureReferences.isEmpty {
            requestBody["scriptureReferences"] = scriptureReferences
        }
        
        // DEVELOPMENT MODE: Use local mock instead of calling Supabase
        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            // Create a mock podcast based on user inputs
            let mockTitle = "The Christian Journey: \(self.selectedTopic)"
            
            var mockContent = "# Introduction (2 minutes)\n\nWelcome to \"The Christian Journey,\" where we explore faith in everyday life. I'm your host, and today we're diving into the topic of \(self.selectedTopic). "
            
            if !self.scriptureReferences.isEmpty {
                mockContent += "We'll be reflecting on \(self.scriptureReferences) and how these scriptures guide us in our understanding of \(self.selectedTopic).\n\n"
            } else {
                mockContent += "We'll be exploring what the Bible teaches us about \(self.selectedTopic) and how we can apply these teachings in our daily lives.\n\n"
            }
            
            mockContent += "# Main Content (\(Int(Double(self.podcastDuration) * 0.7)) minutes)\n\n"
            mockContent += "## Understanding \(self.selectedTopic) from a Biblical Perspective\n\n"
            mockContent += "When we think about \(self.selectedTopic) in the context of our faith, we must consider how God views this aspect of our lives. "
            mockContent += "The Bible provides us with guidance through various passages and stories that illuminate God's perspective on \(self.selectedTopic).\n\n"
            
            if !self.scriptureReferences.isEmpty {
                mockContent += "Looking at \(self.scriptureReferences), we can see that God values \(self.selectedTopic) as an essential part of our spiritual growth. "
                mockContent += "These verses remind us that our approach to \(self.selectedTopic) should be aligned with God's will and purpose for our lives.\n\n"
            } else {
                mockContent += "Throughout scripture, we see examples of how God values \(self.selectedTopic) as an essential part of our spiritual growth. "
                mockContent += "The Bible reminds us that our approach to \(self.selectedTopic) should be aligned with God's will and purpose for our lives.\n\n"
            }
            
            mockContent += "## Practical Application\n\n"
            mockContent += "How can we apply these biblical principles about \(self.selectedTopic) in our daily lives? First, we need to pray for guidance and wisdom. "
            mockContent += "Second, we should seek community and accountability with other believers. And third, we must be intentional about aligning our actions with our faith.\n\n"
            
            mockContent += "## Challenges and Growth\n\n"
            mockContent += "Of course, living out our faith in the area of \(self.selectedTopic) isn't always easy. We face challenges from cultural pressures, our own weaknesses, and spiritual warfare. "
            mockContent += "But these challenges are opportunities for growth and deeper reliance on God's strength rather than our own.\n\n"
            
            mockContent += "# Conclusion (\(Int(Double(self.podcastDuration) * 0.2)) minutes)\n\n"
            mockContent += "As we conclude our discussion on \(self.selectedTopic), I encourage you to reflect on how God is calling you to grow in this area. "
            mockContent += "Remember that spiritual growth is a journey, not a destination. Each step we take in faith brings us closer to becoming who God created us to be.\n\n"
            mockContent += "Thank you for joining me today on \"The Christian Journey.\" Until next time, may God bless you and keep you in His perfect peace."
            
            self.podcast = Podcast(
                title: mockTitle,
                content: mockContent,
                duration: self.podcastDuration
            )
            
            self.isLoading = false
            self.showPodcast = true
        }
        #else
        // Original code for production
        SupabaseService.shared.generatePremiumPodcast(requestBody: requestBody)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] (completion: Subscribers.Completion<Error>) in
                guard let self = self else { return }
                
                if case .failure(let error) = completion {
                    print("Error generating premium podcast: \(error.localizedDescription)")
                    self.errorMessage = "Failed to generate podcast. Please try again."
                    
                    // Use fallback content
                    self.podcast = Podcast(
                        title: "Premium Podcast on \(self.selectedTopic)",
                        content: "Welcome to Soul AI Premium. Today we're discussing \(self.selectedTopic) and how it relates to our Christian walk.",
                        duration: self.podcastDuration
                    )
                }
                
                self.isLoading = false
            }, receiveValue: { [weak self] (podcast: PodcastResponse) in
                guard let self = self else { return }
                
                // Clean up title but preserve formatting for content
                var title = podcast.title
                title = title.replacingOccurrences(of: "###", with: "")
                title = title.replacingOccurrences(of: "**", with: "")
                title = title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                self.podcast = Podcast(
                    title: title,
                    content: podcast.content,
                    duration: podcast.duration > 0 ? podcast.duration : 5
                )
                
                self.showPodcast = true
            })
            .store(in: &cancellables)
        #endif
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
        SupabaseService.shared.fetchPodcasts()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Error checking pending podcasts: \(error.localizedDescription)")
                    // Don't stop polling on error, we'll try again
                }
            }, receiveValue: { [weak self] podcasts in
                guard let self = self else { return }
                
                // Update our podcast list
                self.podcasts = podcasts
                
                // Check if any pending podcasts are now complete
                var stillPending = false
                var completedIds = Set<String>()
                
                for id in self.pendingPodcastIds {
                    if let podcast = podcasts.first(where: { $0.id == id }) {
                        if podcast.status == .ready || podcast.status == .failed {
                            // This podcast is no longer pending
                            completedIds.insert(id)
                        } else {
                            // Still pending
                            stillPending = true
                        }
                    } else {
                        // Podcast not found, mark for removal
                        completedIds.insert(id)
                    }
                }
                
                // Remove completed podcasts from pending set
                for id in completedIds {
                    self.pendingPodcastIds.remove(id)
                }
                
                // If no podcasts are still pending, stop polling
                if !stillPending {
                    self.stopPolling()
                }
            })
            .store(in: &cancellables)
    }
    
    func getRandomSelection() {
        let randomTestamentIndex = Int.random(in: 0..<BibleStructure.structure.count)
        let testament = BibleStructure.structure[randomTestamentIndex]
        
        let randomBookIndex = Int.random(in: 0..<testament.books.count)
        let book = testament.books[randomBookIndex]
        
        let randomChapter = Int.random(in: 1...book.chapters)
        
        selectedTestament = testament.name
        selectedBook = book.name
        selectedChapter = "\(randomChapter)"
    }
    
    func playPodcast(podcast: PodcastEntry) {
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
        stopPolling()
    }
} 