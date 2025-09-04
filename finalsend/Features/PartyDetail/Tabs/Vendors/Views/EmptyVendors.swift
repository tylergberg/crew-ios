import SwiftUI

struct EmptyVendors: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bag").font(.largeTitle)
            Text("No vendors yet")
                .font(.headline)
            Text("Pick a destination city to explore nearby vendors.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


