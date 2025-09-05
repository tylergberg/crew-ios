import SwiftUI

struct DeletePartyConfirmationSheet: View {
    let partyName: String
    let onConfirm: () -> Void
    let onDismiss: () -> Void
    
    @State private var deleteConfirmationText = ""
    @State private var isDeleting = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Warning Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
                .padding(.top, 20)
            
            // Title
            Text("Delete Party")
                .font(.title2)
                .fontWeight(.bold)
            
            // Party Name
            Text(partyName)
                .font(.body)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            
            // Warning Text
            Text("This will permanently delete all party data, attendees, expenses, and itinerary.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
            
            // Confirmation Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Type \"DELETE\" to confirm:")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                TextField("DELETE", text: $deleteConfirmationText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
            }
            .padding(.horizontal, 20)
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    isDeleting = true
                    onConfirm()
                }) {
                    HStack {
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text(isDeleting ? "Deleting..." : "Delete Party")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(deleteConfirmationText == "DELETE" && !isDeleting ? Color.red : Color.gray)
                    .cornerRadius(8)
                }
                .disabled(deleteConfirmationText != "DELETE" || isDeleting)
                
                Button(action: onDismiss) {
                    Text("Cancel")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.clear)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .disabled(isDeleting)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    DeletePartyConfirmationSheet(
        partyName: "Taylor Swift's Bachelorette",
        onConfirm: {},
        onDismiss: {}
    )
}
