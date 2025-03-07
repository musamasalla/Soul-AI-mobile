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
        
        // Create request body with mood and topic
        let requestBody: [String: Any] = [
            "mood": moodText,
            "topic": selectedTopic,
            "duration": 5 // Basic meditations are fixed at 5 minutes
        ]
        
        // Since the generateMeditationWithMood method is no longer available,
        // we'll use a direct HTTP request to the meditation endpoint
        guard let url = URL(string: SupabaseConfig.meditationEndpoint) else {
            self.errorMessage = "Invalid URL configuration."
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add headers
        for (key, value) in SupabaseConfig.headers() {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Add request body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            self.errorMessage = "Failed to serialize request."
            self.isLoading = false
            return
        }
        
        // Perform the request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Error generating meditation: \(error.localizedDescription)")
                    self.errorMessage = "Failed to generate meditation. Please try again."
                    
                    // Use fallback content
                    self.meditation = Meditation(
                        title: "Meditation for Your Current Mood",
                        content: "Take a deep breath and reflect on God's love. Remember that in all things, God works for the good of those who love him.",
                        duration: 5
                    )
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(MeditationResponse.self, from: data)
                    
                    // Clean up title but preserve formatting for content
                    var title = response.title
                    title = title.replacingOccurrences(of: "###", with: "")
                    title = title.replacingOccurrences(of: "**", with: "")
                    title = title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    
                    // Store the raw content
                    let content = response.content
                    
                    // Create meditation object
                    self.meditation = Meditation(
                        title: title,
                        content: content,
                        duration: response.duration > 0 ? response.duration : 5
                    )
                } catch {
                    print("Error decoding meditation response: \(error.localizedDescription)")
                    self.errorMessage = "Failed to decode meditation response. Please try again."
                    
                    // Use fallback content
                    self.meditation = Meditation(
                        title: "Meditation for Your Current Mood",
                        content: "Take a deep breath and reflect on God's love. Remember that in all things, God works for the good of those who love him.",
                        duration: 5
                    )
                }
            }
        }.resume()
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
        // Since the generateAdvancedMeditation method is no longer available,
        // we'll use a direct HTTP request to the advanced meditation endpoint
        guard let url = URL(string: SupabaseConfig.advancedMeditationEndpoint) else {
            self.errorMessage = "Invalid URL configuration."
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add headers
        for (key, value) in SupabaseConfig.headers() {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Add request body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            self.errorMessage = "Failed to serialize request."
            self.isLoading = false
            return
        }
        
        // Perform the request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("Error generating advanced meditation: \(error.localizedDescription)")
                    self.errorMessage = "Failed to generate meditation. Please try again."
                    
                    // Use fallback content
                    self.meditation = Meditation(
                        title: "Advanced Meditation for \(self.selectedTopic)",
                        content: "Take a deep breath and reflect on God's love. Remember that in all things, God works for the good of those who love him.",
                        duration: self.meditationDuration
                    )
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let meditation = try decoder.decode(Meditation.self, from: data)
                    
                    self.meditation = meditation
                    self.showMeditation = true
                } catch {
                    print("Error decoding meditation response: \(error.localizedDescription)")
                    self.errorMessage = "Failed to decode meditation response. Please try again."
                    
                    // Use fallback content
                    self.meditation = Meditation(
                        title: "Advanced Meditation for \(self.selectedTopic)",
                        content: "Take a deep breath and reflect on God's love. Remember that in all things, God works for the good of those who love him.",
                        duration: self.meditationDuration
                    )
                }
            }
        }.resume()
        #endif
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// Define the MeditationResponse struct for decoding API responses
struct MeditationResponse: Codable {
    let title: String
    let content: String
    let duration: Int
} 