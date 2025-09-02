//
//  CreatePartyView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-07-29.
//

import Foundation
import SwiftUI
import Supabase

struct CreatePartyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var partyName = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var selectedCityId: UUID? = nil
    @State private var location = ""
    @State private var partyType = ""
    @State private var coverImage: UIImage? = nil
    @State private var isSubmitting = false
    @State private var submissionError: String?
    @State private var partyVibeTags: [String] = []

    @State private var availableCities: [City] = []

    private let partyTypeOptions = ["Birthday", "Wedding", "Concert", "Festival", "Other"]

    private let personalityTags = ["Chill", "Rowdy", "Fancy", "Laid-back", "Energetic"]
    private let tripGoalTags = ["Sightseeing", "Party", "Relaxation", "Adventure", "Foodie"]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Party Details")) {
                    TextField("Party Name", text: $partyName)
                    Text("This name will appear on invites and dashboards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)

                    Picker("Party Type", selection: $partyType) {
                        Text("").tag("")
                        ForEach(partyTypeOptions, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    Text("Optional. Helps us tailor recommendations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)

                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.secondary.opacity(0.25))
                        )
                    Text("Optional. Let your crew know what to expect")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Party Vibe")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Personality")
                            .font(.subheadline)
                            .bold()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(personalityTags, id: \.self) { tag in
                                    TagToggle(tag: tag, isSelected: partyVibeTags.contains(tag)) {
                                        if partyVibeTags.contains(tag) {
                                            partyVibeTags.removeAll(where: { $0 == tag })
                                        } else {
                                            partyVibeTags.append(tag)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 12)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Trip Goals")
                            .font(.subheadline)
                            .bold()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(tripGoalTags, id: \.self) { tag in
                                    TagToggle(tag: tag, isSelected: partyVibeTags.contains(tag)) {
                                        if partyVibeTags.contains(tag) {
                                            partyVibeTags.removeAll(where: { $0 == tag })
                                        } else {
                                            partyVibeTags.append(tag)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Location")) {
                    Picker("Select City", selection: $selectedCityId) {
                        Text("None").tag(nil as UUID?)
                        ForEach(availableCities, id: \.id) { city in
                            Text(city.city).tag(Optional(city.id))
                        }
                    }
                    Text("Optional. Choose your own destination...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)

                    Button(action: {}) {
                        Label("Find Perfect City (Coming Soon)", systemImage: "magnifyingglass")
                    }
                    .disabled(true)
                }

                Section(header: Text("When are you thinking?")) {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    Text("You can set or edit this later")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let error = submissionError {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                }

                Button("Create Party") {
                    submitParty()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(isSubmitting || partyName.isEmpty)
            }
            .navigationTitle("New Party")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear(perform: fetchCities)
        }
    }

    func fetchCities() {
        Task {
            do {
                let client = SupabaseClient(
                    supabaseURL: URL(string: "https://gyjxjigtihqzepotegjy.supabase.co")!,
                    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5anhqaWd0aWhxemVwb3RlZ2p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIyMzEwOTgsImV4cCI6MjA1NzgwNzA5OH0.3HQ7kvYmg7rPfyF8kB8pJe3iaMJ9sYigl8KGN3Q1rYo"
                )

                let cities: [City] = try await client
                    .from("cities")
                    .select("id, city")
                    .order("city", ascending: true)
                    .execute()
                    .value

                availableCities = cities
            } catch {
                submissionError = "Failed to load cities: \(error.localizedDescription)"
            }
        }
    }

    func submitParty() {
        isSubmitting = true
        submissionError = nil

        struct NewParty: Codable {
            let name: String
            let description: String
            let start_date: String
            let end_date: String
            let created_by: String
            let city_id: String?
            let location: String
            let party_type: String
            let party_vibe_tags: [String]
        }

        Task {
            do {
                let client = SupabaseClient(
                    supabaseURL: URL(string: "https://gyjxjigtihqzepotegjy.supabase.co")!,
                    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5anhqaWd0aWhxemVwb3RlZ2p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIyMzEwOTgsImV4cCI6MjA1NzgwNzA5OH0.3HQ7kvYmg7rPfyF8kB8pJe3iaMJ9sYigl8KGN3Q1rYo"
                )

                let session = try await client.auth.session
                let userId = session.user.id.uuidString

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"

                let newParty = NewParty(
                    name: partyName,
                    description: description,
                    start_date: formatter.string(from: startDate),
                    end_date: formatter.string(from: endDate),
                    created_by: userId,
                    city_id: selectedCityId?.uuidString,
                    location: location,
                    party_type: partyType,
                    party_vibe_tags: partyVibeTags
                )

                _ = try await client
                    .from("parties")
                    .insert([newParty])
                    .execute()

                // Dismiss the sheet after successful submission
                DispatchQueue.main.async {
                    dismiss()
                }
            } catch {
                submissionError = "Failed to create party: \(error.localizedDescription)"
            }

            isSubmitting = false
        }
    }
}

struct TagToggle: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tag)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                .foregroundColor(isSelected ? Color.accentColor : Color.primary)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct City: Identifiable, Codable, Equatable {
    let id: UUID
    let city: String
}
