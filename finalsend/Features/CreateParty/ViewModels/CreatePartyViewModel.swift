import Foundation
import Combine
import SwiftUI

// MARK: - Wizard Step Enum
enum CreatePartyStep: Int, CaseIterable {
    case type, name, dates, vibe, cover, review
}

@MainActor
class CreatePartyViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var draft = PartyDraft()
    @Published var isSubmitting = false
    @Published var availableCities: [CityModel] = []
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
        loadInitialCities()
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
        case .dates, .vibe, .cover:
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
            
            // 4. Set active party and navigate
            partyManager.partyId = partyId.uuidString
            
            // 5. Fire analytics (placeholder for now)
            fireAnalytics(partyId: partyId)
            
            // 6. Mark as successfully created and show success toast
            partyCreatedSuccessfully = true
            showSuccessToast = true
            print("🎯 Party created successfully, setting showSuccessToast = true")
            
            // 7. Navigate to the new party detail view
            appNavigator.navigateToParty(partyId.uuidString, openChat: false)
            
            // 8. Post notification to refresh dashboard
            NotificationCenter.default.post(name: .refreshPartyData, object: nil)
            
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
            await performCitySearch(query: "")
        }
    }
    
    private func performCitySearch(query: String) async {
        do {
            let cities = try await citySearchService.searchCities(query: query)
            availableCities = cities
        } catch {
            print("❌ City search failed: \(error)")
            // Don't show error to user for search failures
        }
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
