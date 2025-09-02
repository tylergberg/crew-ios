import SwiftUI

struct EmptyPartyCardView: View {
    let onCreateParty: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Cover Image - square using GeometryReader for responsive sizing
            GeometryReader { geometry in
                ZStack(alignment: .center) {
                    // Placeholder cover image with gradient
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#F9C94E").opacity(0.8),
                                    Color(hex: "#9BC8EE").opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        )
                }

            }
            .aspectRatio(1, contentMode: .fit) // Force square aspect ratio
            
            // Party Info
            VStack(alignment: .leading, spacing: 12) {
                // Party Name
                Text("Plan Your Next Adventure")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#353E3E"))
                    .lineLimit(2)
                
                // Location
                HStack {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.brandBlue)
                        .frame(width: 16)
                    
                    Text("Choose your destination")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Dates
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.brandBlue)
                        .frame(width: 16)
                    
                    Text("Pick your dates")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Crew
                HStack {
                    Image(systemName: "sparkle")
                        .font(.caption)
                        .foregroundColor(.brandBlue)
                        .frame(width: 16)
                    
                    Text("Invite your crew")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Plus icon to indicate adding
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.brandBlue)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)

        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

#Preview {
    EmptyPartyCardView {
        print("Create party tapped")
    }
    .padding()
    .background(Color.neutralBackground)
}
