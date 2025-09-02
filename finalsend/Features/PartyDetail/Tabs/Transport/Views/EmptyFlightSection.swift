import SwiftUI

struct EmptyFlightSection: View {
    let direction: FlightDirection
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "airplane")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No \(direction.displayName.lowercased()) flights yet")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Add your first \(direction.displayName.lowercased()) flight to get started")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 20) {
        EmptyFlightSection(direction: .arrival)
        EmptyFlightSection(direction: .departure)
    }
    .padding()
}
