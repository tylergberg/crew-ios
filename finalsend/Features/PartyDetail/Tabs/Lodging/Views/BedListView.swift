import SwiftUI

struct BedListView: View {
    let beds: [LodgingBed]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(beds) { bed in
                HStack {
                    Image(systemName: "bed.double")
                        .foregroundColor(.orange)
                    Text(bed.type)
                        .font(.subheadline)
                        .foregroundColor(.titleDark)
                    Spacer()
                    if let person = bed.assignedTo {
                        Text(person)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    BedListView(beds: [LodgingBed(type: "King", assignedTo: "Alex"), LodgingBed(type: "Twin")])
}


