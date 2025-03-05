import Foundation
import Combine

class SupabaseService {
    static let shared = SupabaseService()
    
    private init() {}
    
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
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
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
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
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
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: MeditationResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
    
    func generateMeditationWithMood(requestBody: [String: Any]) -> AnyPublisher<MeditationResponseWithParagraphs, Error> {
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
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: MeditationResponseWithParagraphs.self, decoder: JSONDecoder())
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
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: [PodcastEntry].self, decoder: decoder)
            .eraseToAnyPublisher()
    }
    
    func generateBibleStudy(bibleChapter: String) -> AnyPublisher<PodcastEntry, Error> {
        guard let url = URL(string: SupabaseConfig.podcastEndpoint) else {
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
            "bibleChapter": bibleChapter
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            .decode(type: PodcastEntry.self, decoder: decoder)
            .eraseToAnyPublisher()
    }
}

// MARK: - Response Models

struct ChatResponse: Codable {
    let response: String
}

struct InspirationResponse: Codable {
    let inspiration: String
}

struct MeditationResponse: Codable {
    let title: String
    let content: String
    let duration: Int
}

struct MeditationResponseWithParagraphs: Codable {
    let title: String
    let content: String
    let duration: Int
    let paragraphs: [String]?
} 