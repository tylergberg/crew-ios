import SwiftUI

struct PartyCardView: View {
    let party: Party

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    if let imageURL = party.coverImageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 160)
                                .clipped()
                        } placeholder: {
                            Color.gray.frame(height: 160)
                        }
                    } else {
                        ZStack {
                            Color.gray.frame(height: 160)
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.white)
                        }
                    }

                    let badge = daysAwayString(for: party)
                    if !badge.isEmpty {
                        Text(badge)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .padding(8)
                            .shadow(color: .black, radius: 2, x: 2, y: 2)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(party.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.25, green: 0.1, blue: 0.09))

                    if let city = party.city?.city {
                        Label {
                            Text(city)
                        } icon: {
                            Image(systemName: "mappin.and.ellipse")
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    }

                    if let startDate = party.startDate,
                       let endDate = party.endDate {
                        Label {
                            Text("\(startDate) to \(endDate)")
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(red: 0.99, green: 0.95, blue: 0.91))
            }
            .background(Color(red: 0.99, green: 0.95, blue: 0.91))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black, lineWidth: 2)
            )
            .shadow(color: .black, radius: 3, x: 3, y: 3)
            .padding(.horizontal)
        }
    }

    private func daysAwayString(for party: Party) -> String {
        let formatter = ISO8601DateFormatter()
        guard let start = party.startDate.flatMap({ formatter.date(from: $0) }) else { return "" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: start).day ?? 0
        return "\(days) days away"
    }
}
