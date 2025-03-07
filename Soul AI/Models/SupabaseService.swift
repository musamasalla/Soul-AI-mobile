import Foundation
import Combine
import Supabase

class SupabaseService: SupabaseServiceProtocol {
    static let shared = SupabaseService()
    
    private let session: URLSession
    private let supabase: SupabaseClient
    
    private init() {
        // Create a custom URLSession configuration with increased timeout
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60.0 // Increase timeout to 60 seconds
        configuration.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: configuration)
        
        // Initialize Supabase client
        let supabaseUrl = URL(string: SupabaseConfig.supabaseUrl)!
        let supabaseKey = SupabaseConfig.supabaseAnonKey
        
        self.supabase = SupabaseClient(
            supabaseURL: supabaseUrl,
            supabaseKey: supabaseKey
        )
    }
    
    // MARK: - Chat Methods
    
    func sendMessage(message: String, history: [[String: String]] = [], completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: SupabaseConfig.chatEndpoint) else {
            completion(.failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let requestBody: [String: Any] = [
            "message": message,
            "history": history
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        for (key, value) in SupabaseConfig.headers() {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "SupabaseErrorDomain", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let chatResponse = try decoder.decode(ChatResponse.self, from: data)
                completion(.success(chatResponse.response))
            } catch {
                // Try to extract the response directly if the JSON structure is different
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let response = json["response"] as? String {
                    completion(.success(response))
                } else if let responseString = String(data: data, encoding: .utf8) {
                    completion(.success(responseString))
                } else {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String) async -> Result<User, Error> {
        print("DEBUG: SupabaseService - signUp called with email: \(email)")
        do {
            // Use only the signUp method which is available in the SDK
            print("DEBUG: Trying supabase.auth.signUp")
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            print("DEBUG: SupabaseService - signUp successful")
            
            // Create a user with the provided email
            let userId = UUID().uuidString // Generate a UUID as fallback
            
            let appUser = User(
                id: userId,
                email: email,
                name: email.components(separatedBy: "@").first ?? "User"
            )
            
            return .success(appUser)
        } catch {
            print("DEBUG: SupabaseService - signUp failed with error: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    func signIn(email: String, password: String) async -> Result<User, Error> {
        print("DEBUG: SupabaseService - signIn called with email: \(email)")
        do {
            print("DEBUG: SupabaseService - attempting to sign in with Supabase")
            // Use only the signIn method which is available in the SDK
            print("DEBUG: Trying supabase.auth.signIn")
            let authResponse = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            print("DEBUG: SupabaseService - signIn successful with Supabase")
            
            // Create a user with the provided email
            let userId = UUID().uuidString // Generate a UUID as fallback
            
            let appUser = User(
                id: userId,
                email: email,
                name: email.components(separatedBy: "@").first ?? "User"
            )
            
            print("DEBUG: SupabaseService - created app user: \(appUser)")
            return .success(appUser)
        } catch {
            print("DEBUG: SupabaseService - signIn failed with error: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    func signOut() async -> Result<Void, Error> {
        print("DEBUG: SupabaseService - signOut called")
        do {
            try await supabase.auth.signOut()
            print("DEBUG: SupabaseService - signOut successful")
            return .success(())
        } catch {
            print("DEBUG: SupabaseService - signOut failed with error: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    func resetPassword(email: String) async -> Result<Void, Error> {
        print("DEBUG: SupabaseService - resetPassword called for email: \(email)")
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            print("DEBUG: SupabaseService - resetPassword successful")
            return .success(())
        } catch {
            print("DEBUG: SupabaseService - resetPassword failed with error: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    func getCurrentUser() async -> Result<User?, Error> {
        print("DEBUG: SupabaseService - getCurrentUser called")
        do {
            // Try to get the session
            do {
                print("DEBUG: SupabaseService - attempting to get session")
                let _ = try await supabase.auth.session
                print("DEBUG: SupabaseService - session found")
                
                // If we get here, we have a session, so create a mock user
                let userId = UUID().uuidString
                let userEmail = "user@example.com"
                
                let appUser = User(
                    id: userId,
                    email: userEmail,
                    name: userEmail.components(separatedBy: "@").first ?? "User"
                )
                
                print("DEBUG: SupabaseService - returning mock user: \(appUser)")
                return .success(appUser)
            } catch {
                // No session, return nil
                print("DEBUG: SupabaseService - no session found, returning nil user")
                return .success(nil)
            }
        } catch {
            print("DEBUG: SupabaseService - getCurrentUser failed with error: \(error.localizedDescription)")
            return .failure(error)
        }
    }
    
    func updateUser(user: User) async -> Result<User, Error> {
        // In a real implementation, you would update the user's profile in Supabase
        // For now, we'll just return the user as is
        return .success(user)
    }
    
    // MARK: - Subscription Methods
    
    func fetchSubscriptionStatus() async -> Result<SubscriptionStatus, Error> {
        do {
            // Check if user is authenticated
            let userResult = await getCurrentUser()
            
            // If there's no user or the result is a failure, return a default subscription status
            if case .failure = userResult {
                return .success(SubscriptionStatus(isActive: false, tier: "free"))
            }
            
            var userId = ""
            if case .success(let optionalUser) = userResult {
                if let user = optionalUser {
                    userId = user.id
                } else {
                    return .success(SubscriptionStatus(isActive: false, tier: "free"))
                }
            }
            
            // Create a URL for the subscriptions endpoint
            guard let url = URL(string: "\(SupabaseConfig.supabaseUrl)/rest/v1/subscriptions?user_id=eq.\(userId)&status=eq.active&select=*&limit=1") else {
                return .success(SubscriptionStatus(isActive: false, tier: "free"))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add headers
        for (key, value) in SupabaseConfig.headers() {
                request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Add additional headers for Supabase REST API
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            // Perform the request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return .success(SubscriptionStatus(isActive: false, tier: "free"))
            }
            
            // Parse the response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            // The response is an array of subscriptions
            let subscriptions = try decoder.decode([SubscriptionData].self, from: data)
            
            if let subscription = subscriptions.first {
                return .success(SubscriptionStatus(
                    isActive: true,
                    tier: subscription.tier,
                    status: subscription.status,
                    expiresAt: subscription.expiresAt
                ))
            } else {
                // No active subscription found
                return .success(SubscriptionStatus(isActive: false, tier: "free"))
            }
        } catch {
            // For demo purposes, return a free subscription on error
            return .success(SubscriptionStatus(isActive: false, tier: "free"))
        }
    }
    
    // MARK: - Premium Podcast Methods
    
    func fetchPremiumPodcasts() async -> Result<[PremiumPodcast], Error> {
        do {
            // Create a URL for the premium podcasts endpoint
        guard let url = URL(string: "\(SupabaseConfig.supabaseUrl)/rest/v1/premium_podcasts?select=*&order=created_at.desc") else {
                return .success([])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add headers
        for (key, value) in SupabaseConfig.headers() {
                request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Add additional headers for Supabase REST API
            request.addValue("application/json", forHTTPHeaderField: "Accept")
        
            // Perform the request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return .success([])
            }
            
            // Parse the response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
                let podcasts = try decoder.decode([PremiumPodcast].self, from: data)
                return .success(podcasts)
            } catch {
            // For demo purposes, return an empty array on error
                return .success([])
        }
    }
    
    func generatePremiumPodcast(topic: String, duration: Int, voices: [String]) async -> Result<PremiumPodcast, Error> {
        do {
            // Create request body
            let requestBody: [String: Any] = [
                "topic": topic,
                "duration": duration,
                "voices": voices,
                "initialRequest": true
            ]
            
            // Create URL request
        guard let url = URL(string: SupabaseConfig.premiumPodcastEndpoint) else {
                return .failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        
        // Add headers
        for (key, value) in SupabaseConfig.headers() {
                request.addValue(value, forHTTPHeaderField: key)
            }
            
            // Add request body
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            // Perform request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return .failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Server error"]))
            }
            
            // Parse response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
                let podcast = try decoder.decode(PremiumPodcast.self, from: data)
                return .success(podcast)
        } catch {
            return .failure(error)
        }
    }
    
    // Test method to check if Supabase client is properly initialized
    func testSupabaseConnection() {
        print("DEBUG: Testing Supabase connection")
        print("DEBUG: Supabase URL: \(SupabaseConfig.supabaseUrl)")
        print("DEBUG: Supabase client initialized: \(supabase != nil)")
        
        Task {
            do {
                print("DEBUG: Attempting to get Supabase session")
                let session = try? await supabase.auth.session
                print("DEBUG: Supabase session: \(String(describing: session))")
            } catch {
                print("DEBUG: Error getting Supabase session: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Meditation Methods
    
    func generateMeditation(mood: String, topic: String, duration: Int, completion: @escaping (Result<Meditation, Error>) -> Void) {
        guard let url = URL(string: SupabaseConfig.meditationEndpoint) else {
            completion(.failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let requestBody: [String: Any] = [
            "mood": mood,
            "topic": topic,
            "duration": duration,
            "energyLevel": 5,
            "stressLevel": 5
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        for (key, value) in SupabaseConfig.headers() {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "SupabaseErrorDomain", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let meditationResponse = try decoder.decode(MeditationResponse.self, from: data)
                
                // Clean up title but preserve formatting for content
                var title = meditationResponse.title
                title = title.replacingOccurrences(of: "###", with: "")
                title = title.replacingOccurrences(of: "**", with: "")
                title = title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                let meditation = Meditation(
                    title: title,
                    content: meditationResponse.content,
                    duration: meditationResponse.duration > 0 ? meditationResponse.duration : duration
                )
                
                completion(.success(meditation))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    func generateAdvancedMeditation(mood: String, topic: String, duration: Int, scripture: String?, completion: @escaping (Result<Meditation, Error>) -> Void) {
        guard let url = URL(string: SupabaseConfig.meditationEndpoint) else {
            completion(.failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var requestBody: [String: Any] = [
            "mood": mood,
            "topic": topic,
            "duration": duration,
            "energyLevel": 5,
            "stressLevel": 5
        ]
        
        if let scripture = scripture, !scripture.isEmpty {
            requestBody["scripture"] = scripture
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        for (key, value) in SupabaseConfig.headers() {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "SupabaseErrorDomain", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let meditationResponse = try decoder.decode(MeditationResponse.self, from: data)
                
                // Clean up title but preserve formatting for content
                var title = meditationResponse.title
                title = title.replacingOccurrences(of: "###", with: "")
                title = title.replacingOccurrences(of: "**", with: "")
                title = title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                let meditation = Meditation(
                    title: title,
                    content: meditationResponse.content,
                    duration: meditationResponse.duration > 0 ? meditationResponse.duration : duration
                )
                
                completion(.success(meditation))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Daily Inspiration Methods
    
    func getDailyInspiration(completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: SupabaseConfig.dailyInspirationEndpoint) else {
            completion(.failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        for (key, value) in SupabaseConfig.headers() {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "SupabaseErrorDomain", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error \(httpResponse.statusCode)"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let inspirationResponse = try decoder.decode(InspirationResponse.self, from: data)
                
                let formattedInspiration = """
                \(inspirationResponse.verse)
                
                \(inspirationResponse.reflection)
                
                \(inspirationResponse.prayer)
                """
                
                completion(.success(formattedInspiration))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}

// MARK: - Subscription Data Model

struct SubscriptionData: Codable {
    let id: String
    let userId: String
    let tier: String
    let status: String
    let expiresAt: Date?
} 