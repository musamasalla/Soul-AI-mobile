import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var inputMessage: String = ""
    @Published var isProcessing: Bool = false
    
    // Sample Bible verses and Christian responses
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
        
        // Simulate AI processing
        isProcessing = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Generate a response
            let responseContent = self.generateResponse(for: userMessage.content)
            let assistantMessage = Message(content: responseContent, role: .assistant)
            
            self.messages.append(assistantMessage)
            self.isProcessing = false
        }
    }
    
    private func generateResponse(for message: String) -> String {
        // In a real app, this would call an API to get a response from a Christian AI model
        // For now, we'll return a random Bible verse or Christian response
        return christianResponses.randomElement() ?? "May God bless you on your journey."
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
} 