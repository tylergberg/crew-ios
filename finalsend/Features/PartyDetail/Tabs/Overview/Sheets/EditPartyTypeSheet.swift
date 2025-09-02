//
//  EditPartyTypeSheet.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-05.
//

import SwiftUI

struct EditPartyTypeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var partyManager: PartyManager
    
    let onSaved: () -> Void
    private let partyManagementService = PartyManagementService()
    
    @State private var selectedPartyType: String = ""
    @State private var customPartyType: String = ""
    @State private var isSaving = false
    
    private let partyTypeOptions = [
        "Bachelor Party",
        "Bachelorette Party", 
        "Birthday Trip",
        "Golf Trip",
        "Festival / Concert",
        "Trip with Friends",
        "Other"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit Party Type")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.titleDark)
                    
                    Text("Choose the type of party you're planning")
                        .font(.subheadline)
                        .foregroundColor(.metaGrey)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Party Type Options
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(partyTypeOptions, id: \.self) { type in
                            Button(action: {
                                selectedPartyType = type
                                if type != "Other" {
                                    customPartyType = ""
                                }
                            }) {
                                HStack {
                                    Text(type)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(selectedPartyType == type ? .titleDark : .metaGrey)
                                    
                                    Spacer()
                                    
                                    if selectedPartyType == type {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.titleDark)
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedPartyType == type ? .yellow : .white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Custom Party Type Input
                        if selectedPartyType == "Other" {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Custom Party Type")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.titleDark)
                                
                                TextField("Enter your party type...", text: $customPartyType)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal, 20)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
                
                Spacer()
                
                // Save Button
                Button(action: savePartyType) {
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
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedPartyType.isEmpty || (selectedPartyType == "Other" && customPartyType.isEmpty) ? .gray : Color.brandBlue)
                    )
                }
                .disabled(selectedPartyType.isEmpty || (selectedPartyType == "Other" && customPartyType.isEmpty) || isSaving)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.brandBlue)
                }
            }
        }
        .onAppear {
            // Set initial selection based on current party type
            if partyManager.partyType.isEmpty {
                selectedPartyType = ""
                customPartyType = ""
            } else if partyTypeOptions.contains(partyManager.partyType) {
                selectedPartyType = partyManager.partyType
                customPartyType = ""
            } else {
                selectedPartyType = "Other"
                customPartyType = partyManager.partyType
            }
        }
    }
    
    private func savePartyType() {
        guard !selectedPartyType.isEmpty else { return }
        
        let finalPartyType: String
        if selectedPartyType == "Other" {
            guard !customPartyType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            finalPartyType = customPartyType.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            finalPartyType = selectedPartyType
        }
        
        isSaving = true
        
        Task {
            do {
                // Save to database
                let updates = ["party_type": finalPartyType]
                let success = try await partyManagementService.updateParty(partyId: partyManager.partyId, updates: updates)
                
                if success {
                    // Update the party manager
                    partyManager.partyType = finalPartyType
                    
                    // Call the onSaved callback
                    onSaved()
                    
                    // Dismiss the sheet
                    dismiss()
                } else {
                    // Handle failure
                    print("❌ Failed to update party type in database")
                }
            } catch {
                print("❌ Error updating party type: \(error)")
                // Handle error - could show an alert here
            }
            
            isSaving = false
        }
    }
}

#Preview {
    EditPartyTypeSheet(onSaved: {})
        .environmentObject(PartyManager.mock)
}

