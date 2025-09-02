import SwiftUI
import Supabase

struct PartyDetailView: View {
    let partyId: String
    @Environment(\.dismiss) private var dismiss
    @State private var showSettings = false
    @State private var showEditThemeSheet = false
    @State private var showEditPartyTypeSheet = false
    @State private var isLoading = true

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
                    // Navigation bar at the top
                    HStack {
                                            Button(action: {
                        print("🔙 Back button tapped - dismissing party detail")
                        // Post notification to dismiss the party detail view
                        NotificationCenter.default.post(name: Notification.Name("dismissPartyDetail"), object: nil)
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                        .padding(.leading, 20)
                        .padding(.top, 10)
                        
                        Spacer()
                        
                        // Settings dropdown menu (only show for admin/organizer)
                        if partyManager.isOrganizerOrAdmin {
                            Menu {
                                Button("Edit Party Details") {
                                    // TODO: Open edit party sheet
                                    print("Edit party details")
                                }
                                
                                Button("Edit Cover Image") {
                                    // TODO: Open cover image picker
                                    print("Edit cover image")
                                }
                                
                                Button("Edit Theme") {
                                    showEditThemeSheet = true
                                }
                                
                                Button("Edit Party Type") {
                                    showEditPartyTypeSheet = true
                                }
                                
                                Button("Manage Attendees") {
                                    // TODO: Navigate to crew management
                                    print("Manage attendees")
                                }
                                
                                Divider()
                                
                                Button("Delete Party", role: .destructive) {
                                    // TODO: Open delete confirmation
                                    print("Delete party")
                                }
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 20)
                            .padding(.top, 10)
                        }
                    }
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
        .sheet(isPresented: $showSettings) {
            PartySettingsSheet(onClose: nil)
                .environmentObject(partyManager)
        }
        .sheet(isPresented: $showEditThemeSheet) {
            EditThemeSheet(
                onSaved: {
                    NotificationCenter.default.post(name: .refreshPartyData, object: nil)
                }
            )
        }
        .sheet(isPresented: $showEditPartyTypeSheet) {
            EditPartyTypeSheet(
                onSaved: {
                    NotificationCenter.default.post(name: Notification.Name("refreshPartyData"), object: nil)
                }
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dismissPartyDetail"))) { _ in
            print("🔙 Received dismiss notification - dismissing party detail")
            dismiss()
        }
        .onAppear {
            print("🎯 PartyDetailView appeared - PartyManager isLoaded: \(partyManager.isLoaded)")
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
}
