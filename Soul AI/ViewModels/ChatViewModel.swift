import Foundation
import SwiftUI
import Combine

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputMessage: String = ""
    @Published var isProcessing: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // Sample Bible verses and Christian responses as fallback
    private let christianResponses = [
        "The Lord is my shepherd; I shall not want. - Psalm 23:1",
        "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life. - John 3:16",
        "I can do all things through Christ who strengthens me. - Philippians 4:13",
        "Trust in the LORD with all your heart and lean not on your own understanding. - Proverbs 3:5",
        "Be strong and courageous. Do not be afraid; do not be discouraged, for the LORD your God will be with you wherever you go. - Joshua 1:9",
        "The fruit of the Spirit is love, joy, peace, patience, kindness, goodness, faithfulness, gentleness and self-control. - Galatians 5:22-23",
        "Come to me, all you who are weary and burdened, and I will give you rest. - Matthew 11:28",
        "In all things God works for the good of those who love him, who have been called according to his purpose. - Romans 8:28"
    ]
    
    func sendMessage() {
        guard !inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(content: inputMessage, role: .user)
        messages.append(userMessage)
        
        // Clear input field
        inputMessage = ""
        
        // Start AI processing
        isProcessing = true
        
        // Convert messages to the format expected by the API
        let history = messages.dropLast().map { message -> [String: String] in
            return [
                "role": message.role.rawValue,
                "content": message.content
            ]
        }
        
        // Call the updated SupabaseService method with chat history
        SupabaseService.shared.sendMessage(message: userMessage.content, history: Array(history)) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                
                switch result {
                case .success(let response):
                    let assistantMessage = Message(content: response, role: .assistant)
                    self.messages.append(assistantMessage)
                    
                case .failure(let error):
                    print("Error getting response: \(error.localizedDescription)")
                    // Use fallback response in case of error
                    let fallbackResponse = self.christianResponses.randomElement() ?? "May God bless you on your journey."
                    let assistantMessage = Message(content: fallbackResponse, role: .assistant)
                    self.messages.append(assistantMessage)
                }
            }
        }
    }
    
    // Add some initial messages for demonstration
    func addWelcomeMessage() {
        if messages.isEmpty {
            let welcomeMessage = Message(
                content: "Hello! I'm Soul AI, your Christian companion. How can I help you in your faith journey today?",
                role: .assistant
            )
            messages.append(welcomeMessage)
        }
    }
    
    // Get daily inspiration
    func getDailyInspiration(completion: @escaping (String) -> Void) {
        SupabaseService.shared.getDailyInspiration { result in
            switch result {
            case .success(let inspiration):
                completion(inspiration)
            case .failure(let error):
                print("Error getting daily inspiration: \(error.localizedDescription)")
                // Use fallback inspiration in case of error
                let fallbackVerse = self.christianResponses.randomElement() ?? "May God bless you today and always."
                let fallbackReflection = "God has a purpose and plan for your life. Even in difficult times, He is working all things together for your good. Trust in His timing and His wisdom."
                let fallbackPrayer = "Dear Lord, help me to trust in Your perfect plan for my life. Give me the patience to wait on Your timing and the faith to believe in Your promises. Amen."
                
                let formattedInspiration = """
                \(fallbackVerse)
                
                \(fallbackReflection)
                
                \(fallbackPrayer)
                """
                
                completion(formattedInspiration)
            }
        }
    }
} 