//
//  EditDescriptionSheet.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-05.
//

import SwiftUI

struct EditDescriptionSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var descriptionText: String
    var onSave: (String) -> Void

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Edit Party Description")
                    .font(.title2)
                    .bold()
                    .padding(.top)

                TextEditor(text: $descriptionText)
                    .frame(minHeight: 150)
                    .padding()
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 2)
                    )

                Spacer()

                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                    }

                    Button(action: {
                        onSave(descriptionText)
                        dismiss()
                    }) {
                        Text("Save Changes")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yellow) // or use Color(hex: "#F9C94E") if available
                            .foregroundColor(.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                    }
                }
            }
            .padding()
            .background(Color(red: 0.607, green: 0.784, blue: 0.933)) // match your app background
            .navigationBarHidden(true)
        }
    }
}
