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
    @Published var podcastDuration: Int = 15  // Restore default to 15 minutes for premium podcasts
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
        // Note: The backend expects a bibleChapter parameter, but our UI now uses topics.
        // We're passing the selected topic as the bibleChapter to maintain compatibility
        // with the backend while using the new topic-based UI.
        var requestBody: [String: Any] = [
            "bibleChapter": selectedTopic, // Using topic as the Bible study subject
            "initialRequest": true
        ]
        
        // Add scripture references if provided (for premium users)
        if !scriptureReferences.isEmpty {
            requestBody["scriptureReferences"] = scriptureReferences
        }
        
        SupabaseService.shared.generateBibleStudy(bibleChapter: selectedTopic, scriptureReferences: scriptureReferences)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                if case .failure(let error) = completion {
                    print("Error generating podcast: \(error.localizedDescription)")
                    self.errorMessage = "Failed to generate Bible study. Please try again."
                }
                
                self.isLoading = false
            }, receiveValue: { [weak self] podcastEntry in
                guard let self = self else { return }
                
                // Add the new podcast to our list
                self.podcasts.insert(podcastEntry, at: 0)
                
                // If the podcast is still generating, add it to pending list and start polling
                if podcastEntry.status == .generating {
                    self.pendingPodcastIds.insert(podcastEntry.id)
                    self.startPolling()
                }
                
                self.isLoading = false
            })
            .store(in: &cancellables)
    }
    
    // Generate premium podcast using a hybrid template system with Claude
    func generatePremiumPodcast(isLongForm: Bool = false) {
        guard UserPreferences().isSubscriptionActive else {
            errorMessage = "Premium subscription required for advanced content."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Set scripture references based on selected testament/book/chapter if not already set
        if scriptureReferences.isEmpty && !selectedBook.isEmpty && !selectedChapter.isEmpty {
            scriptureReferences = "\(selectedBook) \(selectedChapter)"
        }
        
        if isLongForm {
            // Use the long-form podcast edge function
            generateLongFormPodcast()
        } else {
            // For premium Bible studies, use the same function as free Bible studies
            // but include scripture references
            generatePodcast()
        }
    }
    
    // Generate long-form podcast using NotebookLM (separate edge function)
    private func generateLongFormPodcast() {
        // Create request body for long-form podcast
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
            
            var mockContent = "# Introduction (\(Int(Double(self.podcastDuration) * 0.2)) minutes)\n\nWelcome to \"The Christian Journey,\" where we explore faith in everyday life. I'm your host, and today we're diving into the topic of \(self.selectedTopic). "
            
            if !self.scriptureReferences.isEmpty {
                mockContent += "We'll be reflecting on \(self.scriptureReferences) and how these scriptures guide us in our understanding of \(self.selectedTopic).\n\n"
            } else {
                mockContent += "We'll be exploring what the Bible teaches us about \(self.selectedTopic) and how we can apply these teachings in our daily lives.\n\n"
            }
            
            mockContent += "# Main Content (\(Int(Double(self.podcastDuration) * 0.6)) minutes)\n\n"
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
            
            mockContent += "## Historical Context and Theological Significance\n\n"
            mockContent += "Throughout church history, Christian thinkers and theologians have reflected deeply on \(self.selectedTopic). "
            mockContent += "From Augustine to C.S. Lewis, we see a rich tradition of wrestling with what it means to understand \(self.selectedTopic) through the lens of faith. "
            mockContent += "This historical perspective helps us see that our own questions and struggles with \(self.selectedTopic) are part of a long conversation within the Christian tradition.\n\n"
            
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
        SupabaseService.shared.generateLongFormPodcast(requestBody: requestBody)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                if case .failure(let error) = completion {
                    print("Error generating long-form podcast: \(error.localizedDescription)")
                    self.errorMessage = "Failed to generate long-form podcast. Please try again."
                    
                    // Use fallback content
                    self.podcast = Podcast(
                        title: "Premium Podcast on \(self.selectedTopic)",
                        content: "Welcome to Soul AI Premium. Today we're discussing \(self.selectedTopic) and how it relates to our Christian walk.",
                        duration: self.podcastDuration
                    )
                }
                
                self.isLoading = false
            }, receiveValue: { [weak self] podcast in
                guard let self = self else { return }
                
                // Clean up title but preserve formatting for content
                var title = podcast.title
                title = title.replacingOccurrences(of: "###", with: "")
                title = title.replacingOccurrences(of: "**", with: "")
                title = title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                self.podcast = Podcast(
                    title: title,
                    content: podcast.content,
                    duration: podcast.duration > 0 ? podcast.duration : self.podcastDuration
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