import Foundation
import SwiftUI
import Combine

struct Inspiration {
    var verse: String
    var reference: String
    var reflection: String
    var prayer: String
    
    static let placeholder = Inspiration(
        verse: "For I know the plans I have for you, declares the LORD, plans for welfare and not for evil, to give you a future and a hope.",
        reference: "Jeremiah 29:11",
        reflection: "God has a purpose and plan for your life. Even in difficult times, He is working all things together for your good. Trust in His timing and His wisdom.",
        prayer: "Dear Lord, help me to trust in Your perfect plan for my life. Give me the patience to wait on Your timing and the faith to believe in Your promises. Amen."
    )
}

class DailyInspirationViewModel: ObservableObject {
    @Published var inspiration: Inspiration = Inspiration.placeholder
    @Published var isLoading: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    
    var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
    
    var shareText: String {
        """
        Daily Inspiration from Soul AI
        
        \(inspiration.verse)
        - \(inspiration.reference)
        
        \(inspiration.reflection)
        
        Prayer:
        \(inspiration.prayer)
        """
    }
    
    func loadInspiration() {
        isLoading = true
        
        SupabaseService.shared.getDailyInspiration()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                if case .failure(let error) = completion {
                    print("Error getting daily inspiration: \(error.localizedDescription)")
                    // Use placeholder in case of error
                    self.inspiration = Inspiration.placeholder
                }
                
                self.isLoading = false
            }, receiveValue: { [weak self] inspirationText in
                guard let self = self else { return }
                
                // Parse the inspiration text into components
                // This is a simplified implementation - in a real app, you'd parse the actual API response
                let components = self.parseInspirationText(inspirationText)
                self.inspiration = components
                self.isLoading = false
            })
            .store(in: &cancellables)
    }
    
    private func parseInspirationText(_ text: String) -> Inspiration {
        // In a real implementation, this would parse the API response
        // For now, we'll return the placeholder
        return Inspiration.placeholder
    }
} 