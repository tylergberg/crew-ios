import SwiftUI
import Supabase

struct PackingTabView: View {
    let partyId: UUID
    let userRole: UserRole
    let currentUserId: UUID
    
    @StateObject private var packingStore: PackingStore
    @State private var showingAddItem = false
    @State private var editingItem: PackingItem?
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: PackingItem?
    @State private var searchText = ""
    
    init(partyId: UUID, userRole: UserRole, currentUserId: UUID, supabase: SupabaseClient) {
        self.partyId = partyId
        self.userRole = userRole
        self.currentUserId = currentUserId
        self._packingStore = StateObject(wrappedValue: PackingStore(supabase: supabase))
    }
    
    var filteredItems: [PackingItem] {
        if searchText.isEmpty {
            return packingStore.items
        } else {
            return packingStore.items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                (item.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var packedCount: Int {
        packingStore.items.filter { $0.isPacked }.count
    }
    
    var totalCount: Int {
        packingStore.items.count
    }
    
    var completionPercentage: Int {
        guard totalCount > 0 else { return 0 }
        return Int((Double(packedCount) / Double(totalCount)) * 100)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if packingStore.isLoading {
                    Spacer()
                    ProgressView("Loading packing items...")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                } else if let error = packingStore.error {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("Error Loading Packing List")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(error.localizedDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            Task {
                                await packingStore.load(partyId: partyId, userId: currentUserId)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    Spacer()
                } else if filteredItems.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 64))
                            .foregroundColor(.orange)
                        
                        Text("No packing items yet")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Start by adding items to your personal packing list for this trip")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Add First Item") {
                            showingAddItem = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    Spacer()
                } else {
                    VStack(spacing: 16) {
                        // Progress Card
                        if totalCount > 0 {
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Your Packing Progress")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        
                                        Text("\(packedCount) of \(totalCount) items packed")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("\(completionPercentage)%")
                                            .font(.title)
                                            .fontWeight(.bold)
                                        
                                        Text("Complete")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                ProgressView(value: Double(packedCount), total: Double(totalCount))
                                    .progressViewStyle(LinearProgressViewStyle())
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField("Search packing items...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        
                        // Items List
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredItems) { item in
                                    PackingItemRowView(
                                        item: item,
                                        onTogglePacked: { isPacked in
                                            Task {
                                                await packingStore.togglePackedStatus(
                                                    itemId: item.id,
                                                    userId: currentUserId,
                                                    isPacked: isPacked
                                                )
                                            }
                                        },
                                        onEdit: {
                                            editingItem = item
                                        },
                                        onDelete: {
                                            itemToDelete = item
                                            showingDeleteAlert = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Packing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddItem = true
                    }
                }
            }
        }
        .onAppear {
            Task {
                await packingStore.load(partyId: partyId, userId: currentUserId)
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddPackingItemView(
                partyId: partyId,
                userId: currentUserId,
                packingStore: packingStore,
                editingItem: editingItem
            )
        }
        .alert("Delete Item", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    Task {
                        await packingStore.deleteItem(itemId: item.id)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this packing item? This action cannot be undone.")
        }
        .onChange(of: showingAddItem) { showing in
            if !showing {
                editingItem = nil
            }
        }
    }
}

#Preview {
    PackingTabView(
        partyId: UUID(),
        userRole: UserRole.attendee,
        currentUserId: UUID(),
        supabase: SupabaseClient(supabaseURL: URL(string: "https://example.com")!, supabaseKey: "key")
    )
}

