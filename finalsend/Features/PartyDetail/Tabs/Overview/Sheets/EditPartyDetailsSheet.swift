//
//  EditPartyDetailsSheet.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-01-27.
//

import SwiftUI

struct EditPartyDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var partyManager: PartyManager
    
    let onSaved: () -> Void
    private let partyManagementService = PartyManagementService()
    
    @State private var partyName: String = ""
    @State private var partyDescription: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit Party Details")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.titleDark)
                    
                    Text("Update your party information")
                        .font(.subheadline)
                        .foregroundColor(.metaGrey)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Form
                ScrollView {
                    VStack(spacing: 24) {
                        // Party Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Party Name")
                                .font(.headline)
                                .foregroundColor(.titleDark)
                            
                            TextField("Enter party name", text: $partyName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                        
                        // Party Description (Optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (Optional)")
                                .font(.headline)
                                .foregroundColor(.titleDark)
                            
                            TextField("Enter party description", text: $partyDescription, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                                .lineLimit(3...6)
                        }
                        
                        // Error Message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
                
                Spacer()
                
                // Save Button
                VStack(spacing: 16) {
                    Button(action: savePartyDetails) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Save Changes")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(partyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.brandBlue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(partyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.brandBlue)
                }
            }
        }
        .onAppear {
            // Initialize with current values
            partyName = partyManager.name
            partyDescription = partyManager.description
        }
    }
    
    private func savePartyDetails() {
        guard !partyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSaving = true
        errorMessage = ""
        
        Task {
            do {
                // Prepare updates - only include non-empty values
                var updates: [String: Any] = [
                    "name": partyName.trimmingCharacters(in: .whitespacesAndNewlines)
                ]
                
                // Include description (empty string if cleared by user)
                let trimmedDescription = partyDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                updates["description"] = trimmedDescription
                
                // Save to database
                let success = try await partyManagementService.updateParty(partyId: partyManager.partyId, updates: updates)
                
                if success {
                    // Update the party manager
                    partyManager.name = partyName.trimmingCharacters(in: .whitespacesAndNewlines)
                    partyManager.description = trimmedDescription.isEmpty ? "" : trimmedDescription
                    
                    // Call the onSaved callback
                    onSaved()
                    
                    // Dismiss the sheet
                    await MainActor.run {
                        dismiss()
                    }
                } else {
                    // Handle failure
                    await MainActor.run {
                        errorMessage = "Failed to update party details. Please try again."
                        isSaving = false
                    }
                }
            } catch {
                print("❌ Error updating party details: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to update party details. Please try again."
                    isSaving = false
                }
            }
        }
    }
}

#Preview {
    EditPartyDetailsSheet(onSaved: {})
        .environmentObject(PartyManager.mock)
}
