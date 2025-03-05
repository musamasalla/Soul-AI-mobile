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
            })
            .store(in: &cancellables)
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
            status: .generating,
            createdAt: Date()
        )
        
        // Add the temporary podcast to the list
        self.podcasts.insert(tempPodcast, at: 0)
        
        SupabaseService.shared.generateBibleStudy(bibleChapter: bibleChapter)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                if case .failure(let error) = completion {
                    print("Error generating podcast: \(error.localizedDescription)")
                    self.errorMessage = "Failed to generate Bible study. Please try again."
                    
                    // Remove the temporary podcast
                    self.podcasts.removeAll { $0.id == tempId }
                    
                    // Create a fallback podcast with error status
                    let fallbackPodcast = PodcastEntry(
                        id: UUID().uuidString,
                        title: "Bible Study on \(bibleChapter)",
                        description: "There was an error generating this Bible study. Please try again.",
                        chapter: bibleChapter,
                        audioUrl: nil,
                        status: .failed,
                        createdAt: Date()
                    )
                    
                    // Add the fallback podcast to the list
                    self.podcasts.insert(fallbackPodcast, at: 0)
                }
                
                self.isLoading = false
            }, receiveValue: { [weak self] podcast in
                guard let self = self else { return }
                
                // Remove the temporary podcast
                self.podcasts.removeAll { $0.id == tempId }
                
                // Add the new podcast to the list
                self.podcasts.insert(podcast, at: 0)
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
        guard let audioUrl = podcast.audioUrl, let url = URL(string: audioUrl) else {
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
} 