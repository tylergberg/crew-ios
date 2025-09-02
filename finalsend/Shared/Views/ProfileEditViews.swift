import SwiftUI
import Supabase
import AnyCodable

// MARK: - Home Address Edit View

struct HomeAddressEditView: View {
    let currentAddress: String?
    let onSave: (String) -> Void
    
    @State private var address: String
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    init(currentAddress: String?, onSave: @escaping (String) -> Void) {
        self.currentAddress = currentAddress
        self.onSave = onSave
        self._address = State(initialValue: currentAddress ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Address Input
                    TextField("Enter your home address", text: $address, axis: .vertical)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#401B17")!)
                        .padding()
                        .background(Color(hex: "#F8F9FA")!)
                        .cornerRadius(12)
                        .lineLimit(3...6)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationTitle("Home Address")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#401B17")!)
                },
                trailing: Button("Save") {
                    handleSave()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#401B17")!)
                .disabled(isLoading || address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
    
    private func handleSave() {
        isLoading = true
        
        Task {
            do {
                guard let userId = AuthManager.shared.currentUserId else { return }
                
                let client = SupabaseManager.shared.client
                try await client
                    .from("profiles")
                    .update(["home_address": address.trimmingCharacters(in: .whitespacesAndNewlines)])
                    .eq("id", value: userId)
                    .execute()
                
                await MainActor.run {
                    onSave(address.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ Failed to update home address: \(error)")
                }
            }
        }
    }
}

// MARK: - Birthday Edit View

struct BirthdayEditView: View {
    let currentBirthday: String?
    let onSave: (String) -> Void
    
    @State private var selectedDate = Date()
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    init(currentBirthday: String?, onSave: @escaping (String) -> Void) {
        self.currentBirthday = currentBirthday
        self.onSave = onSave
        
        // Parse current birthday or use today's date
        if let birthday = currentBirthday {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            self._selectedDate = State(initialValue: formatter.date(from: birthday) ?? Date())
        } else {
            self._selectedDate = State(initialValue: Date())
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Date Picker
                    DatePicker(
                        "Select your birthday",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                    .background(Color(hex: "#F8F9FA")!)
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationTitle("Birthday")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#401B17")!)
                },
                trailing: Button("Save") {
                    handleSave()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#401B17")!)
                .disabled(isLoading)
            )
        }
    }
    
    private func handleSave() {
        isLoading = true
        
        Task {
            do {
                guard let userId = AuthManager.shared.currentUserId else { return }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let birthdayString = formatter.string(from: selectedDate)
                
                let client = SupabaseManager.shared.client
                try await client
                    .from("profiles")
                    .update(["birthday": birthdayString])
                    .eq("id", value: userId)
                    .execute()
                
                await MainActor.run {
                    onSave(birthdayString)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ Failed to update birthday: \(error)")
                }
            }
        }
    }
}

// MARK: - Fun Fact Edit View

struct FunFactEditView: View {
    let currentFunFact: String?
    let onSave: (String) -> Void
    
    @State private var funFact: String
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    init(currentFunFact: String?, onSave: @escaping (String) -> Void) {
        self.currentFunFact = currentFunFact
        self.onSave = onSave
        self._funFact = State(initialValue: currentFunFact ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Fun Fact Input
                    TextField("Share something fun about yourself", text: $funFact, axis: .vertical)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#401B17")!)
                        .padding()
                        .background(Color(hex: "#F8F9FA")!)
                        .cornerRadius(12)
                        .lineLimit(3...6)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationTitle("Fun Fact")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#401B17")!)
                },
                trailing: Button("Save") {
                    handleSave()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#401B17")!)
                .disabled(isLoading || funFact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
    
    private func handleSave() {
        isLoading = true
        
        Task {
            do {
                guard let userId = AuthManager.shared.currentUserId else { return }
                
                let client = SupabaseManager.shared.client
                try await client
                    .from("profiles")
                    .update(["fun_stat": funFact.trimmingCharacters(in: .whitespacesAndNewlines)])
                    .eq("id", value: userId)
                    .execute()
                
                await MainActor.run {
                    onSave(funFact.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ Failed to update fun fact: \(error)")
                }
            }
        }
    }
}

// MARK: - Transportation Edit View

struct TransportationEditView: View {
    let currentHasCar: Bool?
    let currentCarSeatCount: Int?
    let onSave: (Bool, Int?) -> Void
    
    @State private var hasCar: Bool
    @State private var carSeatCount: String
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    init(currentHasCar: Bool?, currentCarSeatCount: Int?, onSave: @escaping (Bool, Int?) -> Void) {
        self.currentHasCar = currentHasCar
        self.currentCarSeatCount = currentCarSeatCount
        self.onSave = onSave
        self._hasCar = State(initialValue: currentHasCar ?? false)
        self._carSeatCount = State(initialValue: currentCarSeatCount != nil ? "\(currentCarSeatCount!)" : "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Has Car Toggle
                    HStack {
                        Text("Do you have a car?")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#401B17")!)
                        
                        Spacer()
                        
                        Toggle("", isOn: $hasCar)
                            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#F9C94E")!))
                    }
                    .padding()
                    .background(Color(hex: "#F8F9FA")!)
                    .cornerRadius(12)
                    
                    // Car Seat Count (only show if has car)
                    if hasCar {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How many passengers can you fit?")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#401B17")!)
                            
                            TextField("Number of seats", text: $carSeatCount)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#401B17")!)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationTitle("Transportation")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#401B17")!)
                },
                trailing: Button("Save") {
                    handleSave()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#401B17")!)
                .disabled(isLoading)
            )
        }
    }
    
    private func handleSave() {
        isLoading = true
        
        Task<Void, Never> {
            do {
                guard let userId = AuthManager.shared.currentUserId else { return }
                
                var seatCount: Int? = nil
                if hasCar {
                    seatCount = Int(carSeatCount)
                }
                
                let client = SupabaseManager.shared.client
                
                // Update has_car first
                try await client
                    .from("profiles")
                    .update(["has_car": hasCar])
                    .eq("id", value: userId)
                    .execute()
                
                // Update car_seat_count separately
                if let seatCount = seatCount {
                    try await client
                        .from("profiles")
                        .update(["car_seat_count": seatCount])
                        .eq("id", value: userId)
                        .execute()
                } else {
                    // Set car_seat_count to null in database
                    try await client
                        .from("profiles")
                        .update(["car_seat_count": Optional<Int>.none])
                        .eq("id", value: userId)
                        .execute()
                }
                
                await MainActor.run {
                    onSave(hasCar, seatCount)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ Failed to update transportation: \(error)")
                }
            }
        }
    }
}

// MARK: - Beverage Preferences Edit View

struct BeveragePreferencesEditView: View {
    let currentPreferences: String?
    let onSave: (String) -> Void
    
    @State private var preferences: String
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    init(currentPreferences: String?, onSave: @escaping (String) -> Void) {
        self.currentPreferences = currentPreferences
        self.onSave = onSave
        self._preferences = State(initialValue: currentPreferences ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    TextField("What are your beverage preferences?", text: $preferences, axis: .vertical)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#401B17")!)
                        .padding()
                        .background(Color(hex: "#F8F9FA")!)
                        .cornerRadius(12)
                        .lineLimit(3...6)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationTitle("Beverage Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#401B17")!)
                },
                trailing: Button("Save") {
                    handleSave()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#401B17")!)
                .disabled(isLoading || preferences.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
    
    private func handleSave() {
        isLoading = true
        
        Task {
            do {
                guard let userId = AuthManager.shared.currentUserId else { return }
                
                let client = SupabaseManager.shared.client
                try await client
                    .from("profiles")
                    .update(["beverage_preferences": preferences.trimmingCharacters(in: .whitespacesAndNewlines)])
                    .eq("id", value: userId)
                    .execute()
                
                await MainActor.run {
                    onSave(preferences.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ Failed to update beverage preferences: \(error)")
                }
            }
        }
    }
}

// MARK: - Dietary Preferences Edit View

struct DietaryPreferencesEditView: View {
    let currentPreferences: [String: AnyCodable]?
    let onSave: ([String: AnyCodable]) -> Void
    
    @State private var allergies: String = ""
    @State private var dislikes: String = ""
    @State private var restrictions: String = ""
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    init(currentPreferences: [String: AnyCodable]?, onSave: @escaping ([String: AnyCodable]) -> Void) {
        self.currentPreferences = currentPreferences
        self.onSave = onSave
        
        // Initialize state from current preferences
        if let prefs = currentPreferences {
            if let allergiesArray = prefs["allergies"]?.value as? [String] {
                self._allergies = State(initialValue: allergiesArray.joined(separator: ", "))
            }
            if let dislikesArray = prefs["dislikes"]?.value as? [String] {
                self._dislikes = State(initialValue: dislikesArray.joined(separator: ", "))
            }
            if let restrictionsArray = prefs["restrictions"]?.value as? [String] {
                self._restrictions = State(initialValue: restrictionsArray.joined(separator: ", "))
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Allergies
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Allergies")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#5B626B")!)
                        
                        TextField("e.g., nuts, shellfish, dairy", text: $allergies)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#401B17")!)
                            .padding()
                            .background(Color(hex: "#F8F9FA")!)
                            .cornerRadius(12)
                    }
                    
                    // Dislikes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Food Dislikes")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#5B626B")!)
                        
                        TextField("e.g., mushrooms, olives, spicy food", text: $dislikes)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#401B17")!)
                            .padding()
                            .background(Color(hex: "#F8F9FA")!)
                            .cornerRadius(12)
                    }
                    
                    // Dietary Restrictions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dietary Restrictions")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#5B626B")!)
                        
                        TextField("e.g., vegetarian, gluten-free, keto", text: $restrictions)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#401B17")!)
                            .padding()
                            .background(Color(hex: "#F8F9FA")!)
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationTitle("Dietary Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#401B17")!)
                },
                trailing: Button("Save") {
                    handleSave()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#401B17")!)
                .disabled(isLoading)
            )
        }
    }
    
    private func handleSave() {
        isLoading = true
        
        Task {
            do {
                guard let userId = AuthManager.shared.currentUserId else { return }
                
                // Create dietary preferences dictionary
                var dietaryPreferences: [String: AnyCodable] = [:]
                
                let allergiesArray = allergies.trimmingCharacters(in: .whitespacesAndNewlines)
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !allergiesArray.isEmpty {
                    dietaryPreferences["allergies"] = AnyCodable(allergiesArray)
                }
                
                let dislikesArray = dislikes.trimmingCharacters(in: .whitespacesAndNewlines)
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !dislikesArray.isEmpty {
                    dietaryPreferences["dislikes"] = AnyCodable(dislikesArray)
                }
                
                let restrictionsArray = restrictions.trimmingCharacters(in: .whitespacesAndNewlines)
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                if !restrictionsArray.isEmpty {
                    dietaryPreferences["restrictions"] = AnyCodable(restrictionsArray)
                }
                
                let client = SupabaseManager.shared.client
                try await client
                    .from("profiles")
                    .update(["dietary_preferences": dietaryPreferences])
                    .eq("id", value: userId)
                    .execute()
                
                await MainActor.run {
                    onSave(dietaryPreferences)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ Failed to update dietary preferences: \(error)")
                }
            }
        }
    }
}

// MARK: - LinkedIn Edit View

struct LinkedInEditView: View {
    let currentLinkedIn: String?
    let onSave: (String) -> Void
    
    @State private var linkedInUrl: String
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    init(currentLinkedIn: String?, onSave: @escaping (String) -> Void) {
        self.currentLinkedIn = currentLinkedIn
        self.onSave = onSave
        self._linkedInUrl = State(initialValue: currentLinkedIn ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    TextField("Enter your LinkedIn URL", text: $linkedInUrl)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#401B17")!)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(hex: "#F8F9FA")!)
                        .cornerRadius(12)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationTitle("LinkedIn")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#401B17")!)
                },
                trailing: Button("Save") {
                    handleSave()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#401B17")!)
                .disabled(isLoading || linkedInUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
    
    private func handleSave() {
        isLoading = true
        
        Task {
            do {
                guard let userId = AuthManager.shared.currentUserId else { return }
                
                let client = SupabaseManager.shared.client
                try await client
                    .from("profiles")
                    .update(["linkedin_url": linkedInUrl.trimmingCharacters(in: .whitespacesAndNewlines)])
                    .eq("id", value: userId)
                    .execute()
                
                await MainActor.run {
                    onSave(linkedInUrl.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ Failed to update LinkedIn: \(error)")
                }
            }
        }
    }
}

// MARK: - Instagram Edit View

struct InstagramEditView: View {
    let currentInstagram: String?
    let onSave: (String) -> Void
    
    @State private var instagramHandle: String
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    init(currentInstagram: String?, onSave: @escaping (String) -> Void) {
        self.currentInstagram = currentInstagram
        self.onSave = onSave
        self._instagramHandle = State(initialValue: currentInstagram ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    TextField("Enter your Instagram handle", text: $instagramHandle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#401B17")!)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(hex: "#F8F9FA")!)
                        .cornerRadius(12)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationTitle("Instagram")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#401B17")!)
                },
                trailing: Button("Save") {
                    handleSave()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#401B17")!)
                .disabled(isLoading || instagramHandle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
    
    private func handleSave() {
        isLoading = true
        
        Task {
            do {
                guard let userId = AuthManager.shared.currentUserId else { return }
                
                let client = SupabaseManager.shared.client
                try await client
                    .from("profiles")
                    .update(["instagram_handle": instagramHandle.trimmingCharacters(in: .whitespacesAndNewlines)])
                    .eq("id", value: userId)
                    .execute()
                
                await MainActor.run {
                    onSave(instagramHandle.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ Failed to update Instagram: \(error)")
                }
            }
        }
    }
}

// MARK: - Clothing Sizes Edit View

struct ClothingSizesEditView: View {
    let currentSizes: [String: AnyCodable]?
    let onSave: ([String: String]) -> Void
    
    @State private var shirtSize: String = ""
    @State private var pantsSize: String = ""
    @State private var shoeSize: String = ""
    @State private var dressSize: String = ""
    @State private var hatSize: String = ""
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    init(currentSizes: [String: AnyCodable]?, onSave: @escaping ([String: String]) -> Void) {
        self.currentSizes = currentSizes
        self.onSave = onSave
        
        // Initialize state from current sizes
        if let sizes = currentSizes {
            self._shirtSize = State(initialValue: sizes["shirt"]?.value as? String ?? "")
            self._pantsSize = State(initialValue: sizes["pants"]?.value as? String ?? "")
            self._shoeSize = State(initialValue: sizes["shoes"]?.value as? String ?? "")
            self._dressSize = State(initialValue: sizes["dress"]?.value as? String ?? "")
            self._hatSize = State(initialValue: sizes["hat"]?.value as? String ?? "")
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Shirt Size
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shirt Size")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#5B626B")!)
                        
                        TextField("e.g., M, L, XL", text: $shirtSize)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#401B17")!)
                            .padding()
                            .background(Color(hex: "#F8F9FA")!)
                            .cornerRadius(12)
                    }
                    
                    // Pants Size
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pants Size")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#5B626B")!)
                        
                        TextField("e.g., 32x32, 34x30", text: $pantsSize)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#401B17")!)
                            .padding()
                            .background(Color(hex: "#F8F9FA")!)
                            .cornerRadius(12)
                    }
                    
                    // Shoe Size
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shoe Size")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#5B626B")!)
                        
                        TextField("e.g., 10, 10.5", text: $shoeSize)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#401B17")!)
                            .padding()
                            .background(Color(hex: "#F8F9FA")!)
                            .cornerRadius(12)
                    }
                    
                    // Dress Size
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dress Size")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#5B626B")!)
                        
                        TextField("e.g., 8, 10, 12", text: $dressSize)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#401B17")!)
                            .padding()
                            .background(Color(hex: "#F8F9FA")!)
                            .cornerRadius(12)
                    }
                    
                    // Hat Size
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hat Size")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "#5B626B")!)
                        
                        TextField("e.g., S, M, L, 7 1/4", text: $hatSize)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#401B17")!)
                            .padding()
                            .background(Color(hex: "#F8F9FA")!)
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationTitle("Clothing Sizes")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#401B17")!)
                },
                trailing: Button("Save") {
                    handleSave()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#401B17")!)
                .disabled(isLoading)
            )
        }
    }
    
    private func handleSave() {
        isLoading = true
        
        Task {
            do {
                guard let userId = AuthManager.shared.currentUserId else { return }
                
                // Create clothing sizes dictionary
                var clothingSizes: [String: String] = [:]
                if !shirtSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    clothingSizes["shirt"] = shirtSize.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                if !pantsSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    clothingSizes["pants"] = pantsSize.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                if !shoeSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    clothingSizes["shoes"] = shoeSize.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                if !dressSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    clothingSizes["dress"] = dressSize.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                if !hatSize.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    clothingSizes["hat"] = hatSize.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                let client = SupabaseManager.shared.client
                try await client
                    .from("profiles")
                    .update(["clothing_sizes": clothingSizes])
                    .eq("id", value: userId)
                    .execute()
                
                await MainActor.run {
                    onSave(clothingSizes)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    print("❌ Failed to update clothing sizes: \(error)")
                }
            }
        }
    }
}
