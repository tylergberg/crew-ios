import SwiftUI

struct PaidByPickerView: View {
    let attendees: [PartyAttendee]
    @Binding var selectedUserId: String
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(attendees, id: \.userId) { attendee in
                    Button(action: {
                        selectedUserId = attendee.userId
                        onDismiss()
                    }) {
                        HStack {
                            Text(attendee.fullName)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedUserId == attendee.userId {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Who Paid?")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    onDismiss()
                }
            )
        }
    }
}

#Preview {
    PaidByPickerView(
        attendees: [
            PartyAttendee(fullName: "John Doe"),
            PartyAttendee(fullName: "Jane Smith"),
            PartyAttendee(fullName: "Bob Johnson")
        ],
        selectedUserId: .constant(""),
        onDismiss: {}
    )
}

