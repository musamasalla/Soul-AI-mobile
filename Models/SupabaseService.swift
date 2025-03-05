import Foundation
import Combine

class SupabaseService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

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
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .flatMap { data -> AnyPublisher<[PodcastEntry], Error> in
                do {
                    // For debugging
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("API Response: \(jsonString)")
                    }
                    
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
} 