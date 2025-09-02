import SwiftUI

struct RoomListView: View {
    let rooms: [LodgingRoom]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(rooms) { room in
                    LodgingCardView(room: room)
                }
            }
            .padding(16)
        }
    }
}

#Preview {
    RoomListView(
        rooms: [
            LodgingRoom(name: "Master Suite", beds: [LodgingBed(type: "King"), LodgingBed(type: "Twin")], notes: "Ocean view"),
            LodgingRoom(name: "Guest Room", beds: [LodgingBed(type: "Queen")])
        ]
    )
}


