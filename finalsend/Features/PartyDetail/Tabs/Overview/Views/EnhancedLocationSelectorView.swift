//
//  EnhancedLocationSelectorView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-01-27.
//

import SwiftUI

struct EnhancedLocationSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var partyManager: PartyManager
    
    @State private var allCities: [CityModel] = []
    @State private var selectedCity: CityModel?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var showingFilters = false
    @State private var searchQuery = ""
    @State private var filteredCities: [CityModel] = []
    @State private var showingCityDetail = false
    @State private var selectedCityForDetail: CityModel?
    @State private var showEditLocationModal = false
    
    private let citySearchService = CitySearchService()
    private let partyManagementService = PartyManagementService()
    private let onSaved: () -> Void
    
    init(onSaved: @escaping () -> Void) {
        self.onSaved = onSaved
    }
    
    var body: some View {
        VStack(spacing: 0) {
                // Sticky Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.metaGrey)
                    
                    TextField("Search cities...", text: $searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: searchQuery) { query in
                            filterCities(query: query)
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.vertical, 16)
                .background(Color.white)
                
                // Scrollable Cities List
                ScrollView {
                    VStack(spacing: 0) {
                        if isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading cities...")
                                    .foregroundColor(.metaGrey)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else if !allCities.isEmpty {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredCities) { city in
                                    Button(action: {
                                        selectedCity = city
                                    }) {
                                        HStack {
                                            Text("\(city.city) (\(city.country))")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.titleDark)
                                            
                                            Spacer()
                                            
                                            if selectedCity?.id == city.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.blue)
                                                    .font(.system(size: 20))
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(selectedCity?.id == city.id ? Color.blue.opacity(0.1) : Color.clear)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if city.id != filteredCities.last?.id {
                                        Divider()
                                            .padding(.leading, 16)
                                    }
                                }
                            }
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                            )
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                        } else if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                                .padding(.top, 16)
                        }
                    }
                }
            }
        .navigationTitle("Location")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveSelectedCity()
                }
                .disabled(selectedCity == nil || isSaving)
            }
        }
        .onAppear {
            loadCities()
        }
    }
    
    private func loadCities() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let cities = try await citySearchService.fetchAllCities()
                
                await MainActor.run {
                    self.allCities = cities
                    self.filteredCities = cities
                    self.isLoading = false
                    
                    // Pre-select current city if available
                    if let currentCityId = partyManager.cityId {
                        if let currentCity = cities.first(where: { $0.id == currentCityId }) {
                            self.selectedCity = currentCity
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load cities: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func filterCities(query: String) {
        if query.isEmpty {
            filteredCities = allCities
        } else {
            filteredCities = allCities.filter { city in
                city.city.localizedCaseInsensitiveContains(query) ||
                city.stateOrProvince?.localizedCaseInsensitiveContains(query) == true ||
                city.country.localizedCaseInsensitiveContains(query)
            }
        }
    }
    
    private func saveSelectedCity() {
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
                    await MainActor.run {
                        partyManager.cityId = city.id
                        partyManager.location = city.displayName
                        partyManager.timezone = city.timezone ?? "UTC"
                        isSaving = false
                        onSaved()
                        showEditLocationModal = false
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Failed to save location"
                        isSaving = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save location: \(error.localizedDescription)"
                    isSaving = false
                }
            }
        }
    }
}

// Placeholder for filter view
struct CityFilterView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("City Filters")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Filter options coming soon!")
                    .foregroundColor(.metaGrey)
                
                Spacer()
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EnhancedLocationSelectorView {
        print("Location saved")
    }
    .environmentObject(PartyManager())
}

