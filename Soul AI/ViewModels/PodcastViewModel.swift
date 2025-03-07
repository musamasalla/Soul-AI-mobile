import Foundation
import Combine
import AVFoundation

class PodcastViewModel: ObservableObject {
    @Published var podcasts: [PodcastEntry] = []
    @Published var isLoading: Bool = false
    @Published var selectedTestament: String = "Old Testament"
    @Published var selectedBook: String = ""
    @Published var selectedChapter: String = ""
    @Published var errorMessage: String? = nil
    
    @Published var isPlaying: Bool = false
    @Published var currentPodcastId: String? = nil
    
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
        
        // Since fetchPodcasts is no longer available, we'll use a direct HTTP request
        guard let url = URL(string: "\(SupabaseConfig.supabaseUrl)/rest/v1/podcasts?select=*&order=created_at.desc") else {
            self.errorMessage = "Invalid URL configuration."
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add headers
        for (key, value) in SupabaseConfig.headers() {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Add additional headers for Supabase REST API
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Error fetching podcasts: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load Bible studies. Please try again later."
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    decoder.dateDecodingStrategy = .formatted(dateFormatter)
                    
                    let podcasts = try decoder.decode([PodcastEntry].self, from: data)
                    self.podcasts = podcasts
                    
                    // Check if there are any podcasts in generating status
                    let generatingPodcasts = podcasts.filter { $0.status == PodcastStatus.generating }
                    if !generatingPodcasts.isEmpty {
                        // Add their IDs to pending list
                        for podcast in generatingPodcasts {
                            self.pendingPodcastIds.insert(podcast.id)
                        }
                        // Start polling if we have pending podcasts
                        self.startPolling()
                    }
                } catch {
                    print("Error decoding podcasts: \(error.localizedDescription)")
                    self.errorMessage = "Failed to decode podcast data. Please try again later."
                }
            }
        }.resume()
    }
    
    func generatePodcast() {
        guard !selectedBook.isEmpty, !selectedChapter.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        let bibleChapter = "\(selectedBook) \(selectedChapter)"
        
        // Create a temporary podcast entry to show in the UI while generating
        let tempId = UUID().uuidString
        let tempPodcast = PodcastEntry(
            id: tempId,
            title: "Generating Bible Study for \(bibleChapter)...",
            description: "Please wait while we create your Bible study...",
            chapter: bibleChapter,
            audioUrl: nil,
            status: PodcastStatus.generating,
            createdAt: Date()
        )
        
        // Add the temporary podcast to the list
        self.podcasts.insert(tempPodcast, at: 0)
        
        // Since generateBibleStudy is no longer available, we'll use a direct HTTP request
        guard let url = URL(string: SupabaseConfig.podcastEndpoint) else {
            self.errorMessage = "Invalid URL configuration."
            self.isLoading = false
            
            // Remove the temporary podcast
            self.podcasts.removeAll { $0.id == tempId }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        
        // Add headers
        for (key, value) in SupabaseConfig.headers() {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Create request body
        let requestBody: [String: Any] = [
            "bibleChapter": bibleChapter,
            "initialRequest": true
        ]
        
        // Add request body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            self.errorMessage = "Failed to serialize request."
            self.isLoading = false
            
            // Remove the temporary podcast
            self.podcasts.removeAll { $0.id == tempId }
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Error generating podcast: \(error.localizedDescription)")
                    
                    // Provide more specific error messages based on error type
                    let errorMsg: String
                    if let urlError = error as? URLError, urlError.code == .timedOut {
                        errorMsg = "The request timed out. The Bible study generation is taking longer than expected. Please try again later."
                    } else if (error as NSError).domain == NSURLErrorDomain && (error as NSError).code == -1001 {
                        // -1001 is also a timeout error
                        errorMsg = "The request timed out. The Bible study generation is taking longer than expected. Please try again later."
                    } else {
                        errorMsg = "Failed to generate Bible study. Please try again."
                    }
                    
                    self.errorMessage = errorMsg
                    
                    // Remove the temporary podcast
                    self.podcasts.removeAll { $0.id == tempId }
                    
                    // Create a fallback podcast with error status
                    let fallbackPodcast = PodcastEntry(
                        id: UUID().uuidString,
                        title: "Bible Study on \(bibleChapter)",
                        description: "There was an error generating this Bible study. Please try again.",
                        chapter: bibleChapter,
                        audioUrl: nil,
                        status: PodcastStatus.failed,
                        createdAt: Date()
                    )
                    
                    // Add the fallback podcast to the list
                    self.podcasts.insert(fallbackPodcast, at: 0)
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received."
                    
                    // Remove the temporary podcast
                    self.podcasts.removeAll { $0.id == tempId }
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    decoder.dateDecodingStrategy = .formatted(dateFormatter)
                    
                    let podcast = try decoder.decode(PodcastEntry.self, from: data)
                    
                    // Remove the temporary podcast
                    self.podcasts.removeAll { $0.id == tempId }
                    
                    // Add the new podcast to the list
                    self.podcasts.insert(podcast, at: 0)
                    
                    // If the podcast is still generating, add it to pending list and start polling
                    if podcast.status == PodcastStatus.generating {
                        self.pendingPodcastIds.insert(podcast.id)
                        self.startPolling()
                    }
                } catch {
                    print("Error decoding podcast: \(error.localizedDescription)")
                    self.errorMessage = "Failed to decode podcast data. Please try again later."
                    
                    // Remove the temporary podcast
                    self.podcasts.removeAll { $0.id == tempId }
                }
            }
        }.resume()
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
        
        // Fetch the latest podcast data using direct HTTP request
        guard let url = URL(string: "\(SupabaseConfig.supabaseUrl)/rest/v1/podcasts?select=*&order=created_at.desc") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add headers
        for (key, value) in SupabaseConfig.headers() {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Add additional headers for Supabase REST API
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    print("Error checking pending podcasts: \(error.localizedDescription)")
                    // Don't stop polling on error, we'll try again
                    return
                }
                
                guard let data = data else {
                    print("No data received when checking pending podcasts")
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                    decoder.dateDecodingStrategy = .formatted(dateFormatter)
                    
                    let podcasts = try decoder.decode([PodcastEntry].self, from: data)
                    
                    // Update our podcast list
                    self.podcasts = podcasts
                    
                    // Check if any pending podcasts are now complete
                    var stillPending = false
                    var completedIds = Set<String>()
                    
                    for id in self.pendingPodcastIds {
                        if let podcast = podcasts.first(where: { $0.id == id }) {
                            if podcast.status == PodcastStatus.ready || podcast.status == PodcastStatus.failed {
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
                } catch {
                    print("Error decoding podcasts during polling: \(error.localizedDescription)")
                }
            }
        }.resume()
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