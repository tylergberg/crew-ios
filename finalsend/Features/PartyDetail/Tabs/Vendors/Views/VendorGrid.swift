import SwiftUI

struct VendorGrid: View {
    let title: String
    let vendors: [Vendor]
    let onSelect: (Vendor) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3).bold()
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(vendors) { vendor in
                        Button(action: { onSelect(vendor) }) {
                            VendorCardView(vendor: vendor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}


