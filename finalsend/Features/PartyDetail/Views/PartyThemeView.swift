import SwiftUI

struct PartyThemeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var partyManager: PartyManager
    @State private var selectedTheme: PartyTheme
    @State private var isSaving = false
    
    init(currentTheme: PartyTheme) {
        self._selectedTheme = State(initialValue: currentTheme)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("Party Theme")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.titleDark)
                    
                    Text("Choose a theme to customize the look and feel of your party")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
                
                // Theme Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(PartyTheme.allThemes) { theme in
                            ThemeCard(
                                theme: theme,
                                isSelected: theme.id == selectedTheme.id,
                                onTap: { selectedTheme = theme }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                // Preview Section
                VStack(spacing: 16) {
                    Text("Preview")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.titleDark)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    
                    // Preview Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Circle()
                                .fill(selectedTheme.primaryAccentColor)
                                .frame(width: 12, height: 12)
                            
                            Text("Sample Card")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(selectedTheme.textPrimaryColor)
                            
                            Spacer()
                            
                            Text("Preview")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(selectedTheme.secondaryAccentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Text("This is how your party content will look with the selected theme. The colors will be applied to cards, buttons, and other UI elements.")
                            .font(.subheadline)
                            .foregroundColor(selectedTheme.textSecondaryColor)
                            .lineLimit(3)
                    }
                    .padding(16)
                    .background(selectedTheme.cardBackgroundColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedTheme.primaryAccentColor.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }
                .padding(.top, 24)
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.titleDark)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.outlineBlack, lineWidth: 1.5)
                    )
                    
                    Button("Save Theme") {
                        saveTheme()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.yellow)
                    .foregroundColor(.titleDark)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.outlineBlack, lineWidth: 1.5)
                    )
                    .disabled(isSaving)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .background(selectedTheme.cardBackgroundColor)
            .navigationBarHidden(true)
        }
    }
    
    private func saveTheme() {
        isSaving = true
        
        Task {
            do {
                // Save to database using PartyManagementService
                let updates = ["theme_id": selectedTheme.id]
                let partyManagementService = PartyManagementService()
                let success = try await partyManagementService.updateParty(
                    partyId: partyManager.partyId, 
                    updates: updates
                )
                
                if success {
                    // Update the party theme in PartyManager
                    partyManager.updateTheme(selectedTheme)
                    
                    // Dismiss the sheet
                    await MainActor.run {
                        isSaving = false
                        dismiss()
                    }
                } else {
                    // Handle failure
                    print("❌ Failed to update party theme in database")
                    await MainActor.run {
                        isSaving = false
                    }
                }
            } catch {
                print("❌ Error updating party theme: \(error)")
                await MainActor.run {
                    isSaving = false
                }
            }
        }
    }
}

struct ThemeCard: View {
    let theme: PartyTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Color preview
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.cardBackgroundColor)
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? theme.primaryAccentColor : Color.clear, lineWidth: 3)
                    )
                    .overlay(
                        VStack(spacing: 4) {
                            Circle()
                                .fill(theme.primaryAccentColor)
                                .frame(width: 20, height: 20)
                            
                            Circle()
                                .fill(theme.secondaryAccentColor)
                                .frame(width: 16, height: 16)
                        }
                    )
                
                VStack(spacing: 4) {
                    Text(theme.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.titleDark)
                    
                    Text(theme.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? theme.primaryAccentColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? theme.primaryAccentColor.opacity(0.3) : .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PartyThemeView(currentTheme: PartyTheme.default)
        .environmentObject(PartyManager())
}
