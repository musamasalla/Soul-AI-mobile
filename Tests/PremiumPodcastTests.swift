import XCTest
@testable import SoulAI

final class PremiumPodcastTests: XCTestCase {
    
    var viewModel: PremiumPodcastViewModel!
    var mockSupabaseService: MockSupabaseService!
    var mockUserPreferences: MockUserPreferences!
    
    override func setUp() {
        super.setUp()
        mockSupabaseService = MockSupabaseService()
        mockUserPreferences = MockUserPreferences()
        viewModel = PremiumPodcastViewModel(supabaseService: mockSupabaseService, userPreferences: mockUserPreferences)
    }
    
    override func tearDown() {
        viewModel = nil
        mockSupabaseService = nil
        mockUserPreferences = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(viewModel.selectedDuration, 15)
        XCTAssertEqual(viewModel.selectedTopic, "")
        XCTAssertTrue(viewModel.selectedVoices.isEmpty)
        XCTAssertFalse(viewModel.isGenerating)
        XCTAssertNil(viewModel.error)
    }
    
    func testCharacterLimitCalculation() {
        // Test 15 minute podcast
        viewModel.selectedDuration = 15
        XCTAssertEqual(viewModel.characterLimit, 11250) // 15 * 750
        
        // Test 30 minute podcast
        viewModel.selectedDuration = 30
        XCTAssertEqual(viewModel.characterLimit, 22500) // 30 * 750
        
        // Test 60 minute podcast
        viewModel.selectedDuration = 60
        XCTAssertEqual(viewModel.characterLimit, 45000) // 60 * 750
    }
    
    func testValidateInputs_Success() {
        viewModel.selectedTopic = "Faith and Prayer"
        viewModel.selectedDuration = 15
        viewModel.selectedVoices = [.alloy, .echo]
        
        mockUserPreferences.characterUsage = 10000
        mockUserPreferences.characterLimit = 45000
        
        XCTAssertTrue(viewModel.validateInputs())
        XCTAssertNil(viewModel.error)
    }
    
    func testValidateInputs_EmptyTopic() {
        viewModel.selectedTopic = ""
        viewModel.selectedDuration = 15
        viewModel.selectedVoices = [.alloy, .echo]
        
        XCTAssertFalse(viewModel.validateInputs())
        XCTAssertEqual(viewModel.error, .emptyTopic)
    }
    
    func testValidateInputs_InsufficientVoices() {
        viewModel.selectedTopic = "Faith and Prayer"
        viewModel.selectedDuration = 15
        viewModel.selectedVoices = [.alloy] // Only one voice
        
        XCTAssertFalse(viewModel.validateInputs())
        XCTAssertEqual(viewModel.error, .insufficientVoices)
    }
    
    func testValidateInputs_ExceedsCharacterLimit() {
        viewModel.selectedTopic = "Faith and Prayer"
        viewModel.selectedDuration = 60
        viewModel.selectedVoices = [.alloy, .echo]
        
        mockUserPreferences.characterUsage = 10000
        mockUserPreferences.characterLimit = 45000
        
        // Character usage (10000) + new podcast (45000) > limit (45000)
        XCTAssertFalse(viewModel.validateInputs())
        XCTAssertEqual(viewModel.error, .exceedsCharacterLimit)
    }
    
    func testGeneratePodcast_Success() async {
        // Setup
        viewModel.selectedTopic = "Faith and Prayer"
        viewModel.selectedDuration = 15
        viewModel.selectedVoices = [.alloy, .echo]
        
        mockUserPreferences.characterUsage = 10000
        mockUserPreferences.characterLimit = 45000
        
        let expectedPodcast = PremiumPodcast(
            id: UUID(),
            title: "Faith and Prayer Discussion",
            description: "A conversation about Faith and Prayer",
            topic: "Faith and Prayer",
            audioURL: nil,
            status: "generating",
            duration: 15,
            characterCount: 11250,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockSupabaseService.generatePremiumPodcastResult = .success(expectedPodcast)
        
        // Execute
        await viewModel.generatePodcast()
        
        // Verify
        XCTAssertFalse(viewModel.isGenerating)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(mockSupabaseService.generatePremiumPodcastCallCount, 1)
        XCTAssertEqual(mockSupabaseService.lastTopic, "Faith and Prayer")
        XCTAssertEqual(mockSupabaseService.lastDuration, 15)
        XCTAssertEqual(mockSupabaseService.lastVoices, ["alloy", "echo"])
    }
    
    func testGeneratePodcast_Failure() async {
        // Setup
        viewModel.selectedTopic = "Faith and Prayer"
        viewModel.selectedDuration = 15
        viewModel.selectedVoices = [.alloy, .echo]
        
        mockSupabaseService.generatePremiumPodcastResult = .failure(NSError(domain: "test", code: 500, userInfo: nil))
        
        // Execute
        await viewModel.generatePodcast()
        
        // Verify
        XCTAssertFalse(viewModel.isGenerating)
        XCTAssertEqual(viewModel.error, .serverError)
    }
    
    func testFetchPodcasts_Success() async {
        // Setup
        let expectedPodcasts = [
            PremiumPodcast(
                id: UUID(),
                title: "Faith Discussion",
                description: "A conversation about Faith",
                topic: "Faith",
                audioURL: "https://example.com/audio.mp3",
                status: "ready",
                duration: 15,
                characterCount: 11250,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        
        mockSupabaseService.fetchPremiumPodcastsResult = .success(expectedPodcasts)
        
        // Execute
        await viewModel.fetchPodcasts()
        
        // Verify
        XCTAssertEqual(viewModel.podcasts.count, 1)
        XCTAssertEqual(viewModel.podcasts.first?.title, "Faith Discussion")
        XCTAssertNil(viewModel.error)
    }
    
    func testFetchPodcasts_Failure() async {
        // Setup
        mockSupabaseService.fetchPremiumPodcastsResult = .failure(NSError(domain: "test", code: 500, userInfo: nil))
        
        // Execute
        await viewModel.fetchPodcasts()
        
        // Verify
        XCTAssertTrue(viewModel.podcasts.isEmpty)
        XCTAssertEqual(viewModel.error, .serverError)
    }
}

// MARK: - Mock Classes

class MockSupabaseService: SupabaseServiceProtocol {
    var generatePremiumPodcastResult: Result<PremiumPodcast, Error>?
    var fetchPremiumPodcastsResult: Result<[PremiumPodcast], Error>?
    
    var generatePremiumPodcastCallCount = 0
    var lastTopic: String?
    var lastDuration: Int?
    var lastVoices: [String]?
    
    func generatePremiumPodcast(topic: String, duration: Int, voices: [String]) async -> Result<PremiumPodcast, Error> {
        generatePremiumPodcastCallCount += 1
        lastTopic = topic
        lastDuration = duration
        lastVoices = voices
        return generatePremiumPodcastResult ?? .failure(NSError(domain: "test", code: 500, userInfo: nil))
    }
    
    func fetchPremiumPodcasts() async -> Result<[PremiumPodcast], Error> {
        return fetchPremiumPodcastsResult ?? .failure(NSError(domain: "test", code: 500, userInfo: nil))
    }
    
    // Implement other required methods from SupabaseServiceProtocol with empty implementations
    func signUp(email: String, password: String) async -> Result<User, Error> {
        return .failure(NSError(domain: "test", code: 500, userInfo: nil))
    }
    
    func signIn(email: String, password: String) async -> Result<User, Error> {
        return .failure(NSError(domain: "test", code: 500, userInfo: nil))
    }
    
    func signOut() async -> Result<Void, Error> {
        return .success(())
    }
    
    func resetPassword(email: String) async -> Result<Void, Error> {
        return .success(())
    }
    
    func getCurrentUser() async -> Result<User?, Error> {
        return .success(nil)
    }
    
    func updateUser(user: User) async -> Result<User, Error> {
        return .failure(NSError(domain: "test", code: 500, userInfo: nil))
    }
    
    func fetchSubscriptionStatus() async -> Result<SubscriptionStatus, Error> {
        return .failure(NSError(domain: "test", code: 500, userInfo: nil))
    }
}

class MockUserPreferences: UserPreferencesProtocol {
    var characterUsage: Int = 0
    var characterLimit: Int = 45000
    
    var isLoggedIn: Bool = true
    var currentUser: User? = User(id: UUID().uuidString, email: "test@example.com", name: "Test User")
    var subscriptionStatus: SubscriptionStatus = SubscriptionStatus(isActive: true, tier: "premium", expiresAt: Date().addingTimeInterval(30*24*60*60))
    
    func getCharacterUsage() -> Int {
        return characterUsage
    }
    
    func getCharacterLimit() -> Int {
        return characterLimit
    }
    
    func updateCharacterUsage(newUsage: Int) {
        characterUsage = newUsage
    }
    
    func isUserLoggedIn() -> Bool {
        return isLoggedIn
    }
    
    func getCurrentUser() -> User? {
        return currentUser
    }
    
    func getSubscriptionStatus() -> SubscriptionStatus {
        return subscriptionStatus
    }
    
    func clearUserData() {
        isLoggedIn = false
        currentUser = nil
        subscriptionStatus = SubscriptionStatus(isActive: false, tier: "free", expiresAt: nil)
    }
} 