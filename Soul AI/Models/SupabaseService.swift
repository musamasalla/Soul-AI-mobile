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
    
    func sendMessage(message: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: SupabaseConfig.chatEndpoint) else {
            completion(.failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let requestBody: [String: Any] = [
            "message": message
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
            
            if let responseString = String(data: data, encoding: .utf8) {
                completion(.success(responseString))
            } else {
                completion(.failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"])))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String) async -> Result<User, Error> {
        do {
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            // Create a user with the provided email
            let userId = UUID().uuidString // Generate a UUID as fallback
            
            let appUser = User(
                id: userId,
                email: email,
                name: email.components(separatedBy: "@").first ?? "User"
            )
            
            return .success(appUser)
        } catch {
            return .failure(error)
        }
    }
    
    func signIn(email: String, password: String) async -> Result<User, Error> {
        do {
            let authResponse = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            // Create a user with the provided email
            let userId = UUID().uuidString // Generate a UUID as fallback
            
            let appUser = User(
                id: userId,
                email: email,
                name: email.components(separatedBy: "@").first ?? "User"
            )
            
            return .success(appUser)
        } catch {
            return .failure(error)
        }
    }
    
    func signOut() async -> Result<Void, Error> {
        do {
            try await supabase.auth.signOut()
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    func resetPassword(email: String) async -> Result<Void, Error> {
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    func getCurrentUser() async -> Result<User?, Error> {
        do {
            // Try to get the session
            do {
                let _ = try await supabase.auth.session
                
                // If we get here, we have a session, so create a mock user
                let userId = UUID().uuidString
                let userEmail = "user@example.com"
                
                let appUser = User(
                    id: userId,
                    email: userEmail,
                    name: userEmail.components(separatedBy: "@").first ?? "User"
                )
                
                return .success(appUser)
            } catch {
                // No session, return nil
                return .success(nil)
            }
        } catch {
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
}

// MARK: - Subscription Data Model

struct SubscriptionData: Codable {
    let id: String
    let userId: String
    let tier: String
    let status: String
    let expiresAt: Date?
} 