//
//  EditLocationSheet.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-05.
//

import SwiftUI

struct EditLocationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var partyManager: PartyManager
    
    @State private var searchQuery = ""
    @State private var availableCities: [CityModel] = []
    @State private var isLoading = false
    @State private var selectedCity: CityModel?
    @State private var errorMessage: String?
    @State private var isSaving = false
    
    private let citySearchService = CitySearchService()
    private let partyManagementService = PartyManagementService()
    private let onSaved: () -> Void
    
    init(onSaved: @escaping () -> Void) {
        self.onSaved = onSaved
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Where is your party?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.titleDark)
                    
                    Text("Choose a city to set your party location")
                        .font(.subheadline)
                        .foregroundColor(.metaGrey)
                }
                .padding(.horizontal)
                
                // City Search
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.metaGrey)
                        
                        TextField("Search cities...", text: $searchQuery)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: searchQuery) { query in
                                Task {
                                    await performCitySearch(query: query)
                                }
                            }
                    }
                    .padding(.horizontal)
                    
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Searching cities...")
                                .foregroundColor(.metaGrey)
                        }
                        .padding()
                    } else if !availableCities.isEmpty {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(availableCities) { city in
                                    Button(action: {
                                        selectedCity = city
                                    }) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(city.displayName)
                                                .font(.body)
                                                .foregroundColor(.titleDark)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            Text(city.country)
                                                .font(.caption)
                                                .foregroundColor(.metaGrey)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedCity?.id == city.id ? Color.brandBlue.opacity(0.1) : Color.white)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(selectedCity?.id == city.id ? Color.brandBlue : Color.outlineBlack.opacity(0.3), lineWidth: selectedCity?.id == city.id ? 2 : 1)
                                                )
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 300)
                    } else if !searchQuery.isEmpty && !isLoading {
                        Text("No cities found")
                            .foregroundColor(.metaGrey)
                            .padding()
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Edit Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLocation()
                    }
                    .disabled(selectedCity == nil || isSaving)
                    .overlay(
                        Group {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                    .scaleEffect(0.8)
                            }
                        }
                    )
                }
            }
        }
        .onAppear {
            // Initialize with current location if available
            if let cityId = partyManager.cityId {
                searchQuery = partyManager.location
            }
            
            // Load some initial cities
            Task {
                await performCitySearch(query: "")
            }
        }
    }
    
    private func performCitySearch(query: String) async {
        isLoading = true
        
        do {
            let cities: [CityModel]
            if query.isEmpty {
                // Show some popular cities for empty query
                cities = try await citySearchService.searchCities(query: "New York")
                // Limit to first 10 for initial display
                let limitedCities = Array(cities.prefix(10))
                await MainActor.run {
                    availableCities = limitedCities
                    isLoading = false
                }
            } else {
                // Search for specific query
                cities = try await citySearchService.searchCities(query: query)
                await MainActor.run {
                    availableCities = cities
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to search cities: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func saveLocation() {
        guard let city = selectedCity else { return }
        
        isSaving = true
        
        Task {
            do {
                // Save to database - update both city_id and location
                let updates: [String: Any] = [
                    "city_id": city.id.uuidString,
                    "location": city.displayName
                ]
                
                let success = try await partyManagementService.updateParty(partyId: partyManager.partyId, updates: updates)
                
                if success {
                    // Update the party manager
                    partyManager.cityId = city.id
                    partyManager.location = city.displayName
                    partyManager.timezone = city.timezone
                    
                    // Call onSaved callback
                    onSaved()
                    
                    // Dismiss the sheet
                    dismiss()
                } else {
                    // Handle failure
                    await MainActor.run {
                        errorMessage = "Failed to update location in database"
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error updating location: \(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                isSaving = false
            }
        }
    }
}

#Preview {
    EditLocationSheet(onSaved: {})
        .environmentObject(PartyManager())
}

