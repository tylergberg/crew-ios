import SwiftUI

struct EmptyPartyStateView: View {
    let tab: PartyTab
    let onCreateParty: () -> Void
    
    private var messages: (title: String, description: String) {
        switch tab {
        case .upcoming:
            return ("No upcoming parties", "Time to plan the perfect party!")
        case .inprogress:
            return ("Party loading...", "Your trip will appear here once the party officially kicks off.")
        case .attended:
            return ("Memories live here", "Once the party's over, your recaps will show up here.")
        case .didntgo:
            return ("No past declined invites", "Past invites you declined or didn't attend will show here.")
        case .declined:
            return ("No declined parties", "You haven't declined any party invitations yet.")
        case .pending:
            return ("No pending invitations", "You don't have any pending party invitations.")
        }
    }
    
    private var illustrationName: String {
        switch tab {
        case .upcoming:
            return "partyplans"
        case .inprogress:
            return "partytime"
        case .attended:
            return "partypast"
        case .didntgo:
            return "partypast"
        case .declined:
            return "partypast" // Use same illustration as past for declined
        case .pending:
            return "partypast" // Use same illustration as past for pending
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(illustrationName)
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .padding(.bottom, 8)
            
            Text(messages.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.titleDark)
            
            Text(messages.description)
                .font(.subheadline)
                .foregroundColor(Color.metaGrey)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if tab == .upcoming {
                Button(action: onCreateParty) {
                    Text("CREATE A PARTY")
                        .fontWeight(.bold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.yellow)
                        .foregroundColor(Color.titleDark)
                        .cornerRadius(Radius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.button)
                                .stroke(Color.outlineBlack, lineWidth: 1.5)
                        )
                        .shadow(
                            color: .black.opacity(0.12),
                            radius: 3,
                            x: 0,
                            y: 1
                        )
                }
                .padding(.top, 12)
            }
        }
        .padding(.top, 32)
        .padding(.horizontal, Spacing.screenH)
    }
}

#Preview {
    EmptyPartyStateView(tab: .upcoming) {
        print("Create party tapped")
    }
    .background(Color(red: 0.607, green: 0.784, blue: 0.933))
}
