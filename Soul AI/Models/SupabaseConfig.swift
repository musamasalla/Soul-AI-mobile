import Foundation

struct SupabaseConfig {
    // Supabase configuration
    static let supabaseUrl = "https://zihuvecrcuaovdiremzw.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InppaHV2ZWNyY3Vhb3ZkaXJlbXp3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkxNjk4MTEsImV4cCI6MjA1NDc0NTgxMX0.6T7dy7EIsbAHOJzjHwSOtZfRfGvgmD3Pz2SSg2NJn10"
    
    // API endpoints
    static let chatEndpoint = "\(supabaseUrl)/functions/v1/chat"
    static let dailyInspirationEndpoint = "\(supabaseUrl)/functions/v1/generate-daily-inspiration"
    static let meditationEndpoint = "\(supabaseUrl)/functions/v1/generate-meditation"
    static let advancedMeditationEndpoint = "\(supabaseUrl)/functions/v1/generate-advanced-meditation"
    static let podcastEndpoint = "\(supabaseUrl)/functions/v1/generate-podcast"
    static let summaryEndpoint = "\(supabaseUrl)/functions/v1/generate-summary"
    
    // Headers for API requests
    static func headers() -> [String: String] {
        return [
            "apikey": supabaseAnonKey,
            "Content-Type": "application/json"
        ]
    }
} 