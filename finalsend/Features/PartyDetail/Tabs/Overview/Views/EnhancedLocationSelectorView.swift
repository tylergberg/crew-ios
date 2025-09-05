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
        ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose Your Party Location")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.titleDark)
                        
                        Text("Select from our curated Crew cities or explore other destinations")
                            .font(.subheadline)
                            .foregroundColor(.metaGrey)
                    }
                    .padding(.horizontal)
                    
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading cities...")
                                .foregroundColor(.metaGrey)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Cities Section
                        if !allCities.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("🌍 Available Cities")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.titleDark)
                                    
                                    Spacer()
                                    
                                    Text("\(filteredCities.count) cities")
                                        .font(.caption)
                                        .foregroundColor(.metaGrey)
                                }
                                .padding(.horizontal)
                                
                                // Search Bar
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
                                
                                LazyVStack(spacing: 12) {
                                    ForEach(filteredCities) { city in
                                        CityCardView(
                                            city: city,
                                            isSelected: selectedCity?.id == city.id,
                                            onTap: {
                                                selectedCity = city
                                            },
                                            onDetailTap: {
                                                selectedCityForDetail = city
                                                showingCityDetail = true
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Error Message
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filter") {
                        showingFilters = true
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
        .sheet(isPresented: $showingFilters) {
            CityFilterView()
        }
        .sheet(isPresented: $showingCityDetail) {
            if let city = selectedCityForDetail {
                CityDetailView(city: city) { selectedCity in
                    self.selectedCity = selectedCity
                }
            }
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
