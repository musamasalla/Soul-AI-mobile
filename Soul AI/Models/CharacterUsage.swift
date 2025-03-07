import Foundation

class CharacterUsage: Codable {
    var totalCharactersUsed: Int
    var lastResetDate: Date
    var monthlyLimit: Int
    
    enum CodingKeys: String, CodingKey {
        case totalCharactersUsed = "total_characters_used"
        case lastResetDate = "last_reset_date"
        case monthlyLimit = "monthly_limit"
    }
    
    init(totalCharactersUsed: Int = 0, lastResetDate: Date = Date(), monthlyLimit: Int = 45000) {
        self.totalCharactersUsed = totalCharactersUsed
        self.lastResetDate = lastResetDate
        self.monthlyLimit = monthlyLimit
    }
    
    // Calculate remaining characters for the month
    var remainingCharacters: Int {
        return max(0, monthlyLimit - totalCharactersUsed)
    }
    
    // Check if user has enough characters for a podcast of given duration
    func hasEnoughCharactersFor(duration: Int) -> Bool {
        let requiredCharacters = CharacterUsage.charactersForDuration(duration)
        return remainingCharacters >= requiredCharacters
    }
    
    // Calculate how many minutes of podcast the user can generate with remaining characters
    var remainingMinutes: Int {
        return Int(Double(remainingCharacters) / 750.0)
    }
    
    // Reset usage if a month has passed
    func checkAndResetIfNeeded() {
        let calendar = Calendar.current
        if let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date()),
           lastResetDate < oneMonthAgo {
            totalCharactersUsed = 0
            lastResetDate = Date()
        }
    }
    
    // Add character usage
    func addUsage(_ characters: Int) {
        checkAndResetIfNeeded()
        totalCharactersUsed += characters
    }
    
    // Static helper to calculate characters needed for a given duration
    static func charactersForDuration(_ minutes: Int) -> Int {
        // 45000 characters = 60 minutes
        // 750 characters = 1 minute
        return minutes * 750
    }
    
    // Static helper to calculate duration possible for a given character count
    static func durationForCharacters(_ characters: Int) -> Int {
        return Int(Double(characters) / 750.0)
    }
} 