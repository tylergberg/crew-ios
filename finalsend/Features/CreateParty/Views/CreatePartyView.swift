//
//  CreatePartyView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-07-29.
//

import Foundation
import SwiftUI

struct CreatePartyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var partyManager: PartyManager
    @StateObject private var viewModel = CreatePartyViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.neutralBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Spacing.cardGap) {
                        // Party Details Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Party Details")
                                .font(Typography.title())
                                .foregroundColor(.titleDark)
                            
                            // Party Name
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Taylor Swift's Bachelorette", text: $viewModel.draft.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.titleDark)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                                    )
                                
                                if !viewModel.isNameValid && !viewModel.draft.name.isEmpty {
                                    Text("Name must be at least 2 characters.")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            // Trip Type
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Trip Type")
                                    .font(.headline)
                                    .foregroundColor(.titleDark)
                                
                                Picker("Trip Type", selection: $viewModel.draft.partyType) {
                                    ForEach(CreatePartyViewModel.partyTypeOptions, id: \.self) { type in
                                        Text(type.capitalized).tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(.brandBlue)
                            }
                        }
                        .padding(Spacing.cardPadH)
                        .padding(.vertical, Spacing.cardPadV)
                        .background(.white)
                        .cornerRadius(Radius.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.card)
                                .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        
                        // Location Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Location")
                                .font(Typography.title())
                                .foregroundColor(.titleDark)
                            
                            // City Search
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Search cities...", text: $viewModel.searchQuery)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.titleDark)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                                    )
                                
                                if !viewModel.availableCities.isEmpty {
                                    ScrollView {
                                        LazyVStack(alignment: .leading, spacing: 4) {
                                            ForEach(viewModel.availableCities) { city in
                                                Button(action: {
                                                    viewModel.draft.cityId = city.id
                                                    viewModel.searchQuery = city.displayName
                                                }) {
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(city.displayName)
                                                            .font(.body)
                                                            .foregroundColor(.titleDark)
                                                        Text(city.country)
                                                            .font(.caption)
                                                            .foregroundColor(.metaGrey)
                                                    }
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .padding(.vertical, 8)
                                                    .padding(.horizontal, 12)
                                                    .background(.white)
                                                    .cornerRadius(8)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                                                    )
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                    }
                                    .frame(maxHeight: 200)
                                }
                            }
                        }
                        .padding(Spacing.cardPadH)
                        .padding(.vertical, Spacing.cardPadV)
                        .background(.white)
                        .cornerRadius(Radius.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.card)
                                .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        
                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text("Error: \(errorMessage)")
                                .foregroundColor(.red)
                                .padding()
                                .background(.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                                )
                        }
                        
                        // Create Button
                        Button("Create Party") {
                            Task {
                                await viewModel.submit()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .disabled(viewModel.isSubmitting || !viewModel.isFormValid)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.yellow)
                        .cornerRadius(Radius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.button)
                                .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    }
                    .padding(Spacing.screenH)
                }
                
                // Success Toast Overlay
                if viewModel.showSuccessToast {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Party created successfully!")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(10)
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut(duration: 0.3), value: viewModel.showSuccessToast)
                }
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
            .onChange(of: viewModel.showSuccessToast) { showToast in
                if showToast {
                    // Dismiss the create party view
                    dismiss()
                }
            }
        }
    }
}
