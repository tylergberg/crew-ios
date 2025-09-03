import SwiftUI
import Supabase
import AnyCodable
import UIKit
import StoreKit

extension Notification.Name {
    static let refreshTaskCount = Notification.Name("refreshTaskCount")
}

enum ProfileSheetType: Identifiable {
    case notificationCenter
    case debugTools
    
    var id: String {
        switch self {
        case .notificationCenter: return "notificationCenter"
        case .debugTools: return "debugTools"
        }
    }
}

struct UnifiedProfileView: View {
    let userId: String
    let partyContext: PartyContext?
    let isOwnProfile: Bool
    let crewService: CrewService?
    let onCrewDataUpdated: (() -> Void)?
    let showTaskManagement: Bool
    let useNavigationForTasks: Bool
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = UnifiedProfileViewModel()
    @State private var showingRsvpChange = false
    @State private var activeSheet: ProfileSheetType?
    @State private var unreadTaskCount = 0
    @State private var showingNotificationCenter = false
    @State private var showingPhoneNumberManagement = false
    @State private var showingPhoneNumberEdit = false
    @State private var showingHomeAddressEdit = false
    @State private var showingBirthdayEdit = false
    @State private var showingFunFactEdit = false
    @State private var showingTransportationEdit = false
    @State private var showingBeveragePreferencesEdit = false
    @State private var showingDietaryPreferencesEdit = false
    @State private var showingLinkedInEdit = false
    @State private var showingInstagramEdit = false
    @State private var showingClothingSizesEdit = false
    @State private var showingSettings = false
    @State private var showingNotificationSettings = false
    @State private var showingRoleChange = false
    @State private var showingSpecialRolePicker = false
    @State private var showingNameEdit = false
    @State private var showingEmailEdit = false

    
    var body: some View {
        Group {
            if useNavigationForTasks {
                // When using navigation for tasks, we're already in a NavigationView
                contentView
            } else {
                // When using modal presentation, we need our own NavigationStack
                NavigationStack {
                    contentView
                }
            }
        }
    }
    
    private var contentView: some View {
            ScrollView(.vertical, showsIndicators: false) {
                Color.neutralBackground.ignoresSafeArea()
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeaderView
                    
                    // Party Information (only in party context)
                    partyInformationView
                    
                    // Profile Information
                    profileInformationView
                    
                    // Management Section (for admins viewing others or own profile in party context)
                    if let partyContext = partyContext {
                        if !isOwnProfile && partyContext.canManageAttendee {
                            SharedProfileSection(title: "Management") {
                                SharedProfileRow(
                                    icon: "crown.fill",
                                    label: "Set Special Role",
                                    value: partyContext.specialRole?.capitalized ?? "None",
                                    isAction: true,
                                    actionColor: .purple,
                                    showChevron: true,
                                    onTap: {
                                        showingSpecialRolePicker = true
                                    }
                                )
                                
                                SharedProfileRow(
                                    icon: "person.2.fill",
                                    label: "Remove from Party",
                                    value: nil,
                                    isAction: true,
                                    actionColor: .red,
                                    showChevron: false,
                                    onTap: {
                                        viewModel.showRemoveConfirmation = true
                                    }
                                )
                            }
                        }
                    }
                    
                    // Settings (only for own profile in dashboard context)
                    if isOwnProfile && partyContext == nil {
                        SharedProfileSection(title: "Account") {
                            SharedProfileRow(
                                icon: "gearshape.fill",
                                label: "Settings",
                                value: nil,
                                isAction: true,
                                showChevron: true,
                                onTap: {
                                    showingSettings = true
                                }
                            )
                            
                            SharedProfileRow(
                                icon: "bell.fill",
                                label: "Notifications",
                                value: nil,
                                isAction: true,
                                showChevron: true,
                                onTap: {
                                    showingNotificationSettings = true
                                }
                            )
                        }
                        

                    }
                    
                    // Debug Tools (only in debug builds, only for own profile)
                    #if DEBUG
                    if isOwnProfile {
                        SharedProfileSection(title: "Debug Tools") {
                            SharedProfileRow(
                                icon: "wrench.and.screwdriver.fill",
                                label: "Session Debug",
                                value: nil,
                                isAction: true,
                                actionColor: .orange,
                                showChevron: false,
                                onTap: {
                                    activeSheet = .debugTools
                                }
                            )
                        }
                    }
                    #endif
                    

                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(!useNavigationForTasks) // Hide back button only in modal context
            .toolbar {
                // Show X button only in modal context (when useNavigationForTasks is false)
                if !useNavigationForTasks {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("✕") {
                            dismiss()
                        }
                        .foregroundColor(Color(red: 0.93, green: 0.51, blue: 0.25))
                        .font(.title2)
                        .fontWeight(.medium)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isOwnProfile && showTaskManagement {
                        Button(action: {
                            showingNotificationCenter = true
                        }) {
                            ZStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.green)
                                    .font(.title2)
                                
                                if unreadTaskCount > 0 {
                                    Text("\(unreadTaskCount)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                    }
                }
            }
        .onAppear {
            viewModel.crewService = crewService
            viewModel.loadProfile(userId: userId)
            
            // Load unread task count if task management is enabled
            if isOwnProfile && showTaskManagement {
                Task {
                    await loadUnreadTaskCount()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshTaskCount)) { _ in
            // Refresh task count when notification is received
            if isOwnProfile && showTaskManagement {
                Task {
                    await loadUnreadTaskCount()
                }
            }
        }
        .sheet(item: $activeSheet) { sheetType in
            switch sheetType {
            case .notificationCenter:
                EmptyView() // This is handled by fullScreenCover
            case .debugTools:
                NotificationTestView()
            }
        }
        .background(
            Group {
                if useNavigationForTasks {
                    NavigationLink(
                        destination: NotificationCenterView(),
                        isActive: $showingNotificationCenter,
                        label: { EmptyView() }
                    )
                } else {
                    EmptyView()
                }
            }
        )
        .fullScreenCover(isPresented: .constant(!useNavigationForTasks && showingNotificationCenter)) {
            NotificationCenterView()
        }
        .fullScreenCover(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView()
        }

        .fullScreenCover(isPresented: $showingPhoneNumberManagement) {
            PhoneNumberManagementView(
                currentProfilePhone: viewModel.profile?.phone,
                onPhoneUpdated: { _ in
                    viewModel.loadProfile(userId: userId)
                },
                currentPhone: viewModel.profile?.phone
            )
        }
        .fullScreenCover(isPresented: $showingPhoneNumberEdit) {
            PhoneNumberManagementView(
                currentProfilePhone: viewModel.profile?.phone,
                onPhoneUpdated: { _ in
                    viewModel.loadProfile(userId: userId)
                },
                currentPhone: viewModel.profile?.phone
            )
                .onDisappear {
                    // Refresh profile when phone number management is dismissed
                    viewModel.loadProfile(userId: userId)
                }
        }
        .fullScreenCover(isPresented: $showingHomeAddressEdit) {
            HomeAddressEditView(
                currentAddress: viewModel.profile?.home_address
            ) { newAddress in
                viewModel.loadProfile(userId: userId)
            }
        }
        .fullScreenCover(isPresented: $showingBirthdayEdit) {
            BirthdayEditView(
                currentBirthday: viewModel.profile?.birthday
            ) { newBirthday in
                viewModel.loadProfile(userId: userId)
            }
        }
        .fullScreenCover(isPresented: $showingFunFactEdit) {
            FunFactEditView(
                currentFunFact: viewModel.profile?.fun_stat
            ) { newFunFact in
                viewModel.loadProfile(userId: userId)
            }
        }
        .fullScreenCover(isPresented: $showingTransportationEdit) {
            TransportationEditView(
                currentHasCar: viewModel.profile?.has_car,
                currentCarSeatCount: viewModel.profile?.car_seat_count
            ) { hasCar, carSeatCount in
                viewModel.loadProfile(userId: userId)
            }
        }
        .fullScreenCover(isPresented: $showingBeveragePreferencesEdit) {
            BeveragePreferencesEditView(
                currentPreferences: viewModel.profile?.beverage_preferences
            ) { newPreferences in
                viewModel.loadProfile(userId: userId)
            }
        }
        .fullScreenCover(isPresented: $showingDietaryPreferencesEdit) {
            DietaryPreferencesEditView(
                currentPreferences: viewModel.profile?.dietary_preferences
            ) { newPreferences in
                viewModel.loadProfile(userId: userId)
            }
        }
        .fullScreenCover(isPresented: $showingLinkedInEdit) {
            LinkedInEditView(
                currentLinkedIn: viewModel.profile?.linkedin_url
            ) { newLinkedIn in
                viewModel.loadProfile(userId: userId)
            }
        }
        .fullScreenCover(isPresented: $showingInstagramEdit) {
            InstagramEditView(
                currentInstagram: viewModel.profile?.instagram_handle
            ) { newInstagram in
                viewModel.loadProfile(userId: userId)
            }
        }
        .fullScreenCover(isPresented: $showingClothingSizesEdit) {
            ClothingSizesEditView(
                currentSizes: viewModel.profile?.clothing_sizes
            ) { newSizes in
                viewModel.loadProfile(userId: userId)
            }
        }
        .fullScreenCover(isPresented: $showingEmailEdit) {
            EmailEditView(
                currentEmail: viewModel.profile?.email
            ) { newEmail in
                viewModel.loadProfile(userId: userId)
            }
        }
        .fullScreenCover(isPresented: $showingNameEdit) {
            NameEditView(
                currentName: viewModel.profile?.full_name
            ) { newName in
                viewModel.loadProfile(userId: userId)
            }
        }
        .alert("Remove Attendee", isPresented: $viewModel.showRemoveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                if let partyContext = partyContext {
                    Task {
                        await viewModel.removeAttendee(attendeeId: partyContext.attendeeId)
                        if viewModel.isAttendeeRemoved {
                            onCrewDataUpdated?()
                            dismiss()
                        }
                    }
                }
            }
        } message: {
            if let partyContext = partyContext {
                Text("Are you sure you want to remove \(partyContext.attendeeName) from this party? This action cannot be undone.")
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }

        .sheet(isPresented: $showingRsvpChange) {
            if let partyContext = partyContext {
                ChangeRsvpModal(
                    attendee: PartyAttendee(
                        id: partyContext.attendeeId,
                        userId: userId,
                        partyId: partyContext.partyId,
                        fullName: viewModel.profile?.full_name ?? "Unknown",
                        email: viewModel.profile?.email ?? "",
                        avatarUrl: viewModel.profile?.avatar_url,
                        role: partyContext.role,
                        rsvpStatus: partyContext.rsvpStatus,
                        specialRole: partyContext.specialRole,
                        invitedAt: nil,
                        respondedAt: nil,
                        isCurrentUser: isOwnProfile
                    ),
                    onChange: { newStatus in
                        Task {
                            let success = await (crewService ?? CrewService()).updateRsvpStatus(for: partyContext.attendeeId, to: newStatus)
                            if success {
                                NotificationCenter.default.post(name: .refreshPartyData, object: nil)
                                onCrewDataUpdated?()
                            }
                            dismiss()
                        }
                    },
                    onDismiss: { dismiss() }
                )
            }
        }
        .sheet(isPresented: $showingRoleChange) {
            if let partyContext = partyContext {
                ChangeRoleModal(
                    attendee: PartyAttendee(
                        id: partyContext.attendeeId,
                        userId: userId,
                        partyId: partyContext.partyId,
                        fullName: viewModel.profile?.full_name ?? "Unknown",
                        email: viewModel.profile?.email ?? "",
                        avatarUrl: viewModel.profile?.avatar_url,
                        role: partyContext.role,
                        rsvpStatus: partyContext.rsvpStatus,
                        specialRole: partyContext.specialRole,
                        invitedAt: nil,
                        respondedAt: nil,
                        isCurrentUser: isOwnProfile
                    ),
                    onChange: { _ in onCrewDataUpdated?(); dismiss() },
                    onDismiss: { dismiss() }
                )
            }
        }
        .sheet(isPresented: $showingSpecialRolePicker) {
            if let partyContext = partyContext {
                SetSpecialRoleModal(
                    attendee: PartyAttendee(
                        id: partyContext.attendeeId,
                        userId: userId,
                        partyId: partyContext.partyId,
                        fullName: viewModel.profile?.full_name ?? "Unknown",
                        email: viewModel.profile?.email ?? "",
                        avatarUrl: viewModel.profile?.avatar_url,
                        role: partyContext.role,
                        rsvpStatus: partyContext.rsvpStatus,
                        specialRole: partyContext.specialRole,
                        invitedAt: nil,
                        respondedAt: nil,
                        isCurrentUser: isOwnProfile
                    ),
                    crewService: crewService ?? CrewService(),
                    onSpecialRoleChanged: {
                        // Refresh crew data and dismiss
                        onCrewDataUpdated?()
                        dismiss()
                    }
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var profileHeaderView: some View {
        Group {
            if isOwnProfile {
                EditableProfileHeaderView(
                    profile: viewModel.profile,
                    isLoading: viewModel.isLoading,
                    isUploading: viewModel.isUploadingAvatar,
                    onImageSelected: { image in
                        Task {
                            await viewModel.uploadAvatar(image)
                        }
                    },
                    onNameEdit: {
                        showingNameEdit = true
                    }
                )
            } else {
                SharedProfileHeaderView(
                    profile: viewModel.profile,
                    isLoading: viewModel.isLoading
                )
            }
        }
    }
    
    private var partyInformationView: some View {
        Group {
            if let partyContext = partyContext {
                
                SharedProfileSection(title: "Party Information") {
                    SharedProfileRow(
                        icon: "person.badge.key.fill",
                        label: "Role",
                        value: partyContext.role.displayName,
                        isLink: false,
                        isAction: (isOwnProfile && partyContext.canChangeRole) || (!isOwnProfile && partyContext.canManageAttendee && partyContext.role != .admin),
                        valueColor: CrewUtilities.colorForRole(partyContext.role),
                        onTap: {
                            if (isOwnProfile && partyContext.canChangeRole) || (!isOwnProfile && partyContext.canManageAttendee && partyContext.role != .admin) {
                                showingRoleChange = true
                            }
                        }
                    )
                    
                    // Show special role if it exists (groom/bride highlighting)
                    if let specialRole = partyContext.specialRole, !specialRole.isEmpty {
                        let isGroomBride = specialRole.lowercased().contains("groom") || specialRole.lowercased().contains("bride")
                        let displayText = isGroomBride ? 
                            (specialRole.lowercased().contains("groom") ? "The Bachelor" : "The Bachelorette") :
                            specialRole.capitalized
                        
                        SharedProfileRow(
                            icon: "crown.fill",
                            label: "Special Role",
                            value: displayText,
                            isLink: false,
                            isAction: isOwnProfile,
                            valueColor: .purple,
                            onTap: {
                                if isOwnProfile {
                                    showingSpecialRolePicker = true
                                }
                            }
                        )
                    } else if isOwnProfile {
                        // Show option to set special role if user doesn't have one
                        SharedProfileRow(
                            icon: "crown.fill",
                            label: "Special Role",
                            value: "Set your special role",
                            isLink: false,
                            isAction: true,
                            actionColor: .purple,
                            showChevron: true,
                            onTap: {
                                showingSpecialRolePicker = true
                            }
                        )
                    }
                    
                    SharedProfileRow(
                        icon: "checkmark.circle.fill",
                        label: "RSVP Status",
                        value: partyContext.rsvpStatus.displayName,
                        isLink: false,
                        isAction: isOwnProfile,
                        valueColor: CrewUtilities.colorForRsvpStatus(partyContext.rsvpStatus),
                        onTap: {
                            if isOwnProfile {
                                showingRsvpChange = true
                            }
                        }
                    )
                }
            } else {
                EmptyView()
            }
        }
    }
    
    private var profileInformationView: some View {
        Group {
            if let profile = viewModel.profile {
                let hasPhone = profile.phone != nil && !profile.phone!.isEmpty
                let hasAddress = profile.home_address != nil && !profile.home_address!.isEmpty
                let hasContactInfo = hasPhone || hasAddress
                let hasTransportation = profile.has_car != nil
                let dietaryPrefs = formatDietaryPreferences(profile.dietary_preferences)
                let hasDietaryPrefs = !dietaryPrefs.isEmpty
                let hasBeveragePrefs = profile.beverage_preferences != nil && !profile.beverage_preferences!.isEmpty
                let hasPreferences = hasDietaryPrefs || hasBeveragePrefs
                let clothingSizes = formatClothingSizes(profile.clothing_sizes)
                let hasBirthday = profile.birthday != nil
                let hasFunStat = profile.fun_stat != nil && !profile.fun_stat!.isEmpty
                let hasClothingSizes = !clothingSizes.isEmpty
                let hasPersonalInfo = hasBirthday || hasFunStat || hasClothingSizes
                let hasLinkedIn = profile.linkedin_url != nil && !profile.linkedin_url!.isEmpty
                let hasInstagram = profile.instagram_handle != nil && !profile.instagram_handle!.isEmpty
                let hasSocialLinks = hasLinkedIn || hasInstagram
                
                VStack(spacing: 24) {
                    // Contact Information
                    if hasContactInfo || isOwnProfile {
                        SharedProfileSection(title: "Contact Information") {
                            if let phone = profile.phone, !phone.isEmpty {
                                SharedProfileRow(
                                    icon: "phone.fill", 
                                    label: "Phone", 
                                    value: phone,
                                    showChevron: isOwnProfile,
                                    onTap: {
                                        if isOwnProfile {
                                            showingPhoneNumberEdit = true
                                        }
                                    }
                                )
                            } else if isOwnProfile {
                                SharedProfileRow(
                                    icon: "phone.fill", 
                                    label: "Phone", 
                                    value: "Connect phone number", 
                                    valueColor: .secondary,
                                    showChevron: true,
                                    onTap: {
                                        showingPhoneNumberEdit = true
                                    }
                                )
                            }
                            if let email = profile.email, !email.isEmpty {
                                SharedProfileRow(
                                    icon: "envelope.fill", 
                                    label: "Email", 
                                    value: email,
                                    showChevron: isOwnProfile,
                                    onTap: {
                                        if isOwnProfile {
                                            showingEmailEdit = true
                                        }
                                    }
                                )
                            } else if isOwnProfile {
                                SharedProfileRow(
                                    icon: "envelope.fill", 
                                    label: "Email", 
                                    value: "Add email address", 
                                    valueColor: .secondary,
                                    showChevron: true,
                                    onTap: {
                                        showingEmailEdit = true
                                    }
                                )
                            }
                            if let homeAddress = profile.home_address, !homeAddress.isEmpty {
                                SharedProfileRow(
                                    icon: "house.fill", 
                                    label: "Home Address", 
                                    value: homeAddress,
                                    showChevron: isOwnProfile,
                                    onTap: {
                                        if isOwnProfile {
                                            showingHomeAddressEdit = true
                                        }
                                    }
                                )
                            } else if isOwnProfile {
                                SharedProfileRow(
                                    icon: "house.fill", 
                                    label: "Home Address", 
                                    value: "Add home address", 
                                    valueColor: .secondary,
                                    showChevron: true
                                ) {
                                    showingHomeAddressEdit = true
                                }
                            }
                        }
                    }
                    
                    // Transportation
                    if hasTransportation || isOwnProfile {
                        SharedProfileSection(title: "Transportation") {
                            if let hasCar = profile.has_car {
                                SharedProfileRow(
                                    icon: "car.fill",
                                    label: "Has Car",
                                    value: hasCar ? "Yes" : "No",
                                    showChevron: isOwnProfile
                                ) {
                                    if isOwnProfile {
                                        showingTransportationEdit = true
                                    }
                                }
                                if hasCar, let carSeatCount = profile.car_seat_count {
                                    SharedProfileRow(
                                        icon: "person.3.fill", 
                                        label: "Car Seat Count", 
                                        value: "\(carSeatCount)",
                                        showChevron: isOwnProfile
                                    ) {
                                        if isOwnProfile {
                                            showingTransportationEdit = true
                                        }
                                    }
                                }
                            } else if isOwnProfile {
                                SharedProfileRow(
                                    icon: "car.fill",
                                    label: "Has Car",
                                    value: "Add transportation info",
                                    valueColor: .secondary,
                                    showChevron: true
                                ) {
                                    showingTransportationEdit = true
                                }
                            }
                        }
                    }
                    
                    // Preferences
                    if hasPreferences || isOwnProfile {
                        SharedProfileSection(title: "Preferences") {
                            ForEach(dietaryPrefs, id: \.self) { pref in
                                SharedProfileRow(
                                    icon: "leaf.fill", 
                                    label: pref, 
                                    value: nil,
                                    showChevron: isOwnProfile
                                ) {
                                    if isOwnProfile {
                                        showingDietaryPreferencesEdit = true
                                    }
                                }
                            }
                            if let beveragePrefs = profile.beverage_preferences, !beveragePrefs.isEmpty {
                                SharedProfileRow(
                                    icon: "cup.and.saucer.fill", 
                                    label: "Beverage Preferences", 
                                    value: beveragePrefs,
                                    showChevron: isOwnProfile
                                ) {
                                    if isOwnProfile {
                                        showingBeveragePreferencesEdit = true
                                    }
                                }
                            } else if isOwnProfile {
                                SharedProfileRow(
                                    icon: "cup.and.saucer.fill", 
                                    label: "Beverage Preferences", 
                                    value: "Add beverage preferences", 
                                    valueColor: .secondary,
                                    showChevron: true
                                ) {
                                    showingBeveragePreferencesEdit = true
                                }
                            }
                            if dietaryPrefs.isEmpty && isOwnProfile {
                                SharedProfileRow(
                                    icon: "leaf.fill", 
                                    label: "Dietary Preferences", 
                                    value: "Add dietary preferences", 
                                    valueColor: .secondary,
                                    showChevron: true
                                ) {
                                    showingDietaryPreferencesEdit = true
                                }
                            }
                        }
                    }
                    
                    // Personal Information
                    if hasPersonalInfo || isOwnProfile {
                        SharedProfileSection(title: "Personal Information") {
                            if let birthday = profile.birthday {
                                SharedProfileRow(
                                    icon: "gift.fill", 
                                    label: "Birthday", 
                                    value: birthday,
                                    showChevron: isOwnProfile
                                ) {
                                    if isOwnProfile {
                                        showingBirthdayEdit = true
                                    }
                                }
                            } else if isOwnProfile {
                                SharedProfileRow(
                                    icon: "gift.fill", 
                                    label: "Birthday", 
                                    value: "Add birthday", 
                                    valueColor: .secondary,
                                    showChevron: true
                                ) {
                                    showingBirthdayEdit = true
                                }
                            }
                            if let funStat = profile.fun_stat, !funStat.isEmpty {
                                SharedProfileRow(
                                    icon: "star.fill", 
                                    label: "Fun Fact", 
                                    value: funStat,
                                    showChevron: isOwnProfile
                                ) {
                                    if isOwnProfile {
                                        showingFunFactEdit = true
                                    }
                                }
                            } else if isOwnProfile {
                                SharedProfileRow(
                                    icon: "star.fill", 
                                    label: "Fun Fact", 
                                    value: "Add fun fact", 
                                    valueColor: .secondary,
                                    showChevron: true
                                ) {
                                    showingFunFactEdit = true
                                }
                            }
                            ForEach(clothingSizes, id: \.self) { size in
                                SharedProfileRow(
                                    icon: "tshirt.fill", 
                                    label: size, 
                                    value: nil,
                                    showChevron: isOwnProfile
                                ) {
                                    if isOwnProfile {
                                        showingClothingSizesEdit = true
                                    }
                                }
                            }
                            if clothingSizes.isEmpty && isOwnProfile {
                                SharedProfileRow(
                                    icon: "tshirt.fill", 
                                    label: "Clothing Sizes", 
                                    value: "Add clothing sizes", 
                                    valueColor: .secondary,
                                    showChevron: true
                                ) {
                                    showingClothingSizesEdit = true
                                }
                            }
                        }
                    }
                    
                    // Social Links
                    if hasSocialLinks || isOwnProfile {
                        SharedProfileSection(title: "Social Links") {
                            if let linkedin = profile.linkedin_url, !linkedin.isEmpty {
                                SharedProfileRow(
                                    icon: "link", 
                                    label: "LinkedIn", 
                                    value: linkedin, 
                                    isLink: true,
                                    showChevron: isOwnProfile,
                                    showExternalLinkArrow: !isOwnProfile
                                ) {
                                    if isOwnProfile {
                                        showingLinkedInEdit = true
                                    }
                                }
                            } else if isOwnProfile {
                                SharedProfileRow(
                                    icon: "link", 
                                    label: "LinkedIn", 
                                    value: "Add LinkedIn URL", 
                                    valueColor: .secondary,
                                    showChevron: true
                                ) {
                                    showingLinkedInEdit = true
                                }
                            }
                            if let instagram = formatInstagramHandle(profile.instagram_handle), !instagram.isEmpty {
                                SharedProfileRow(
                                    icon: "camera.fill", 
                                    label: "Instagram", 
                                    value: instagram, 
                                    isLink: true,
                                    showChevron: isOwnProfile,
                                    showExternalLinkArrow: !isOwnProfile
                                ) {
                                    if isOwnProfile {
                                        showingInstagramEdit = true
                                    }
                                }
                            } else if isOwnProfile {
                                SharedProfileRow(
                                    icon: "camera.fill", 
                                    label: "Instagram", 
                                    value: "Add Instagram handle", 
                                    valueColor: .secondary,
                                    showChevron: true
                                ) {
                                    showingInstagramEdit = true
                                }
                            }
                        }
                    }
                }
            } else {
                EmptyView()
            }
        }
    }
    

    
    // MARK: - Helper Methods
    
    private func formatDietaryPreferences(_ preferences: [String: AnyCodable]?) -> [String] {
        guard let preferences = preferences else { return [] }
        
        var formattedParts: [String] = []
        
        // Only show expected dietary preference keys
        let expectedKeys = ["allergies", "dislikes", "restrictions"]
        
        for (key, value) in preferences {
            // Only process expected keys
            guard expectedKeys.contains(key) else { continue }
            
            if let stringValue = value.value as? String {
                formattedParts.append("\(key.capitalized): \(stringValue)")
            } else if let arrayValue = value.value as? [String] {
                if !arrayValue.isEmpty {
                    formattedParts.append("\(key.capitalized): \(arrayValue.joined(separator: ", "))")
                }
            }
        }
        
        return formattedParts
    }
    
    private func formatClothingSizes(_ sizes: [String: AnyCodable]?) -> [String] {
        guard let sizes = sizes else { return [] }
        
        var formattedParts: [String] = []
        
        for (key, value) in sizes {
            if let stringValue = value.value as? String {
                formattedParts.append("\(key.capitalized): \(stringValue)")
            } else if let arrayValue = value.value as? [String] {
                if !arrayValue.isEmpty {
                    formattedParts.append("\(key.capitalized): \(arrayValue.joined(separator: ", "))")
                }
            }
        }
        
        return formattedParts
    }
    
    private func loadUnreadTaskCount() async {
        do {
            let service = NotificationCenterService()
            unreadTaskCount = try await service.getUnreadTaskCount()
        } catch {
            print("❌ Failed to load unread task count: \(error)")
        }
    }
    
    private func formatInstagramHandle(_ handle: String?) -> String? {
        guard let handle = handle, !handle.isEmpty else { return nil }
        
        let formattedUrl: String
        if handle.hasPrefix("http") {
            formattedUrl = handle
        } else if handle.hasPrefix("@") {
            formattedUrl = "https://instagram.com/\(String(handle.dropFirst()))"
        } else {
            formattedUrl = "https://instagram.com/\(handle)"
        }
        
        print("📸 Instagram handle: '\(handle)' -> URL: '\(formattedUrl)'")
        return formattedUrl
    }
}

// MARK: - Placeholder Edit Views



struct HomeAddressEditPlaceholderView: View {
    let currentAddress: String?
    let onSave: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Home Address Edit")
                    .font(.title)
                Text("Placeholder - Implement actual address editing")
                    .foregroundColor(.secondary)
                Button("Done") {
                    onSave(currentAddress ?? "")
                    dismiss()
                }
            }
        }
    }
}

struct BirthdayEditPlaceholderView: View {
    let currentBirthday: String?
    let onSave: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Birthday Edit")
                    .font(.title)
                Text("Placeholder - Implement actual birthday editing")
                    .foregroundColor(.secondary)
                Button("Done") {
                    onSave(currentBirthday ?? "")
                    dismiss()
                }
            }
        }
    }
}

struct FunFactEditPlaceholderView: View {
    let currentFunFact: String?
    let onSave: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Fun Fact Edit")
                    .font(.title)
                Text("Placeholder - Implement actual fun fact editing")
                    .foregroundColor(.secondary)
                Button("Done") {
                    onSave(currentFunFact ?? "")
                    dismiss()
                }
            }
        }
    }
}

struct TransportationEditPlaceholderView: View {
    let currentHasCar: Bool?
    let currentCarSeatCount: Int?
    let onSave: (Bool, Int?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Transportation Edit")
                    .font(.title)
                Text("Placeholder - Implement actual transportation editing")
                    .foregroundColor(.secondary)
                Button("Done") {
                    onSave(currentHasCar ?? false, currentCarSeatCount)
                    dismiss()
                }
            }
        }
    }
}

struct BeveragePreferencesEditPlaceholderView: View {
    let currentPreferences: String?
    let onSave: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Beverage Preferences Edit")
                    .font(.title)
                Text("Placeholder - Implement actual beverage preferences editing")
                    .foregroundColor(.secondary)
                Button("Done") {
                    onSave(currentPreferences ?? "")
                    dismiss()
                }
            }
        }
    }
}

struct LinkedInEditPlaceholderView: View {
    let currentLinkedIn: String?
    let onSave: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("LinkedIn Edit")
                    .font(.title)
                Text("Placeholder - Implement actual LinkedIn editing")
                    .foregroundColor(.secondary)
                Button("Done") {
                    onSave(currentLinkedIn ?? "")
                    dismiss()
                }
            }
        }
    }
}

struct InstagramEditPlaceholderView: View {
    let currentInstagram: String?
    let onSave: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Instagram Edit")
                    .font(.title)
                Text("Placeholder - Implement actual Instagram editing")
                    .foregroundColor(.secondary)
                Button("Done") {
                    onSave(currentInstagram ?? "")
                    dismiss()
                }
            }
        }
    }
}



// MARK: - Data Models

struct PartyContext {
    let role: UserRole
    let rsvpStatus: RsvpStatus
    let attendeeName: String
    let attendeeId: UUID
    let canChangeRole: Bool
    let canManageAttendee: Bool
    let partyId: String
    let specialRole: String?
}

// MARK: - View Model

@MainActor
class UnifiedProfileViewModel: ObservableObject {
    @Published var profile: ProfileResponse?
    @Published var isLoading = true
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isUploadingAvatar = false
    @Published var showRemoveConfirmation = false
    @Published var isAttendeeRemoved = false
    
    private let authManager = AuthManager.shared
    var crewService: CrewService?
    
    func loadProfile(userId: String) {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let client = SupabaseManager.shared.client
                
                // Convert userId string to UUID for proper database comparison
                print("👤 UnifiedProfileViewModel.loadProfile starting for userId: \(userId)")
                guard let userIdUUID = UUID(uuidString: userId) else {
                    throw NSError(domain: "ProfileError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID format"])
                }
                print("👤 UnifiedProfileViewModel.loadProfile parsed UUID: \(userIdUUID)")
                
                let response: PostgrestResponse<ProfileResponse> = try await client
                    .from("profiles")
                    .select("id, full_name, avatar_url, phone, email, role, home_address, has_car, car_seat_count, dietary_preferences, beverage_preferences, clothing_sizes, birthday, linkedin_url, instagram_handle, fun_stat")
                    .eq("id", value: userIdUUID)
                    .single()
                    .execute()

                self.profile = response.value
                self.isLoading = false
                print("👤 UnifiedProfileViewModel.loadProfile loaded profile for id: \(response.value.id ?? "<nil>") name: \(response.value.full_name ?? "<nil>")")
            } catch {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
                print("❌ UnifiedProfileViewModel.loadProfile error: \(error)")
            }
        }
    }
    
    func refreshProfile() {
        if let profile = profile {
            loadProfile(userId: profile.id ?? "")
        }
    }
    
    func loadProfile() {
        if let profile = profile {
            loadProfile(userId: profile.id ?? "")
        }
    }
    
    func signOut() async {
        // Set logout flag immediately to prevent any database queries
        authManager.isLoggingOut = true
        await authManager.logout()
    }
    
    func uploadAvatar(_ image: UIImage) async {
        isUploadingAvatar = true
        errorMessage = ""
        
        do {
            guard let userId = AuthManager.shared.currentUserId else {
                throw NSError(domain: "ProfileError", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
            }
            
            _ = try await AvatarUploadService.shared.upload(image: image, for: userId)
            refreshProfile()
            isUploadingAvatar = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isUploadingAvatar = false
        }
    }
    
    func removeAttendee(attendeeId: UUID) async {
        guard let crewService = crewService else { return }
        
        let success = await crewService.removeAttendee(attendeeId)
        
        if success {
            isAttendeeRemoved = true
        } else {
            errorMessage = crewService.errorMessage ?? "Failed to remove attendee"
            showError = true
        }
    }
    

}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = UnifiedProfileViewModel()
    @State private var showingNotifications = false
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // About Section
                    VStack(spacing: 0) {
                        // Instagram
                        Button(action: {
                            // TODO: Open Instagram
                        }) {
                            HStack {
                                Image(systemName: "camera")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(hex: "#401B17")!)
                                    .frame(width: 24)
                                
                                Text("Instagram")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "#401B17")!)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#5B626B")!)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                        }
                        
                        Divider()
                            .padding(.leading, 68)
                        
                        // Twitter
                        Button(action: {
                            // TODO: Open Twitter
                        }) {
                            HStack {
                                Image(systemName: "bird")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(hex: "#401B17")!)
                                    .frame(width: 24)
                                
                                Text("Twitter")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "#401B17")!)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#5B626B")!)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                        }
                        
                        Divider()
                            .padding(.leading, 68)
                        
                        // LinkedIn
                        Button(action: {
                            // TODO: Open LinkedIn
                        }) {
                            HStack {
                                Image(systemName: "link")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(hex: "#401B17")!)
                                    .frame(width: 24)
                                
                                Text("LinkedIn")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "#401B17")!)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#5B626B")!)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                        }
                        
                        Divider()
                            .padding(.leading, 68)
                        
                        // Website
                        Button(action: {
                            // TODO: Open Website
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(hex: "#401B17")!)
                                    .frame(width: 24)
                                
                                Text("Website")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "#401B17")!)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#5B626B")!)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    
                    // Support Section
                    VStack(spacing: 0) {
                        // Help & Support
                        Button(action: {
                            // TODO: Add support contact
                        }) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(hex: "#401B17")!)
                                    .frame(width: 24)
                                
                                Text("Help & Support")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "#401B17")!)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#5B626B")!)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                        }
                        
                        Divider()
                            .padding(.leading, 68)
                        
                        // Leave us a review
                        Button(action: {
                            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                SKStoreReviewController.requestReview(in: scene)
                            }
                        }) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(hex: "#401B17")!)
                                    .frame(width: 24)
                                
                                Text("Leave us a review")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "#401B17")!)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#5B626B")!)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                        }
                        
                        Divider()
                            .padding(.leading, 68)
                        
                        // Privacy Policy
                        Button(action: {
                            // TODO: Add privacy policy
                        }) {
                            HStack {
                                Image(systemName: "hand.raised")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(hex: "#401B17")!)
                                    .frame(width: 24)
                                
                                Text("Privacy Policy")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "#401B17")!)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#5B626B")!)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                        }
                        
                        Divider()
                            .padding(.leading, 68)
                        
                        // Terms of Service
                        Button(action: {
                            // TODO: Add terms of service
                        }) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(hex: "#401B17")!)
                                    .frame(width: 24)
                                
                                Text("Terms of Service")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(hex: "#401B17")!)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#5B626B")!)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.white)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    
                    Spacer()
                    
                    // Delete Account Button (at bottom)
                    Button(action: {
                        // TODO: Implement delete account functionality
                        print("Delete account tapped - not yet implemented")
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.red)
                                .frame(width: 24)
                            
                            Text("Delete Account")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    
                    // Sign Out Button (at bottom)
                    Button(action: {
                        Task {
                            await viewModel.signOut()
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.red)
                                .frame(width: 24)
                            
                            Text("Sign Out")
                                .font(.callout.weight(.medium))
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(Radius.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.card)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.neutralBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.callout.weight(.medium))
                        .foregroundColor(.brandBlue)
                }
            )
        }
    }
}

// MARK: - Set Special Role Modal

struct SetSpecialRoleModal: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: SetSpecialRoleModalViewModel
    let attendee: PartyAttendee
    let onSpecialRoleChanged: () -> Void
    
    init(attendee: PartyAttendee, crewService: CrewService, onSpecialRoleChanged: @escaping () -> Void) {
        self.attendee = attendee
        self.onSpecialRoleChanged = onSpecialRoleChanged
        self._viewModel = StateObject(wrappedValue: SetSpecialRoleModalViewModel(crewService: crewService))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Set Special Role")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.titleDark)
                    
                    if attendee.isCurrentUser {
                        Text("Set your special role for this party")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Set special role for \(attendee.fullName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 20)
                
                // Current Special Role
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Special Role")
                        .font(.headline)
                        .foregroundColor(.titleDark)
                    
                    HStack {
                        Text(attendee.specialRole?.capitalized ?? "None")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(attendee.specialRole != nil ? .purple : .gray)
                            )
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                
                // Special Role Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Special Role")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    VStack(spacing: 8) {
                        ForEach(SpecialRoleOption.allCases, id: \.self) { option in
                            Button(action: {
                                viewModel.selectedSpecialRole = option
                            }) {
                                HStack {
                                    Text(option.displayName)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    if viewModel.selectedSpecialRole == option {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.purple)
                                            .font(.system(size: 18, weight: .medium))
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 18, weight: .medium))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(viewModel.selectedSpecialRole == option ? Color.purple.opacity(0.1) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(viewModel.selectedSpecialRole == option ? Color.purple : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await viewModel.setSpecialRole(for: attendee.id)
                            if viewModel.isSpecialRoleUpdated {
                                onSpecialRoleChanged()
                                dismiss()
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            Text(viewModel.isLoading ? "Updating..." : "Update Special Role")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.canUpdateSpecialRole ? Color.purple : Color.gray)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.black, lineWidth: 2)
                        )
                    }
                    .disabled(!viewModel.canUpdateSpecialRole || viewModel.isLoading)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(red: 0.99, green: 0.95, blue: 0.91))
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.selectedSpecialRole = SpecialRoleOption.fromString(attendee.specialRole)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

enum SpecialRoleOption: String, CaseIterable {
    case none = ""
    case groom = "groom"
    case bride = "bride"
    
    var displayName: String {
        switch self {
        case .none:
            return "No Special Role"
        case .groom:
            return "The Bachelor"
        case .bride:
            return "The Bachelorette"
        }
    }
    
    static func fromString(_ string: String?) -> SpecialRoleOption {
        guard let string = string, !string.isEmpty else { return .none }
        
        switch string.lowercased() {
        case "groom":
            return .groom
        case "bride":
            return .bride
        default:
            return .none
        }
    }
}

@MainActor
class SetSpecialRoleModalViewModel: ObservableObject {
    @Published var selectedSpecialRole: SpecialRoleOption = .none
    @Published var isLoading = false
    @Published var isSpecialRoleUpdated = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let crewService: CrewService
    
    init(crewService: CrewService) {
        self.crewService = crewService
    }
    
    var canUpdateSpecialRole: Bool {
        !isLoading
    }
    
    func setSpecialRole(for attendeeId: UUID) async {
        isLoading = true
        isSpecialRoleUpdated = false
        
        let specialRoleString = selectedSpecialRole == .none ? nil : selectedSpecialRole.rawValue
        let success = await crewService.setSpecialRole(for: attendeeId, specialRole: specialRoleString)
        
        if success {
            isSpecialRoleUpdated = true
        } else {
            errorMessage = crewService.errorMessage ?? "Failed to update special role"
            showError = true
        }
        
        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    UnifiedProfileView(
        userId: "test-user-id",
        partyContext: nil,
        isOwnProfile: true,
        crewService: nil,
        onCrewDataUpdated: nil,
        showTaskManagement: true,
        useNavigationForTasks: true
    )
}

