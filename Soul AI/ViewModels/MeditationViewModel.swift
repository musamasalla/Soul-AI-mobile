import Foundation
import Combine
import UIKit

struct Meditation {
    let title: String
    let content: String
    let duration: Int
}

class MeditationViewModel: NSObject, ObservableObject {
    @Published var moodText: String = ""
    @Published var selectedTopic: String = "Peace"
    @Published var scriptureReference: String = ""
    @Published var meditationDuration: Int = 10
    @Published var meditation: Meditation?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            // App went to background
        }
    }
    
    // Generate basic meditation
    func generateMeditation() {
        guard !moodText.isEmpty else {
            errorMessage = "Please share how you're feeling to generate a meditation."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Create request body with mood and topic
        let requestBody: [String: Any] = [
            "mood": moodText,
            "topic": selectedTopic,
            "duration": 5 // Basic meditations are fixed at 5 minutes
        ]
        
        SupabaseService.shared.generateMeditationWithMood(requestBody: requestBody)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                if case .failure(let error) = completion {
                    print("Error generating meditation: \(error.localizedDescription)")
                    self.errorMessage = "Failed to generate meditation. Please try again."
                    
                    // Use fallback content
                    self.meditation = Meditation(
                        title: "Meditation for Your Current Mood",
                        content: "Take a deep breath and reflect on God's love. Remember that in all things, God works for the good of those who love him.",
                        duration: 5
                    )
                }
                
                self.isLoading = false
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                // Clean up title but preserve formatting for content
                var title = response.title
                title = title.replacingOccurrences(of: "###", with: "")
                title = title.replacingOccurrences(of: "**", with: "")
                title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Store the raw content
                let content = response.content
                
                // Create meditation object
                self.meditation = Meditation(
                    title: title,
                    content: content,
                    duration: response.duration > 0 ? response.duration : 5
                )
            })
            .store(in: &cancellables)
    }
    
    // Generate advanced meditation (premium feature)
    func generateAdvancedMeditation() {
        guard !moodText.isEmpty else {
            errorMessage = "Please share how you're feeling to generate a meditation."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Create request body with all advanced options
        var requestBody: [String: Any] = [
            "mood": moodText,
            "topic": selectedTopic,
            "duration": meditationDuration,
            "isPremium": true
        ]
        
        // Add scripture reference if provided
        if !scriptureReference.isEmpty {
            requestBody["scriptureReference"] = scriptureReference
        }
        
        SupabaseService.shared.generateAdvancedMeditation(requestBody: requestBody)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                if case .failure(let error) = completion {
                    print("Error generating advanced meditation: \(error.localizedDescription)")
                    self.errorMessage = "Failed to generate meditation. Please try again."
                    
                    // Use fallback content
                    self.meditation = Meditation(
                        title: "Advanced Meditation for \(self.selectedTopic)",
                        content: "Take a deep breath and reflect on God's love. Remember that in all things, God works for the good of those who love him.",
                        duration: self.meditationDuration
                    )
                }
                
                self.isLoading = false
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                // Clean up title but preserve formatting for content
                var title = response.title
                title = title.replacingOccurrences(of: "###", with: "")
                title = title.replacingOccurrences(of: "**", with: "")
                title = title.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Store the raw content
                let content = response.content
                
                // Create meditation object
                self.meditation = Meditation(
                    title: title,
                    content: content,
                    duration: self.meditationDuration
                )
            })
            .store(in: &cancellables)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 