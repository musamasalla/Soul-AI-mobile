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
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseUrl)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
    }
    
    // MARK: - Chat API
    
    func sendMessage(message: String, chatHistory: [[String: String]]) -> AnyPublisher<String, Error> {
        guard let url = URL(string: SupabaseConfig.chatEndpoint) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add headers
        for (key, value) in SupabaseConfig.headers() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Create request body
        let body: [String: Any] = [
            "message": message,
            "chatHistory": chatHistory
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    // Try to extract error message from response
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMessage = errorData["error"] as? String {
                        throw NSError(domain: "SupabaseErrorDomain", 
                                     code: httpResponse.statusCode,
                                     userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    } else {
                        throw NSError(domain: "SupabaseErrorDomain", 
                                     code: httpResponse.statusCode,
                                     userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
                    }
                }
                
                // Log response for debugging
                #if DEBUG
                if let responseString = String(data: data, encoding: .utf8) {
                    print("API Response: \(responseString)")
                }
                #endif
                
                return data
            }
            .decode(type: ChatResponse.self, decoder: JSONDecoder())
            .map { $0.response }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Daily Inspiration API
    
    func getDailyInspiration() -> AnyPublisher<String, Error> {
        guard let url = URL(string: SupabaseConfig.dailyInspirationEndpoint) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add headers
        for (key, value) in SupabaseConfig.headers() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    // Try to extract error message from response
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMessage = errorData["error"] as? String {
                        throw NSError(domain: "SupabaseErrorDomain", 
                                     code: httpResponse.statusCode,
                                     userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    } else {
                        throw NSError(domain: "SupabaseErrorDomain", 
                                     code: httpResponse.statusCode,
                                     userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
                    }
                }
                
                // Log response for debugging
                #if DEBUG
                if let responseString = String(data: data, encoding: .utf8) {
                    print("API Response: \(responseString)")
                }
                #endif
                
                return data
            }
            .decode(type: InspirationResponse.self, decoder: JSONDecoder())
            .map { $0.inspiration }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Meditation API
    
    func generateMeditation(topic: String) -> AnyPublisher<MeditationResponse, Error> {
        guard let url = URL(string: SupabaseConfig.meditationEndpoint) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add headers
        for (key, value) in SupabaseConfig.headers() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Create request body
        let body: [String: Any] = [
            "topic": topic
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    // Try to extract error message from response
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMessage = errorData["error"] as? String {
                        throw NSError(domain: "SupabaseErrorDomain", 
                                     code: httpResponse.statusCode,
                                     userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    } else {
                        throw NSError(domain: "SupabaseErrorDomain", 
                                     code: httpResponse.statusCode,
                                     userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
                    }
                }
                
                // Log response for debugging
                #if DEBUG
                if let responseString = String(data: data, encoding: .utf8) {
                    print("API Response: \(responseString)")
                }
                #endif
                
                return data
            }
            .decode(type: MeditationResponse.self, decoder: JSONDecoder())
            .map { response in
                // Add default duration if not provided
                let duration = 10
                return MeditationResponse(title: response.title, content: response.content, duration: duration)
            }
            .eraseToAnyPublisher()
    }
    
    func generateMeditationWithMood(requestBody: [String: Any]) -> AnyPublisher<MeditationResponse, Error> {
        guard let url = URL(string: SupabaseConfig.meditationEndpoint) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add headers
        for (key, value) in SupabaseConfig.headers() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                
                return data
            }
            .decode(type: MeditationResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    // Advanced meditation generation for premium users
    func generateAdvancedMeditation(requestBody: [String: Any]) -> AnyPublisher<MeditationResponse, Error> {
        guard let url = URL(string: SupabaseConfig.advancedMeditationEndpoint) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add headers
        for (key, value) in SupabaseConfig.headers() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                
                return data
            }
            .decode(type: MeditationResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    // MARK: - Podcast API
    
    func fetchPodcasts() -> AnyPublisher<[PodcastEntry], Error> {
        guard let url = URL(string: "\(SupabaseConfig.supabaseUrl)/rest/v1/podcasts?select=*&order=created_at.desc") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add headers
        for (key, value) in SupabaseConfig.headers() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add additional headers for Supabase REST API
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let decoder = createDecoderWithRobustDateHandling()
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    // Try to extract error message from response
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMessage = errorData["error"] as? String {
                        throw NSError(domain: "SupabaseErrorDomain", 
                                     code: httpResponse.statusCode,
                                     userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    } else {
                        throw NSError(domain: "SupabaseErrorDomain", 
                                     code: httpResponse.statusCode,
                                     userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
                    }
                }
                
                // Log response for debugging
                #if DEBUG
                if let responseString = String(data: data, encoding: .utf8) {
                    print("API Response: \(responseString)")
                }
                #endif
                
                return data
            }
            .flatMap { data -> AnyPublisher<[PodcastEntry], Error> in
                do {
                    let podcasts = try decoder.decode([PodcastEntry].self, from: data)
                    return Just(podcasts)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } catch {
                    print("Error decoding podcasts: \(error)")
                    // Return empty array instead of failing
                    return Just([])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    func generateBibleStudy(bibleChapter: String) -> AnyPublisher<PodcastEntry, Error> {
        guard let url = URL(string: SupabaseConfig.podcastEndpoint) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // Keep a reasonable timeout since we're now expecting a quick response
        request.timeoutInterval = 30
        
        // Add headers
        for (key, value) in SupabaseConfig.headers() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Create request body
        let body: [String: Any] = [
            "bibleChapter": bibleChapter,
            // Add a placeholder audio_url to satisfy the not-null constraint
            "initialRequest": true
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        let decoder = createDecoderWithRobustDateHandling()
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    // Try to extract error message from response
                    if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMessage = errorData["error"] as? String {
                        throw NSError(domain: "SupabaseErrorDomain", 
                                     code: httpResponse.statusCode,
                                     userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    } else {
                        throw NSError(domain: "SupabaseErrorDomain", 
                                     code: httpResponse.statusCode,
                                     userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"])
                    }
                }
                
                // Log response for debugging
                #if DEBUG
                if let responseString = String(data: data, encoding: .utf8) {
                    print("API Response: \(responseString)")
                }
                #endif
                
                return data
            }
            .flatMap { data -> AnyPublisher<PodcastEntry, Error> in
                do {
                    let podcast = try decoder.decode(PodcastEntry.self, from: data)
                    return Just(podcast)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } catch {
                    print("Error decoding podcast: \(error)")
                    
                    // If we can't decode the response, check if it's a JSON object with an error message
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorMessage = json["error"] as? String {
                        let error = NSError(domain: "SupabaseErrorDomain", 
                                           code: -1,
                                           userInfo: [NSLocalizedDescriptionKey: errorMessage])
                        return Fail(error: error).eraseToAnyPublisher()
                    }
                    
                    // Otherwise, propagate the original error
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Premium Podcast API
    
    func fetchPremiumPodcasts() async -> Result<[PremiumPodcast], Error> {
        guard let url = URL(string: "\(SupabaseConfig.supabaseUrl)/rest/v1/premium_podcasts?select=*&order=created_at.desc") else {
            return .failure(URLError(.badURL))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add headers
        for (key, value) in SupabaseConfig.headers() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add additional headers for Supabase REST API
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let decoder = createDecoderWithRobustDateHandling()
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(URLError(.badServerResponse))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to extract error message from response
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorData["error"] as? String {
                    return .failure(NSError(domain: "SupabaseErrorDomain", 
                                         code: httpResponse.statusCode,
                                         userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    return .failure(NSError(domain: "SupabaseErrorDomain", 
                                         code: httpResponse.statusCode,
                                         userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"]))
                }
            }
            
            // Log response for debugging
            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response: \(responseString)")
            }
            #endif
            
            do {
                let podcasts = try decoder.decode([PremiumPodcast].self, from: data)
                return .success(podcasts)
            } catch {
                print("Error decoding premium podcasts: \(error)")
                // Return empty array instead of failing
                return .success([])
            }
        } catch {
            return .failure(error)
        }
    }
    
    func generatePremiumPodcast(topic: String, duration: Int, voices: [String]) async -> Result<PremiumPodcast, Error> {
        guard let url = URL(string: SupabaseConfig.premiumPodcastEndpoint) else {
            return .failure(URLError(.badURL))
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // Keep a reasonable timeout since we're now expecting a quick response
        request.timeoutInterval = 30
        
        // Add headers
        for (key, value) in SupabaseConfig.headers() {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Create request body
        let body: [String: Any] = [
            "topic": topic,
            "duration": duration,
            "voices": voices,
            "initialRequest": true
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(URLError(.badServerResponse))
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to extract error message from response
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorData["error"] as? String {
                    return .failure(NSError(domain: "SupabaseErrorDomain", 
                                 code: httpResponse.statusCode,
                                 userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                } else {
                    return .failure(NSError(domain: "SupabaseErrorDomain", 
                                 code: httpResponse.statusCode,
                                 userInfo: [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"]))
                }
            }
            
            // Log response for debugging
            #if DEBUG
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response: \(responseString)")
            }
            #endif
            
            let decoder = createDecoderWithRobustDateHandling()
            
            do {
                let podcast = try decoder.decode(PremiumPodcast.self, from: data)
                return .success(podcast)
            } catch {
                print("Error decoding premium podcast: \(error)")
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String) async -> Result<User, Error> {
        do {
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            guard let id = authResponse.user?.id.uuidString else {
                return .failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to create user"]))
            }
            
            let user = User(
                id: id,
                email: email,
                name: email.components(separatedBy: "@").first ?? "User"
            )
            
            return .success(user)
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
            
            guard let id = authResponse.user?.id.uuidString,
                  let email = authResponse.user?.email else {
                return .failure(NSError(domain: "SupabaseErrorDomain", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid user data"]))
            }
            
            let user = User(
                id: id,
                email: email,
                name: email.components(separatedBy: "@").first ?? "User"
            )
            
            return .success(user)
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
            let session = try await supabase.auth.session
            
            guard let user = session?.user,
                  let email = user.email else {
                return .success(nil)
            }
            
            let appUser = User(
                id: user.id.uuidString,
                email: email,
                name: email.components(separatedBy: "@").first ?? "User"
            )
            
            return .success(appUser)
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
            
            guard case .success(let user) = userResult, let user = user else {
                return .success(SubscriptionStatus(isActive: false, tier: "free", expiresAt: nil))
            }
            
            // Fetch subscription from Supabase
            let response = try await supabase.database
                .from("subscriptions")
                .select()
                .eq("user_id", value: user.id)
                .eq("status", value: "active")
                .single()
                .execute()
            
            // Parse the response
            if let data = response.data {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                let subscription = try decoder.decode(SubscriptionData.self, from: data)
                
                return .success(SubscriptionStatus(
                    isActive: true,
                    tier: subscription.tier,
                    expiresAt: subscription.expiresAt
                ))
            } else {
                // No active subscription found
                return .success(SubscriptionStatus(isActive: false, tier: "free", expiresAt: nil))
            }
        } catch {
            // For demo purposes, return a free subscription on error
            return .success(SubscriptionStatus(isActive: false, tier: "free", expiresAt: nil))
        }
    }
    
    // Helper function to create a decoder with robust date handling
    private func createDecoderWithRobustDateHandling() -> JSONDecoder {
        let decoder = JSONDecoder()
        
        // Create a custom date formatter that can handle multiple formats
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        // Try multiple date formats
        let dateFormats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        ]
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            for format in dateFormats {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        
        return decoder
    }
}

// MARK: - Response Models

struct ChatResponse: Decodable {
    let response: String
}

struct InspirationResponse: Decodable {
    let inspiration: String
}

struct MeditationResponse: Decodable {
    let title: String
    let content: String
    let duration: Int
}

struct SubscriptionData: Decodable {
    let id: String
    let userId: String
    let tier: String
    let status: String
    let expiresAt: Date?
} 