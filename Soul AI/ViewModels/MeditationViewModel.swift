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
    @Published var showMeditation: Bool = false
    
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
        
        // Use the updated SupabaseService method
        SupabaseService.shared.generateMeditation(
            mood: moodText,
            topic: selectedTopic,
            duration: 5 // Basic meditations are fixed at 5 minutes
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let meditation):
                    self.meditation = meditation
                    self.showMeditation = true
                    
                case .failure(let error):
                    print("Error generating meditation: \(error.localizedDescription)")
                    self.errorMessage = "Failed to generate meditation. Please try again."
                    
                    // Use fallback content
                    self.meditation = Meditation(
                        title: "Meditation for Your Current Mood",
                        content: "Take a deep breath and reflect on God's love. Remember that in all things, God works for the good of those who love him.",
                        duration: 5
                    )
                }
            }
        }
    }
    
    // Generate advanced meditation (premium feature)
    func generateAdvancedMeditation() {
        guard !moodText.isEmpty else {
            errorMessage = "Please share how you're feeling to generate a meditation."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // DEVELOPMENT MODE: Use local mock instead of calling Supabase
        // This allows testing without a deployed Supabase function
        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Create a mock meditation based on user inputs
            let mockTitle = "Advanced \(self.selectedTopic) Meditation"
            
            var mockContent = "Welcome to this guided Christian meditation on \(self.selectedTopic). "
            mockContent += "As you're feeling \(self.moodText), take a moment to center yourself in God's presence. "
            
            if !self.scriptureReference.isEmpty {
                mockContent += "Reflecting on \(self.scriptureReference), we are reminded of God's faithfulness. "
            }
            
            mockContent += "Take a deep breath in... and out... Feel God's peace washing over you. "
            mockContent += "For the next \(self.meditationDuration) minutes, allow yourself to be fully present with God. "
            mockContent += "Remember that you are loved, you are valued, and you are never alone on this journey."
            
            self.meditation = Meditation(
                title: mockTitle,
                content: mockContent,
                duration: self.meditationDuration
            )
            
            self.isLoading = false
            self.showMeditation = true
        }
        #else
        // Use the updated SupabaseService method
        SupabaseService.shared.generateAdvancedMeditation(
            mood: moodText,
            topic: selectedTopic,
            duration: meditationDuration,
            scripture: scriptureReference.isEmpty ? nil : scriptureReference
        ) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let meditation):
                    self.meditation = meditation
                    self.showMeditation = true
                    
                case .failure(let error):
                    print("Error generating advanced meditation: \(error.localizedDescription)")
                    self.errorMessage = "Failed to generate meditation. Please try again."
                    
                    // Use fallback content
                    self.meditation = Meditation(
                        title: "Advanced Meditation for \(self.selectedTopic)",
                        content: "Take a deep breath and reflect on God's love. Remember that in all things, God works for the good of those who love him.",
                        duration: self.meditationDuration
                    )
                }
            }
        }
        #endif
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 