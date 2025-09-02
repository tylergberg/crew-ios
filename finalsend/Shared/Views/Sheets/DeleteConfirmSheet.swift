//
//  DeleteConfirmSheet.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-01-27.
//

import SwiftUI

struct DeleteConfirmSheet: View {
    let title: String
    let message: String
    let itemName: String
    let onConfirm: () -> Void
    let onDismiss: () -> Void
    
    @State private var isDeleting = false
    
    var body: some View {
        VStack(spacing: LodgingTheme.looseSpacing) {
            // Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
                .padding(.top, LodgingTheme.looseSpacing)
            
            // Title
            Text(title)
                .font(LodgingTheme.headlineFont)
                .fontWeight(.bold)
                .foregroundColor(LodgingTheme.textPrimary)
                .multilineTextAlignment(.center)
            
            // Message
            Text(message)
                .font(LodgingTheme.bodyFont)
                .foregroundColor(LodgingTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, LodgingTheme.padding)
            
            // Item name highlight
            Text(itemName)
                .font(LodgingTheme.bodyFont)
                .fontWeight(.semibold)
                .foregroundColor(LodgingTheme.textPrimary)
                .padding(.horizontal, LodgingTheme.padding)
                .padding(.vertical, LodgingTheme.smallPadding)
                .background(LodgingTheme.backgroundYellow)
                .cornerRadius(LodgingTheme.smallCornerRadius)
            
            Spacer()
            
            // Buttons
            VStack(spacing: LodgingTheme.spacing) {
                Button(action: {
                    isDeleting = true
                    onConfirm()
                }) {
                    HStack {
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text(isDeleting ? "Deleting..." : "Delete")
                            .font(LodgingTheme.bodyFont)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LodgingTheme.padding)
                    .background(isDeleting ? Color.gray : Color.red)
                    .cornerRadius(LodgingTheme.smallCornerRadius)
                }
                .disabled(isDeleting)
                .padding(.horizontal, LodgingTheme.padding)
                
                Button(action: onDismiss) {
                    Text("Cancel")
                        .font(LodgingTheme.bodyFont)
                        .foregroundColor(LodgingTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, LodgingTheme.padding)
                        .background(Color.clear)
                        .cornerRadius(LodgingTheme.smallCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: LodgingTheme.smallCornerRadius)
                                .stroke(LodgingTheme.borderColor, lineWidth: 1)
                        )
                }
                .disabled(isDeleting)
                .padding(.horizontal, LodgingTheme.padding)
            }
            .padding(.bottom, LodgingTheme.looseSpacing)
        }
        .background(LodgingTheme.backgroundYellow)
        .cornerRadius(LodgingTheme.cornerRadius)
        .padding(LodgingTheme.padding)
    }
}

// MARK: - Convenience Initializers

extension DeleteConfirmSheet {
    static func forLodging(_ lodging: Lodging, onConfirm: @escaping () -> Void, onDismiss: @escaping () -> Void) -> DeleteConfirmSheet {
        return DeleteConfirmSheet(
            title: "Delete Lodging",
            message: "Are you sure you want to delete this lodging? This will also remove all rooms, beds, and assignments.",
            itemName: lodging.name,
            onConfirm: onConfirm,
            onDismiss: onDismiss
        )
    }
    
    static func forRoom(_ room: Room, onConfirm: @escaping () -> Void, onDismiss: @escaping () -> Void) -> DeleteConfirmSheet {
        return DeleteConfirmSheet(
            title: "Delete Room",
            message: "Are you sure you want to delete this room? This will also remove all beds and assignments in this room.",
            itemName: room.name,
            onConfirm: onConfirm,
            onDismiss: onDismiss
        )
    }
    
    static func forBed(_ bed: Bed, onConfirm: @escaping () -> Void, onDismiss: @escaping () -> Void) -> DeleteConfirmSheet {
        return DeleteConfirmSheet(
            title: "Delete Bed",
            message: "Are you sure you want to delete this bed? This will also remove all assignments to this bed.",
            itemName: bed.bedType.displayName,
            onConfirm: onConfirm,
            onDismiss: onDismiss
        )
    }
    
    static func forAssignment(_ attendeeName: String, onConfirm: @escaping () -> Void, onDismiss: @escaping () -> Void) -> DeleteConfirmSheet {
        return DeleteConfirmSheet(
            title: "Remove Assignment",
            message: "Are you sure you want to remove this person from their bed assignment?",
            itemName: attendeeName,
            onConfirm: onConfirm,
            onDismiss: onDismiss
        )
    }
}

#Preview {
    DeleteConfirmSheet(
        title: "Delete Lodging",
        message: "Are you sure you want to delete this lodging? This will also remove all rooms, beds, and assignments.",
        itemName: "Beach House",
        onConfirm: {},
        onDismiss: {}
    )
}

