//
//  EditPartyVibeSheet.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-01-30.
//

import SwiftUI

struct EditPartyVibeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var partyManager: PartyManager
    @State private var selectedTags: [String]
    @State private var isSaving = false
    
    let onSaved: () -> Void
    
    // Available vibe tags (exact same as create party wizard)
    static let vibeTags = [
        "Chill", "Lowkey", "Rowdy", "Wild", "Bougie", "Classy", "Luxury", "Nightlife",
        "Bar Crawl", "Pool", "Games", "Gambling", "Outdoorsy", "Athletic", "Adventure",
        "Sports", "Music", "Festival", "Foodie", "Dining", "Shopping", "Beach", "City",
        "Cabin", "Country", "Relax", "Wellness", "Bonding", "Celebrate"
    ]
    
    init(onSaved: @escaping () -> Void) {
        self.onSaved = onSaved
        // Initialize with current vibe tags
        self._selectedTags = State(initialValue: [])
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                // Description
                Text("Select tags that describe your trip")
                    .font(Typography.meta())
                    .foregroundColor(.metaGrey)
                

                
                // Available Tags Grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("Available Tags")
                        .font(.headline)
                        .foregroundColor(.titleDark)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(Self.vibeTags, id: \.self) { tag in
                            TagToggle(
                                tag: tag,
                                isSelected: selectedTags.contains(tag)
                            ) {
                                toggleTag(tag)
                            }
                            .opacity((selectedTags.count >= 5 && !selectedTags.contains(tag)) ? 0.5 : 1.0)
                            .disabled(selectedTags.count >= 5 && !selectedTags.contains(tag))
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Trip Vibe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.brandBlue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveVibeTags()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.brandBlue)
                    .disabled(selectedTags.isEmpty || isSaving)
                }
            }
        }
        .onAppear {
            // Load current vibe tags when sheet appears
            selectedTags = partyManager.vibeTags
        }
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.removeAll { $0 == tag }
        } else if selectedTags.count < 5 {
            selectedTags.append(tag)
        }
    }
    
    private func saveVibeTags() async {
        guard !selectedTags.isEmpty else { return }
        
        isSaving = true
        
        do {
            // Update the party manager
            partyManager.vibeTags = selectedTags
            
            // Save to database using PartyManagementService
            let service = PartyManagementService()
            let success = try await service.updateParty(
                partyId: partyManager.partyId,
                updates: ["party_vibe_tags": selectedTags]
            )
            
            if success {
                // Post notification to refresh party data
                NotificationCenter.default.post(name: .refreshPartyData, object: nil)
                
                // Call the onSaved callback
                onSaved()
                
                // Dismiss the sheet
                dismiss()
            } else {
                print("❌ Failed to save vibe tags")
            }
        } catch {
            print("❌ Error saving vibe tags: \(error)")
        }
        
        isSaving = false
    }
    

}



#Preview {
    EditPartyVibeSheet(onSaved: {})
        .environmentObject(PartyManager.mock)
}
