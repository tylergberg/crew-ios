import SwiftUI

struct LodgingTabView: View {
    let partyId: UUID
    let currentUserId: UUID
    let currentUserRole: UserRole
    @Environment(\.dismiss) private var dismiss
    @State private var showArrangements = false
    @StateObject private var store = LodgingStore(supabase: SupabaseManager.shared.client)

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Lodging details card (mock)
                LodgingDetailsCard(
                    title: store.lodgingTitle.isEmpty ? "Lodging" : store.lodgingTitle,
                    address: store.lodgingAddress,
                    onEdit: {},
                    onSleepingArrangements: {
                        // Navigate to sleeping arrangements within this NavigationView
                        showArrangements = true
                    }
                )
                if store.isLoading {
                    ProgressView().padding(.top, 8)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(
                NavigationLink(
                    destination: SleepingArrangementsView(partyId: partyId),
                    isActive: $showArrangements,
                    label: { EmptyView() }
                )
                .hidden()
            )
            .navigationTitle("Lodging")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) { Image(systemName: "plus") }
                }
            }
            .task {
                await store.loadLodgings(partyId: partyId)
            }
        }
    }
}

// Simple card matching screenshot style
private struct LodgingDetailsCard: View {
    let title: String
    let address: String
    let onEdit: () -> Void
    let onSleepingArrangements: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.titleDark)
                Spacer()
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.secondary)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            Text(address)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(2)
            
            Divider()
                .padding(.vertical, 4)
            
            Button(action: onSleepingArrangements) {
                HStack {
                    Image(systemName: "bed.double")
                    Text("Sleeping Arrangements")
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color(.systemGray5))
                .foregroundColor(.titleDark)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    LodgingTabView(
        partyId: UUID(),
        currentUserId: UUID(),
        currentUserRole: .attendee
    )
}


