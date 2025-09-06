import SwiftUI

struct EmptyPartyStateView: View {
    let tab: PartyTab
    let onCreateParty: () -> Void
    
    private var messages: (title: String, description: String) {
        switch tab {
        case .upcoming:
            return ("No upcoming parties", "Time to plan the perfect party!")
        case .past:
            return ("Memories live here", "Once the party's over, your recaps will show up here.")
        case .declined:
            return ("No declined parties", "You haven't declined any party invitations yet.")
        case .pending, .inprogress, .attended, .didntgo:
            return ("No parties", "No parties found in this category.")
        }
    }
    
    private var illustrationName: String {
        switch tab {
        case .upcoming:
            return "partyplans"
        case .past:
            return "partypast"
        case .declined:
            return "partypast"
        case .pending, .inprogress, .attended, .didntgo:
            return "partypast" // Default illustration for unused tabs
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
