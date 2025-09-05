import SwiftUI

struct StepPartyLocationView: View {
    @ObservedObject var viewModel: CreatePartyViewModel
    @State private var allCities: [CityModel] = []
    @State private var isLoading = false
    @State private var searchQuery = ""
    @State private var filteredCities: [CityModel] = []
    
    private let citySearchService = CitySearchService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Where is your party?")
                    .font(Typography.title())
                    .foregroundColor(.titleDark)
                
                Text("Optional. You can choose a city later.")
                    .font(Typography.meta())
                    .foregroundColor(.metaGrey)
            }
            
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
                
                // Cities List
                if !filteredCities.isEmpty {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredCities) { city in
                            Button(action: {
                                if viewModel.selectedCity?.id == city.id {
                                    // Deselect if already selected
                                    viewModel.selectedCity = nil
                                    viewModel.draft.cityId = nil
                                } else {
                                    // Select the city
                                    viewModel.selectedCity = city
                                    viewModel.draft.cityId = city.id
                                }
                            }) {
                                HStack {
                                    Text("\(city.city) (\(city.country))")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.titleDark)
                                    
                                    Spacer()
                                    
                                    if viewModel.selectedCity?.id == city.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 20))
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(viewModel.selectedCity?.id == city.id ? Color.blue.opacity(0.1) : Color.clear)
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
                }
            }
            
            Spacer()
        }
        .onAppear {
            loadCities()
        }
    }
    
    private func loadCities() {
        isLoading = true
        
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
    StepPartyLocationView(viewModel: CreatePartyViewModel())
        .padding()
        .background(.white)
}
