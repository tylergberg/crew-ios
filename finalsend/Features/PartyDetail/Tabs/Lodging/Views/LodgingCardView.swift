import SwiftUI

struct LodgingRoom: Identifiable, Hashable {
    let id: UUID
    let name: String
    let beds: [LodgingBed]
    let notes: String?
    
    init(id: UUID = UUID(), name: String, beds: [LodgingBed], notes: String? = nil) {
        self.id = id
        self.name = name
        self.beds = beds
        self.notes = notes
    }
}

struct LodgingBed: Identifiable, Hashable {
    let id: UUID
    let type: String
    let assignedTo: String?
    
    init(id: UUID = UUID(), type: String, assignedTo: String? = nil) {
        self.id = id
        self.type = type
        self.assignedTo = assignedTo
    }
}

struct LodgingCardView: View {
    let room: LodgingRoom
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundColor(.orange)
                Text(room.name)
                    .font(.headline)
                    .foregroundColor(.titleDark)
                Spacer()
                Text("\(room.beds.count) beds")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) {
                ForEach(room.beds.prefix(5)) { bed in
                    Text(bed.type)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
                if room.beds.count > 5 {
                    Text("+\(room.beds.count - 5)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            if let notes = room.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    LodgingCardView(
        room: LodgingRoom(
            name: "Master Suite",
            beds: [LodgingBed(type: "King", assignedTo: "Alex"), LodgingBed(type: "Twin"), LodgingBed(type: "Sofa Bed")],
            notes: "Ocean view, balcony"
        )
    )
}


