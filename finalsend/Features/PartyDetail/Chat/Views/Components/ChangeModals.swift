import SwiftUI

struct ChangeRsvpModal: View {
    var attendee: PartyAttendee
    var onChange: (RsvpStatus) -> Void
    var onDismiss: () -> Void
    
    @State private var currentStatus: RsvpStatus = .pending
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Change RSVP for \(attendee.fullName)")
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(.top, 12)

            VStack(spacing: 12) {
                selectableButton(title: "Going", isSelected: currentStatus == .confirmed) {
                    onChange(.confirmed)
                }
                selectableButton(title: "Pending", isSelected: currentStatus == .pending) {
                    onChange(.pending)
                }
                selectableButton(title: "Can't go", isSelected: currentStatus == .declined) {
                    onChange(.declined)
                }
            }

            Button("Cancel", action: onDismiss)
                .padding(.top, 4)
        }
        .padding(20)
        .presentationDetents([.fraction(0.35), .medium])
        .presentationDragIndicator(.visible)
        .onAppear { currentStatus = attendee.rsvpStatus }
    }
}

private extension ChangeRsvpModal {
    func selectableButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? Color.white : Color.accentColor)
                    .frame(maxWidth: .infinity, alignment: .center)
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color.white)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.accentColor : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentColor, lineWidth: 1.5)
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

struct ChangeRoleModal: View {
    var attendee: PartyAttendee
    var onChange: (UserRole) -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Change Role for \(attendee.fullName)").font(.headline)
            ForEach(UserRole.allCases, id: \.self) { role in
                Button(role.displayName) { onChange(role) }
                    .buttonStyle(.bordered)
            }
            Button("Cancel", action: onDismiss)
        }
        .padding()
    }
}


