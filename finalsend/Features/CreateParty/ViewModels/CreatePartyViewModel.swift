import Foundation
import Combine
import SwiftUI

// MARK: - Wizard Step Enum
enum CreatePartyStep: Int, CaseIterable {
    case type, name, dates, location, vibe, cover, review
}

@MainActor
class CreatePartyViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var draft = PartyDraft()
    @Published var isSubmitting = false
    @Published var availableCities: [CityModel] = []
    @Published var selectedCity: CityModel?
    @Published var searchQuery = ""
    @Published var errorMessage: String?
    @Published var showSuccessToast = false
    @Published var partyCreatedSuccessfully = false
    
    // MARK: - Wizard Navigation Properties
    @Published var step: CreatePartyStep = .type
    @Published var coverImage: UIImage? = nil
    
    // MARK: - Private Properties
    private let citySearchService: CitySearchServiceType
    private let partyCreationService: PartyCreationServiceType
    private let specialRoleService: SpecialRoleServiceType
    private let coverImageService: CoverImageServiceType
    private var partyManager: PartyManager
    private var appNavigator: AppNavigator
    private var searchCancellable: AnyCancellable?
    
    // MARK: - Constants
    static let partyTypeOptions = ["Bachelor Party", "Bachelorette Party", "Birthday Trip", "Golf Trip", "Festival / Concert", "Trip with Friends", "Other"]
    static let vibeTags = [
        "Chill", "Lowkey", "Rowdy", "Wild", "Bougie", "Classy", "Luxury", "Nightlife",
        "Bar Crawl", "Pool", "Games", "Gambling", "Outdoorsy", "Athletic", "Adventure",
        "Sports", "Music", "Festival", "Foodie", "Dining", "Shopping", "Beach", "City",
        "Cabin", "Country", "Relax", "Wellness", "Bonding", "Celebrate"
    ]
    
    // MARK: - Initialization
    init(
        citySearchService: CitySearchServiceType = CitySearchService(),
        partyCreationService: PartyCreationServiceType = PartyCreationService(),
        specialRoleService: SpecialRoleServiceType = SpecialRoleService(),
        coverImageService: CoverImageServiceType = CoverImageService(),
        partyManager: PartyManager = PartyManager(),
        appNavigator: AppNavigator? = nil
    ) {
        self.citySearchService = citySearchService
        self.partyCreationService = partyCreationService
        self.specialRoleService = specialRoleService
        self.coverImageService = coverImageService
        self.partyManager = partyManager
        self.appNavigator = appNavigator ?? AppNavigator.shared
        
        setupSearchDebouncing()
        // Load cities in background without blocking UI
        Task.detached { [weak self] in
            await self?.loadInitialCities()
        }
    }
    
    // MARK: - PartyManager Update
    func updatePartyManager(_ newPartyManager: PartyManager) {
        self.partyManager = newPartyManager
    }
    
    // MARK: - AppNavigator Update
    func updateAppNavigator(_ newAppNavigator: AppNavigator) {
        self.appNavigator = newAppNavigator
    }
    
    // MARK: - Wizard Navigation Computed Properties
    
    var totalSteps: Int { CreatePartyStep.allCases.count }
    var stepIndex: Int { step.rawValue + 1 } // 1-based for UI
    var progress: Double { Double(stepIndex) / Double(totalSteps) }
    
    // MARK: - Wizard Navigation Methods
    
    func next() {
        if step != .review {
            step = CreatePartyStep(rawValue: step.rawValue + 1)!
        }
    }
    
    func back() {
        if step != .type {
            step = CreatePartyStep(rawValue: step.rawValue - 1)!
        }
    }
    
    func isCurrentStepValid() -> Bool {
        switch step {
        case .type:
            return !draft.partyType.isEmpty
        case .name:
            return !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .dates, .location, .vibe, .cover:
            return true // Optional steps
        case .review:
            return draft.isValid
        }
    }
    
    // MARK: - Computed Properties
    
    /// Form validation flags
    var isNameValid: Bool {
        draft.hasValidName
    }
    
    var isDatesValid: Bool {
        draft.hasValidDates
    }
    
    var isFormValid: Bool {
        draft.isValid
    }
    
    var showGuestOfHonorToggle: Bool {
        false // No longer needed - removed guest of honor question
    }
    
    var showCustomPartyTypeField: Bool {
        draft.partyType == "Other"
    }
    
    var dateValidationMessage: String? {
        if draft.startDate != nil || draft.endDate != nil {
            if draft.startDate == nil || draft.endDate == nil {
                return "Please select both a start and end date."
            }
            if !draft.hasValidDates {
                return "End date can't be before start date."
            }
        }
        return nil
    }
    
    // MARK: - Public Methods
    
    /// Updates party type and auto-fills name if empty
    func updatePartyType(_ newType: String) {
        draft.partyType = newType
        
        // Removed auto-fill behavior - let users enter their own party names
    }
    
    /// Updates custom party type and auto-fills name if needed
    func updateCustomPartyType(_ customType: String) {
        draft.customPartyType = customType
        
        // Removed auto-fill behavior - let users enter their own party names
    }
    
    /// Toggles a vibe tag
    func toggleVibeTag(_ tag: String) {
        if draft.vibeTags.contains(tag) {
            draft.vibeTags.removeAll { $0 == tag }
        } else {
            draft.vibeTags.append(tag)
        }
    }
    
    /// Loads the newly created party data into PartyManager
    private func loadNewlyCreatedParty(partyId: UUID) async {
        do {
            // Fetch the party data from the server
            let partyData = try await partyCreationService.fetchParty(partyId: partyId)
            
            // Load the data into PartyManager with admin role (since they're the creator)
            partyManager.load(from: partyData, role: "admin")
            
            print("✅ CreatePartyViewModel: Loaded newly created party data into PartyManager")
        } catch {
            print("❌ CreatePartyViewModel: Failed to load newly created party data: \(error)")
            // Don't fail the entire creation process for this
        }
    }
    
    /// Submits the party creation form (reused from original)
    func createParty() async {
        guard isFormValid && !isSubmitting && !partyCreatedSuccessfully else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            // 1. Upload cover image if selected
            if let coverImage = coverImage {
                do {
                    let imageURL = try await coverImageService.uploadImage(coverImage)
                    draft.coverImageURL = imageURL
                    print("✅ Cover image uploaded successfully: \(imageURL)")
                } catch {
                    print("⚠️ Cover image upload failed: \(error.localizedDescription)")
                    // Continue with party creation even if image upload fails
                }
            }
            
            // 2. Create the party
            let partyId = try await partyCreationService.createParty(from: draft)
            
            // 3. Special role assignment removed - no longer asking about guest of honor
            
            // 4. Load the newly created party data into PartyManager
            await loadNewlyCreatedParty(partyId: partyId)
            
            // 5. Set active party and navigate
            partyManager.partyId = partyId.uuidString
            
            // 5. Fire analytics (placeholder for now)
            fireAnalytics(partyId: partyId)
            
            // 6. Mark as successfully created and show success toast
            partyCreatedSuccessfully = true
            partyManager.partyCreatedSuccessfully = true
            showSuccessToast = true
            print("🎯 Party created successfully, setting showSuccessToast = true")
            
            // 7. Post notification to refresh dashboard first
            NotificationCenter.default.post(name: .refreshPartyData, object: nil)
            
            // 8. Add a small delay to ensure party data is loaded, then navigate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("🎯 CreatePartyViewModel: Navigating to party \(partyId.uuidString)")
                self.appNavigator.navigateToParty(partyId.uuidString, openChat: false)
                print("🎯 CreatePartyViewModel: Navigation call completed, route: \(self.appNavigator.route)")
            }
            
            // Reset submitting state after successful creation
            isSubmitting = false
            
        } catch {
            errorMessage = error.localizedDescription
            isSubmitting = false
        }
    }
    
    /// Submits the party creation form (legacy method for backward compatibility)
    func submit() async {
        await createParty()
    }
    
    // MARK: - Private Methods
    
    private func setupSearchDebouncing() {
        searchCancellable = $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                Task {
                    await self?.performCitySearch(query: query)
                }
            }
    }
    
    private func loadInitialCities() {
        Task {
            // Add a small delay to prevent blocking the UI during initialization
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await performCitySearch(query: "")
        }
    }
    
    private func performCitySearch(query: String) async {
        do {
            // Add timeout to prevent hanging
            let cities = try await withTimeout(seconds: 5) {
                try await self.citySearchService.searchCities(query: query)
            }
            availableCities = cities
        } catch {
            print("❌ City search failed: \(error)")
            // Don't show error to user for search failures
            // Set empty array to prevent UI issues
            availableCities = []
        }
    }
    
    // Helper function to add timeout to async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            
            group.cancelAll()
            return result
        }
    }
    // Simple timeout error
    private struct TimeoutError: Error {
        let message = "Operation timed out"
    }
    
    private func fireAnalytics(partyId: UUID) {
        // TODO: Implement analytics tracking
        let analyticsData: [String: Any] = [
            "party_id": partyId.uuidString,
            "party_name": draft.name,
            "has_start_date": draft.startDate != nil,
            "has_location": draft.cityId != nil,
            "location_country": availableCities.first { $0.id == draft.cityId }?.country ?? "unknown",
            "days_until_party": calculateDaysUntilParty(),
            "creator_id": SessionManager().currentUserId ?? "unknown",
            "party_type": draft.finalPartyType,
            "vibe_tags_count": draft.vibeTags.count
        ]
        
        print("📊 Analytics: created_party - \(analyticsData)")
    }
    
    private func calculateDaysUntilParty() -> Int {
        guard let startDate = draft.startDate else { return 0 }
        let calendar = Calendar.current
        let today = Date()
        let components = calendar.dateComponents([.day], from: today, to: startDate)
        return components.day ?? 0
    }
}
