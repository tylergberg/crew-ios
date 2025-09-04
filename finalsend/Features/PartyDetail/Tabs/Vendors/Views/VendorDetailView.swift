import SwiftUI

struct VendorDetailView: View, Identifiable {
    let id = UUID()
    let vendor: Vendor
    @EnvironmentObject var partyManager: PartyManager
    @EnvironmentObject var sessionManager: SessionManager
    @State private var showingAddSheet = false
    @State private var addError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                info
                Spacer(minLength: 8)
                addButton
            }
            .padding(16)
        }
        .navigationTitle(vendor.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddSheet) {
            AddEventSheet(
                partyId: partyManager.partyId,
                currentUserId: sessionManager.userProfile?.id ?? "",
                cityTimezone: partyManager.timezone,
                onEventAdded: { _ in showingAddSheet = false },
                prefillTitle: vendor.name,
                prefillDescription: vendor.description,
                prefillLocation: vendor.location,
                prefillLocationUrl: vendor.websiteUrl,
                prefillImageUrl: vendor.imageUrl,
                prefillDate: startDatePrefill
            )
            .environmentObject(partyManager)
            .environmentObject(sessionManager)
        }
    }

    private var header: some View {
        let side = UIScreen.main.bounds.width - 32 // match outer padding of 16 on each side
        return ZStack {
            Rectangle().fill(Color(.systemGray6))
            if let imageUrl = vendor.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipped()
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(maxWidth: .infinity)
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let desc = vendor.description, !desc.isEmpty {
                Text(desc)
                    .font(.body)
            }
            HStack(spacing: 8) {
                if let rating = vendor.rating {
                    Image(systemName: "star.fill").foregroundColor(.yellow)
                    Text(String(describing: rating)).foregroundColor(.secondary)
                }
                if let price = vendor.priceRange, !price.isEmpty {
                    Text(price).foregroundColor(.secondary)
                }
            }
            if let website = vendor.websiteUrl, let url = URL(string: website) {
                Link("Visit Website", destination: url)
            }
            if let phone = vendor.phone, !phone.isEmpty, let telURL = URL(string: "tel://\(phone)") {
                Link("Call", destination: telURL)
            }
        }
    }

    private var addButton: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error = addError { Text(error).foregroundColor(.red).font(.footnote) }
            Button {
                showingAddSheet = true
            } label: {
                HStack {
                    Text("Add to Itinerary")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }

    private var startDatePrefill: Date? {
        // Use party start date from PartyManager
        return partyManager.startDate
    }
}
