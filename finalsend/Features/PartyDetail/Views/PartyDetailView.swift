import SwiftUI
import Supabase

struct PartyDetailView: View {
    let partyId: String
    @Environment(\.dismiss) private var dismiss
    @State private var showEditThemeSheet = false
    @State private var showEditPartyDetailsSheet = false
    @State private var showEditCoverImageSheet = false
    @State private var showDeletePartyConfirmation = false
    @State private var isLoading = true
    
    // Pre-warm menu state to avoid first-touch hang
    @State private var isMenuPreWarmed = false

    @EnvironmentObject var partyManager: PartyManager
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var dataManager = PartyDataManager()

    var body: some View {
        ZStack {
            // Use party theme background instead of hardcoded color
            partyManager.currentTheme.cardBackgroundColor.ignoresSafeArea()

            if isLoading {
                // Show loading state while PartyManager loads
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Loading party...")
                        .foregroundColor(.white)
                        .padding(.top, 16)
                }
            } else {
                VStack(spacing: 0) {
                    // Navigation bar at the top - matching main view structure
                    ZStack {
                        // Center: Crew Logo (always centered)
                        Image("crew-wordmark")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 24)
                        
                        // Left: Back Button
                        HStack {
                            Button(action: {
                                print("🔙 Back button tapped - dismissing party detail")
                                // Post notification to dismiss the party detail view
                                NotificationCenter.default.post(name: Notification.Name("dismissPartyDetail"), object: nil)
                                dismiss()
                            }) {
                                Image(systemName: "arrowshape.backward.circle.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(Color(hex: "#353E3E"))
                            }
                            
                            Spacer()
                        }
                        
                        // Right: Settings Button (only show for admin/organizer)
                        HStack {
                            Spacer()
                            
                            if partyManager.isOrganizerOrAdmin {
                                Menu {
                                    Button("Edit Party Details") {
                                        print("🎯 Settings: Edit Party Details tapped")
                                        showEditPartyDetailsSheet = true
                                    }
                                    
                                    Button("Edit Cover Image") {
                                        print("🎯 Settings: Edit Cover Image tapped")
                                        showEditCoverImageSheet = true
                                    }
                                    
                                    Button("Edit Theme") {
                                        print("🎯 Settings: Edit Theme tapped")
                                        showEditThemeSheet = true
                                    }
                                    
                                    Divider()
                                    
                                    Button("Delete Party", role: .destructive) {
                                        print("🎯 Settings: Delete Party tapped")
                                        showDeletePartyConfirmation = true
                                    }
                                } label: {
                                    Image(systemName: "gearshape.circle.fill")
                                        .font(.system(size: 32, weight: .medium))
                                        .foregroundColor(Color(hex: "#353E3E"))
                                }
                                .onTapGesture {
                                    print("🎯 Settings: Menu gear icon tapped")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(partyManager.currentTheme.cardBackgroundColor)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.gray.opacity(0.2)),
                        alignment: .bottom
                    )
                    .zIndex(1) // Ensure navigation is above content
                    
                    // Direct PartyHubView without tab navigation
                    PartyHubView(partyId: partyId)
                        .environmentObject(partyManager)
                        .environmentObject(sessionManager)
                        .environmentObject(dataManager)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showEditThemeSheet) {
            EditThemeSheet(
                onSaved: {
                    NotificationCenter.default.post(name: .refreshPartyData, object: nil)
                }
            )
        }
        .sheet(isPresented: $showEditPartyDetailsSheet) {
            EditPartyDetailsSheet(
                onSaved: {
                    NotificationCenter.default.post(name: Notification.Name("refreshPartyData"), object: nil)
                }
            )
        }
        .sheet(isPresented: $showEditCoverImageSheet) {
            EditCoverImageSheet(
                onSaved: {
                    NotificationCenter.default.post(name: Notification.Name("refreshPartyData"), object: nil)
                }
            )
        }
        .sheet(isPresented: $showDeletePartyConfirmation) {
            DeletePartyConfirmationSheet(
                partyName: partyManager.name,
                onConfirm: {
                    Task {
                        await deleteParty()
                    }
                },
                onDismiss: {
                    showDeletePartyConfirmation = false
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dismissPartyDetail"))) { _ in
            print("🔙 Received dismiss notification - dismissing party detail")
            dismiss()
        }
        .onAppear {
            print("🎯 PartyDetailView appeared - PartyManager isLoaded: \(partyManager.isLoaded)")
            // Pre-warm menu to avoid first-touch hang
            preWarmMenu()
            // Wait for PartyManager to be loaded before showing content
            if partyManager.isLoaded {
                isLoading = false
            } else {
                // Keep showing the loading state until PartyManager reports loaded
                isLoading = true
            }
        }
        .onChange(of: partyManager.isLoaded) { isLoaded in
            print("🎯 PartyDetailView: PartyManager isLoaded changed to: \(isLoaded)")
            if isLoaded {
                isLoading = false
            }
        }
    }
    
    private func deleteParty() async {
        do {
            let partyManagementService = PartyManagementService()
            let success = try await partyManagementService.deleteParty(partyId: partyId)
            
            if success {
                print("✅ Party deleted successfully")
                // Navigate back to dashboard
                DispatchQueue.main.async {
                    AppNavigator.shared.navigateToDashboard()
                }
            } else {
                print("❌ Party deletion failed")
            }
        } catch {
            print("❌ Error deleting party: \(error)")
        }
    }
    
    private func preWarmMenu() {
        // Pre-warm the menu by accessing its properties to avoid first-touch compilation
        guard !isMenuPreWarmed else { return }
        
        // Force SwiftUI to compile the menu structure and related properties
        _ = partyManager.isOrganizerOrAdmin
        _ = showEditPartyDetailsSheet
        _ = showEditCoverImageSheet
        _ = showEditThemeSheet
        _ = showDeletePartyConfirmation
        
        isMenuPreWarmed = true
        print("🎯 PartyDetailView: Menu pre-warmed successfully")
    }
}
