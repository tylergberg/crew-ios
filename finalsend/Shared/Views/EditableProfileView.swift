import SwiftUI
import Supabase
import AnyCodable
import UIKit

struct EditableProfileView: View {
    let profile: ProfileResponse
    let onProfileUpdated: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EditableProfileViewModel()
    @State private var showingDatePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    EditableProfileHeaderView(
                        profile: profile,
                        isLoading: false,
                        isUploading: viewModel.isUploadingAvatar,
                        onImageSelected: { image in
                            Task {
                                await viewModel.uploadAvatar(image)
                            }
                        },
                        onNameEdit: nil
                    )
                    
                    // Contact Information
                    SharedProfileSection(title: "Contact Information") {
                        EditableProfileRow(
                            icon: "person.fill",
                            label: "Full Name",
                            value: $viewModel.fullName,
                            placeholder: "Enter your full name"
                        )
                        

                        
                        EditableProfileRow(
                            icon: "house.fill",
                            label: "Home Address",
                            value: $viewModel.homeAddress,
                            placeholder: "Enter your home address",
                            isMultiline: true
                        )
                    }
                    
                    // Transportation
                    SharedProfileSection(title: "Transportation") {
                        EditableProfileRow(
                            icon: "car.fill",
                            label: "Has Car",
                            value: Binding(
                                get: { viewModel.hasCar ? "Yes" : "No" },
                                set: { viewModel.hasCar = $0.lowercased() == "yes" || $0.lowercased() == "true" }
                            ),
                            isToggle: true
                        )
                        
                        if viewModel.hasCar {
                            EditableProfileRow(
                                icon: "person.3.fill",
                                label: "Car Seat Count",
                                value: $viewModel.carSeatCount,
                                placeholder: "Enter number of seats",
                                keyboardType: .numberPad
                            )
                        }
                    }
                    
                    // Preferences
                    SharedProfileSection(title: "Preferences") {
                        EditableProfileRow(
                            icon: "cup.and.saucer.fill",
                            label: "Beverage Preferences",
                            value: $viewModel.beveragePreferences,
                            placeholder: "Enter your beverage preferences",
                            isMultiline: true
                        )
                        
                        // Dietary Preferences
                        EditableDietaryPreferencesField(
                            dietaryPreferences: $viewModel.dietaryPreferences
                        )
                    }
                    
                    // Personal Information
                    SharedProfileSection(title: "Personal Information") {
                        EditableProfileRow(
                            icon: "gift.fill",
                            label: "Birthday",
                            value: $viewModel.birthday,
                            placeholder: "Select your birthday",
                            isDate: true,
                            onDateTap: { showingDatePicker = true }
                        )
                        
                        EditableProfileRow(
                            icon: "star.fill",
                            label: "Fun Fact",
                            value: $viewModel.funStat,
                            placeholder: "Share something fun about yourself",
                            isMultiline: true
                        )
                        
                        // Clothing Sizes
                        EditableClothingSizesField(
                            clothingSizes: $viewModel.clothingSizes
                        )
                    }
                    
                    // Social Links
                    SharedProfileSection(title: "Social Links") {
                        EditableProfileRow(
                            icon: "link",
                            label: "LinkedIn URL",
                            value: $viewModel.linkedinUrl,
                            placeholder: "Enter your LinkedIn URL"
                        )
                        
                        EditableProfileRow(
                            icon: "camera.fill",
                            label: "Instagram Handle",
                            value: $viewModel.instagramHandle,
                            placeholder: "Enter your Instagram handle"
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.93, green: 0.51, blue: 0.25))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.saveProfile()
                            onProfileUpdated()
                            dismiss()
                        }
                    }
                    .foregroundColor(Color(red: 0.93, green: 0.51, blue: 0.25))
                    .disabled(viewModel.isSaving)
                }
            }
        }
        .onAppear {
            viewModel.onProfileUpdated = onProfileUpdated
            viewModel.loadProfile(profile)
        }
        .sheet(isPresented: $showingDatePicker) {
            BirthdayPickerSheet(
                selectedDate: $viewModel.birthday,
                isPresented: $showingDatePicker
            )
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Supporting Views

struct EditableProfileRow: View {
    let icon: String
    let label: String
    @Binding var value: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    let isMultiline: Bool
    let isToggle: Bool
    let isDate: Bool
    let onDateTap: (() -> Void)?
    
    init(
        icon: String,
        label: String,
        value: Binding<String>,
        placeholder: String = "",
        keyboardType: UIKeyboardType = .default,
        isMultiline: Bool = false,
        isToggle: Bool = false,
        isDate: Bool = false,
        onDateTap: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.label = label
        self._value = value
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.isMultiline = isMultiline
        self.isToggle = isToggle
        self.isDate = isDate
        self.onDateTap = onDateTap
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color.finalSendBlue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                if isToggle {
                    Toggle("", isOn: Binding(
                        get: { value.lowercased() == "yes" || value.lowercased() == "true" },
                        set: { value = $0 ? "Yes" : "No" }
                    ))
                    .labelsHidden()
                } else if isDate {
                    Button(action: { onDateTap?() }) {
                        HStack {
                            Text(value.isEmpty ? placeholder : value)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(value.isEmpty ? .secondary : .black)
                            Spacer()
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    if isMultiline {
                        TextField(placeholder, text: $value, axis: .vertical)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                            .lineLimit(3...6)
                    } else {
                        TextField(placeholder, text: $value)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                            .keyboardType(keyboardType)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct EditableDietaryPreferencesField: View {
    @Binding var dietaryPreferences: [String: AnyCodable]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dietary Preferences")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                EditablePreferenceField(
                    title: "Allergies",
                    value: Binding(
                        get: { 
                            if let allergies = dietaryPreferences["allergies"]?.value as? [String] {
                                return allergies.joined(separator: ", ")
                            }
                            return ""
                        },
                        set: { newValue in
                            let allergies = newValue.isEmpty ? [] : newValue.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) }
                            dietaryPreferences["allergies"] = AnyCodable(allergies)
                        }
                    ),
                    placeholder: "Enter allergies (comma separated)"
                )
                
                EditablePreferenceField(
                    title: "Dislikes",
                    value: Binding(
                        get: { 
                            if let dislikes = dietaryPreferences["dislikes"]?.value as? [String] {
                                return dislikes.joined(separator: ", ")
                            }
                            return ""
                        },
                        set: { newValue in
                            let dislikes = newValue.isEmpty ? [] : newValue.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) }
                            dietaryPreferences["dislikes"] = AnyCodable(dislikes)
                        }
                    ),
                    placeholder: "Enter foods you dislike (comma separated)"
                )
                
                EditablePreferenceField(
                    title: "Restrictions",
                    value: Binding(
                        get: { 
                            if let restrictions = dietaryPreferences["restrictions"]?.value as? [String] {
                                return restrictions.joined(separator: ", ")
                            }
                            return ""
                        },
                        set: { newValue in
                            let restrictions = newValue.isEmpty ? [] : newValue.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) }
                            dietaryPreferences["restrictions"] = AnyCodable(restrictions)
                        }
                    ),
                    placeholder: "Enter dietary restrictions (comma separated)"
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct EditableClothingSizesField: View {
    @Binding var clothingSizes: [String: AnyCodable]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clothing Sizes")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                EditablePreferenceField(
                    title: "T Shirt",
                    value: Binding(
                        get: { clothingSizes["tshirt"]?.value as? String ?? "" },
                        set: { clothingSizes["tshirt"] = AnyCodable($0) }
                    ),
                    placeholder: "Enter t-shirt size (e.g., S, M, L, XL)"
                )
                
                EditablePreferenceField(
                    title: "Sweater",
                    value: Binding(
                        get: { clothingSizes["sweater"]?.value as? String ?? "" },
                        set: { clothingSizes["sweater"] = AnyCodable($0) }
                    ),
                    placeholder: "Enter sweater size (e.g., S, M, L, XL)"
                )
                
                EditablePreferenceField(
                    title: "Sweatpants",
                    value: Binding(
                        get: { clothingSizes["sweatpants"]?.value as? String ?? "" },
                        set: { clothingSizes["sweatpants"] = AnyCodable($0) }
                    ),
                    placeholder: "Enter sweatpants size (e.g., S, M, L, XL)"
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct EditablePreferenceField: View {
    let title: String
    @Binding var value: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
                .textFieldStyle(PlainTextFieldStyle())
        }
    }
}

struct BirthdayPickerSheet: View {
    @Binding var selectedDate: String
    @Binding var isPresented: Bool
    
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select Birthday",
                    selection: $date,
                    displayedComponents: .date
                )
                .datePickerStyle(WheelDatePickerStyle())
                .padding()
                
                Spacer()
            }
            .navigationTitle("Select Birthday")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        selectedDate = formatter.string(from: date)
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            if !selectedDate.isEmpty {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                if let date = formatter.date(from: selectedDate) {
                    self.date = date
                }
            }
        }
    }
}

// MARK: - View Model

@MainActor
class EditableProfileViewModel: ObservableObject {
    @Published var fullName = ""

    @Published var homeAddress = ""
    @Published var hasCar = false
    @Published var carSeatCount = ""
    @Published var beveragePreferences = ""
    @Published var dietaryPreferences: [String: AnyCodable] = [:]
    @Published var clothingSizes: [String: AnyCodable] = [:]
    @Published var birthday = ""
    @Published var linkedinUrl = ""
    @Published var instagramHandle = ""
    @Published var funStat = ""
    
    @Published var isSaving = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isUploadingAvatar = false
    
    var onProfileUpdated: (() -> Void)?
    
    func loadProfile(_ profile: ProfileResponse) {
        fullName = profile.full_name ?? ""

        homeAddress = profile.home_address ?? ""
        hasCar = profile.has_car == true
        carSeatCount = profile.car_seat_count?.description ?? ""
        beveragePreferences = profile.beverage_preferences ?? ""
        dietaryPreferences = profile.dietary_preferences ?? [:]
        clothingSizes = profile.clothing_sizes ?? [:]
        birthday = profile.birthday ?? ""
        linkedinUrl = profile.linkedin_url ?? ""
        instagramHandle = profile.instagram_handle ?? ""
        funStat = profile.fun_stat ?? ""
    }
    
    func saveProfile() async {
        isSaving = true
        errorMessage = ""
        
        do {
            let client = SupabaseManager.shared.client
            
            struct UpdateProfileData: Encodable {
                let full_name: String?

                let home_address: String?
                let has_car: Bool
                let car_seat_count: Int?
                let beverage_preferences: String?
                let dietary_preferences: [String: AnyCodable]?
                let clothing_sizes: [String: AnyCodable]?
                let birthday: String?
                let linkedin_url: String?
                let instagram_handle: String?
                let fun_stat: String?
            }
            
            let updateData = UpdateProfileData(
                full_name: fullName.isEmpty ? nil : fullName,

                home_address: homeAddress.isEmpty ? nil : homeAddress,
                has_car: hasCar,
                car_seat_count: Int(carSeatCount),
                beverage_preferences: beveragePreferences.isEmpty ? nil : beveragePreferences,
                dietary_preferences: dietaryPreferences.isEmpty ? nil : dietaryPreferences,
                clothing_sizes: clothingSizes.isEmpty ? nil : clothingSizes,
                birthday: birthday.isEmpty ? nil : birthday,
                linkedin_url: linkedinUrl.isEmpty ? nil : linkedinUrl,
                instagram_handle: instagramHandle.isEmpty ? nil : instagramHandle,
                fun_stat: funStat.isEmpty ? nil : funStat
            )
            
            // Convert userId string to UUID for proper database comparison
            guard let userId = AuthManager.shared.currentUserId,
                  let userIdUUID = UUID(uuidString: userId) else {
                throw NSError(domain: "ProfileError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID format"])
            }
            
            try await client
                .from("profiles")
                .update(updateData)
                .eq("id", value: userIdUUID)
                .execute()
            
            isSaving = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isSaving = false
        }
    }
    
    func uploadAvatar(_ image: UIImage) async {
        isUploadingAvatar = true
        errorMessage = ""
        
        do {
            guard let userId = AuthManager.shared.currentUserId else {
                throw NSError(domain: "ProfileError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            _ = try await AvatarUploadService.shared.upload(image: image, for: userId)
            onProfileUpdated?()
            isUploadingAvatar = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isUploadingAvatar = false
        }
    }
}

// MARK: - Preview

#Preview {
    EditableProfileView(
        profile: ProfileResponse(
            id: "test",
            full_name: "Test User",
            avatar_url: nil,
            phone: "123-456-7890",
            email: "test@example.com",
            role: "user",
            home_address: "123 Main St",
            has_car: true,
            car_seat_count: 4,
            dietary_preferences: ["allergies": AnyCodable(["nuts"])],
            beverage_preferences: "Coffee",
            clothing_sizes: ["shirt": AnyCodable("M")],
            birthday: "January 1, 1990",
            linkedin_url: "https://linkedin.com/in/test",
            instagram_handle: "@testuser",
            fun_stat: "I love coding!",
            onboarding_stage: "done",
            onboarding_completed: true,
            tos_accepted_at: "2025-01-01T00:00:00Z",
            last_seen_at: "2025-01-01T00:00:00Z"
        ),
        onProfileUpdated: {}
    )
}
