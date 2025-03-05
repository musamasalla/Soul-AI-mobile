import Foundation
import Combine
import UIKit

class MeditationViewModel: NSObject, ObservableObject {
    @Published var moodText: String = ""
    @Published var energyLevel: Double = 5.0
    @Published var stressLevel: Double = 5.0
    @Published var meditationTitle: String = ""
    @Published var meditationContent: String = ""
    @Published var meditationParagraphs: [String] = []
    @Published var meditationDuration: Int = 0
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
    
    func generateMeditation() {
        guard !moodText.isEmpty else {
            errorMessage = "Please share how you're feeling to generate a meditation."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Create request body with mood, energy level, and stress level
        let requestBody: [String: Any] = [
            "mood": moodText,
            "energyLevel": Int(energyLevel),
            "stressLevel": Int(stressLevel)
        ]
        
        SupabaseService.shared.generateMeditationWithMood(requestBody: requestBody)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                if case .failure(let error) = completion {
                    print("Error generating meditation: \(error.localizedDescription)")
                    self.errorMessage = "Failed to generate meditation. Please try again."
                    
                    // Use fallback content
                    self.meditationTitle = "Meditation for Your Current Mood"
                    self.meditationContent = "Take a deep breath and reflect on God's love. Remember that in all things, God works for the good of those who love him."
                    self.meditationParagraphs = ["Take a deep breath and reflect on God's love.", "Remember that in all things, God works for the good of those who love him."]
                    self.meditationDuration = 5
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
                
                // Use paragraphs from response if available, otherwise split content
                let paragraphs: [String]
                if let responseParagraphs = response.paragraphs, !responseParagraphs.isEmpty {
                    paragraphs = responseParagraphs
                } else {
                    paragraphs = content.split(separator: "\n")
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                }
                
                self.meditationTitle = title
                self.meditationContent = content
                self.meditationParagraphs = paragraphs
                
                // Estimate duration based on word count (about 150 words per minute for reading)
                let wordCount = content.split(separator: " ").count
                let estimatedMinutes = max(5, Int(ceil(Double(wordCount) / 150.0)))
                self.meditationDuration = response.duration > 0 ? response.duration : estimatedMinutes
            })
            .store(in: &cancellables)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 