//
//  EditCoverImageSheet.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-01-27.
//

import SwiftUI
import PhotosUI

struct EditCoverImageSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var partyManager: PartyManager
    
    let onSaved: () -> Void
    private let partyManagementService = PartyManagementService()
    private let coverImageService = CoverImageService()
    
    @State private var showingImagePicker = false
    @State private var showingLinkInput = false
    @State private var linkInput = ""
    @State private var showPhotoCrop = false
    @State private var selectedImage: UIImage?
    @State private var isSaving = false
    @State private var errorMessage: String = ""
    @State private var isImageCropped = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit Cover Photo")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.titleDark)
                    
                    Text("Choose a new cover photo for your party")
                        .font(.subheadline)
                        .foregroundColor(.metaGrey)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Current Cover Photo
                ScrollView {
                    VStack(spacing: 24) {
                        // Current Cover Photo Display
                        VStack(spacing: 16) {
                            Text(selectedImage != nil ? "New Cover Photo Preview" : "Current Cover Photo")
                                .font(.headline)
                                .foregroundColor(.titleDark)
                            
                            // Show selected image preview if available, otherwise show current cover photo
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 200, height: 200)
                                    .clipped()
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.brandBlue, lineWidth: 2)
                                    )
                                    .overlay(
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Text("NEW")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.brandBlue)
                                                    .cornerRadius(4)
                                                    .padding(8)
                                            }
                                            Spacer()
                                        }
                                    )
                            } else if let coverImageURL = partyManager.coverImageURL, !coverImageURL.isEmpty {
                                AsyncImage(url: URL(string: coverImageURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 200, height: 200)
                                        .clipped()
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                                        )
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 200, height: 200)
                                        .overlay(
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                        )
                                }
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 200, height: 200)
                                    .overlay(
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                            Text("No cover photo")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    )
                            }
                        }
                        
                        // Photo Selection Options
                        VStack(spacing: 12) {
                            Text("Choose New Photo")
                                .font(.headline)
                                .foregroundColor(.titleDark)
                            
                            // Photo Library Button
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                    Text("Choose from Library")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .foregroundColor(.titleDark)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // URL Input Button
                            Button(action: {
                                showingLinkInput = true
                            }) {
                                HStack {
                                    Image(systemName: "link")
                                    Text("Add from URL")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .foregroundColor(.titleDark)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Remove Photo Button (only show if there's a current photo)
                            if let coverImageURL = partyManager.coverImageURL, !coverImageURL.isEmpty {
                                Button(action: removeCoverPhoto) {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Remove Cover Photo")
                                        Spacer()
                                    }
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // Error Message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
                
                Spacer()
                
                // Save Button (only show if there's a selected image)
                if selectedImage != nil {
                    VStack(spacing: 16) {
                        Button(action: saveCoverPhoto) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Save Cover Photo")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.brandBlue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isSaving)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.brandBlue)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            EditCoverImagePicker(selectedImage: $selectedImage)
                .onDisappear {
                    // Reset the cropped flag when picker is dismissed
                    isImageCropped = false
                }
        }
        .fullScreenCover(isPresented: $showPhotoCrop) {
            if let image = selectedImage {
                PhotoCropView(
                    image: image,
                    onCropComplete: { croppedImage in
                        selectedImage = croppedImage
                        isImageCropped = true
                        showPhotoCrop = false
                    },
                    onCancel: {
                        showPhotoCrop = false
                        selectedImage = nil
                        isImageCropped = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingLinkInput) {
            EditLinkInputSheet(linkInput: $linkInput, onImageSelected: { imageUrl in
                // Convert URL to UIImage and set it
                loadImageFromURL(imageUrl) { image in
                    if let image = image {
                        selectedImage = image
                        isImageCropped = false
                    }
                }
            })
        }
        .onChange(of: selectedImage) { image in
            if let image = image, !isImageCropped {
                showPhotoCrop = true
            }
        }
    }
    
    private func saveCoverPhoto() {
        guard let image = selectedImage else { return }
        
        isSaving = true
        errorMessage = ""
        
        Task {
            do {
                // Clear cache for old cover image URL if it exists
                if let oldURL = partyManager.coverImageURL {
                    ImageCacheService.shared.removeImage(for: oldURL)
                }
                
                // Upload the image
                let imageURL = try await coverImageService.uploadImage(image)
                
                // Update the party with the new cover image URL
                let updates = ["cover_image_url": imageURL]
                let success = try await partyManagementService.updateParty(partyId: partyManager.partyId, updates: updates)
                
                if success {
                    // Update the party manager
                    partyManager.coverImageURL = imageURL
                    
                    // Clear the selected image to reset the preview
                    await MainActor.run {
                        selectedImage = nil
                    }
                    
                    // Call the onSaved callback
                    onSaved()
                    
                    // Dismiss the sheet
                    await MainActor.run {
                        dismiss()
                    }
                } else {
                    // Handle failure
                    await MainActor.run {
                        errorMessage = "Failed to update cover photo. Please try again."
                        isSaving = false
                    }
                }
            } catch {
                print("❌ Error updating cover photo: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to update cover photo. Please try again."
                    isSaving = false
                }
            }
        }
    }
    
    private func removeCoverPhoto() {
        isSaving = true
        errorMessage = ""
        
        Task {
            do {
                // Clear cache for current cover image URL if it exists
                if let currentURL = partyManager.coverImageURL {
                    ImageCacheService.shared.removeImage(for: currentURL)
                }
                
                // Update the party to remove the cover image URL
                let updates = ["cover_image_url": NSNull()]
                let success = try await partyManagementService.updateParty(partyId: partyManager.partyId, updates: updates)
                
                if success {
                    // Update the party manager
                    partyManager.coverImageURL = nil
                    
                    // Call the onSaved callback
                    onSaved()
                    
                    // Dismiss the sheet
                    await MainActor.run {
                        dismiss()
                    }
                } else {
                    // Handle failure
                    await MainActor.run {
                        errorMessage = "Failed to remove cover photo. Please try again."
                        isSaving = false
                    }
                }
            } catch {
                print("❌ Error removing cover photo: \(error)")
                await MainActor.run {
                    errorMessage = "Failed to remove cover photo. Please try again."
                    isSaving = false
                }
            }
        }
    }
    
    private func loadImageFromURL(_ urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    completion(image)
                } else {
                    completion(nil)
                }
            }
        }.resume()
    }
}

// Local components to avoid conflicts with StepCoverPhotoView
struct EditCoverImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: EditCoverImagePicker
        
        init(_ parent: EditCoverImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

struct EditLinkInputSheet: View {
    @Binding var linkInput: String
    let onImageSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter Image URL")
                    .font(.headline)
                    .padding(.top, 20)
                
                TextField("https://example.com/image.jpg", text: $linkInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                
                Button("Add Image") {
                    onImageSelected(linkInput)
                    dismiss()
                }
                .disabled(linkInput.isEmpty)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    EditCoverImageSheet(onSaved: {})
        .environmentObject(PartyManager.mock)
}
