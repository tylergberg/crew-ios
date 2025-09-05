//
//  CreatePartyLocationSelectorView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-01-27.
//

import SwiftUI

struct StepPartyLocationSelectorView: View {
    let selectedCity: CityModel?
    let onCitySelected: (CityModel) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var allCities: [CityModel] = []
    @State private var currentSelectedCity: CityModel?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchQuery = ""
    @State private var filteredCities: [CityModel] = []
    @State private var showingCityDetail = false
    @State private var selectedCityForDetail: CityModel?
    
    private let citySearchService = CitySearchService()
    
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
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 16) {
                                    ForEach(filteredCities) { city in
                                        CityCardView(
                                            city: city,
                                            isSelected: currentSelectedCity?.id == city.id,
                                            onTap: {
                                                currentSelectedCity = city
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
                    Button("Done") {
                        if let city = currentSelectedCity {
                            onCitySelected(city)
                        }
                    }
                    .disabled(currentSelectedCity == nil)
                }
            }
        .onAppear {
            currentSelectedCity = selectedCity
            loadCities()
        }
        .sheet(isPresented: $showingCityDetail) {
            if let city = selectedCityForDetail {
                CityDetailView(city: city) { selectedCity in
                    self.currentSelectedCity = selectedCity
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
}

#Preview {
    StepPartyLocationSelectorView(
        selectedCity: nil,
        onCitySelected: { city in
            print("Selected city: \(city.city)")
        }
    )
}
