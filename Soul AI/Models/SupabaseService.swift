import Foundation
import Combine

class SupabaseService: SupabaseServiceProtocol {
    static let shared = SupabaseService()
    
    private let session: URLSession
    
    private init() {
        // Create a custom URLSession configuration with increased timeout
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60.0 // Increase timeout to 60 seconds
        configuration.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: configuration)
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
        // This would typically call Supabase auth.signUp
        // For now, return a mock user
        let mockUser = User(id: UUID().uuidString, email: email, name: "New User")
        return .success(mockUser)
    }
    
    func signIn(email: String, password: String) async -> Result<User, Error> {
        // This would typically call Supabase auth.signIn
        // For now, return a mock user
        let mockUser = User(id: UUID().uuidString, email: email, name: "Existing User")
        return .success(mockUser)
    }
    
    func signOut() async -> Result<Void, Error> {
        // This would typically call Supabase auth.signOut
        return .success(())
    }
    
    func resetPassword(email: String) async -> Result<Void, Error> {
        // This would typically call Supabase auth.resetPasswordForEmail
        return .success(())
    }
    
    func getCurrentUser() async -> Result<User?, Error> {
        // This would typically check Supabase auth.session()
        // For now, return nil to indicate no user is logged in
        return .success(nil)
    }
    
    func updateUser(user: User) async -> Result<User, Error> {
        // This would typically call Supabase auth.update
        return .success(user)
    }
    
    // MARK: - Subscription Methods
    
    func fetchSubscriptionStatus() async -> Result<SubscriptionStatus, Error> {
        // This would typically fetch the subscription status from Supabase
        // For now, return a mock subscription status
        let mockStatus = SubscriptionStatus(
            isActive: true,
            tier: "premium",
            expiresAt: Calendar.current.date(byAdding: .month, value: 1, to: Date())
        )
        return .success(mockStatus)
    }
}

// MARK: - Response Models

struct ChatResponse: Codable {
    let response: String
}

struct InspirationResponse: Codable {
    let title: String
    let content: String
    let verse: String
    let verse_content: String
    let theme: String
    let image_url: String
    
    var inspiration: String {
        return content
    }
}

struct MeditationResponse: Codable {
    let title: String
    let content: String
    let duration: Int
    
    enum CodingKeys: String, CodingKey {
        case title
        case content
        case duration
    }
    
    init(title: String, content: String, duration: Int) {
        self.title = title
        self.content = content
        self.duration = duration
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode title with fallback
        if let title = try? container.decode(String.self, forKey: .title) {
            self.title = title
        } else {
            self.title = "Christian Meditation"
        }
        
        // Decode content with fallback
        if let content = try? container.decode(String.self, forKey: .content) {
            self.content = content
        } else {
            self.content = "Take a deep breath and reflect on God's love. Remember that in all things, God works for the good of those who love him."
        }
        
        // Decode duration with fallback
        if let duration = try? container.decode(Int.self, forKey: .duration) {
            self.duration = duration
        } else {
            self.duration = 5
        }
    }
}

struct MeditationResponseWithParagraphs: Codable {
    let title: String
    let content: String
    let duration: Int
    let paragraphs: [String]?
    
    enum CodingKeys: String, CodingKey {
        case title
        case content
        case duration
        case paragraphs
    }
    
    init(title: String, content: String, duration: Int, paragraphs: [String]?) {
        self.title = title
        self.content = content
        self.duration = duration
        self.paragraphs = paragraphs
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        
        // Handle content as either a string or an array of strings
        if let contentString = try? container.decode(String.self, forKey: .content) {
            content = contentString
            paragraphs = nil
        } else if let contentArray = try? container.decode([String].self, forKey: .content) {
            content = contentArray.joined(separator: "\n")
            paragraphs = contentArray
        } else {
            throw DecodingError.dataCorruptedError(
                forKey: .content,
                in: container,
                debugDescription: "Expected String or [String] for content"
            )
        }
        
        // Try to decode duration, but use a default value if it's not present
        if let decodedDuration = try? container.decode(Int.self, forKey: .duration) {
            duration = decodedDuration
        } else {
            // Default duration (10 minutes)
            duration = 10
        }
    }
}

// MARK: - Helper Methods

private func createDecoderWithRobustDateHandling() -> JSONDecoder {
    let decoder = JSONDecoder()
    
    // Create a custom date formatter that can handle multiple formats
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    // Try multiple date formats
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        
        // Try ISO8601 first
        if let date = ISO8601DateFormatter().date(from: dateString) {
            return date
        }
        
        // Try other formats
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'"
        ]
        
        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
        }
        
        // If all else fails, return current date and log error
        print("Cannot decode date string: \(dateString), using current date instead")
        return Date()
    }
    
    return decoder
} 