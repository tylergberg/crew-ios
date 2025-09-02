import SwiftUI
import PhotosUI

struct StepCoverPhotoView: View {
    @ObservedObject var viewModel: CreatePartyViewModel
    @State private var showingImagePicker = false
    @State private var showingLinkInput = false
    @State private var linkInput = ""
    @State private var showPhotoCrop = false
    @State private var selectedImage: UIImage?
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Trip Photo")
                    .font(Typography.title())
                    .foregroundColor(.titleDark)
                
                Text("Optional. You can add this later.")
                    .font(Typography.meta())
                    .foregroundColor(.metaGrey)
            }
            
            // Cover Photo Selection
            VStack(spacing: 16) {
                if let coverImage = viewModel.coverImage {
                    // Show selected image
                    VStack(spacing: 12) {
                        Image(uiImage: coverImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipped()
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                            )
                        
                        Button("Change Photo") {
                            showingImagePicker = true
                        }
                        .foregroundColor(.titleDark)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                        )
                    }
                } else {
                    // Show placeholder with options
                    VStack(spacing: 16) {
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(.metaGrey)
                            
                            Text("No cover photo selected")
                                .font(.headline)
                                .foregroundColor(.titleDark)
                            
                            Text("Add a photo to make your party stand out")
                                .font(.subheadline)
                                .foregroundColor(.metaGrey)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .background(.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                        )
                        
                        // Image Source Options
                        VStack(spacing: 12) {
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled")
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
                        }
                    }
                }
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingImagePicker) {
            CoverImagePicker(selectedImage: $selectedImage)
        }
        .fullScreenCover(isPresented: $showPhotoCrop) {
            if let image = selectedImage {
                PhotoCropView(
                    image: image,
                    onCropComplete: { croppedImage in
                        viewModel.coverImage = croppedImage
                        showPhotoCrop = false
                        selectedImage = nil
                    },
                    onCancel: {
                        showPhotoCrop = false
                        selectedImage = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showingLinkInput) {
            LinkInputSheet(linkInput: $linkInput, onImageSelected: { imageUrl in
                // Convert URL to UIImage and set it
                loadImageFromURL(imageUrl) { image in
                    if let image = image {
                        viewModel.coverImage = image
                    }
                }
            })
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                showPhotoCrop = true
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

struct CoverImagePicker: UIViewControllerRepresentable {
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
        let parent: CoverImagePicker
        
        init(_ parent: CoverImagePicker) {
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

struct LinkInputSheet: View {
    @Binding var linkInput: String
    let onImageSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var tempLinkInput = ""
    @State private var isValidImageURL = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add Image from URL")
                        .font(Typography.title())
                        .foregroundColor(Color.titleDark)
                    
                    Text("Paste a direct link to an image")
                        .font(Typography.meta())
                        .foregroundColor(Color.metaGrey)
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    TextField("Paste image URL here...", text: $tempLinkInput)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.titleDark)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.outlineBlack, lineWidth: 1.5)
                        )
                        .onChange(of: tempLinkInput) { newValue in
                            validateImageURL(newValue)
                        }
                    
                    if !tempLinkInput.isEmpty {
                        if isValidImageURL {
                            Text("✓ Valid image URL")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text("Please enter a valid image URL")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color.beige)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if isValidImageURL {
                            onImageSelected(tempLinkInput)
                            dismiss()
                        }
                    }
                    .disabled(!isValidImageURL)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func validateImageURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            isValidImageURL = false
            return
        }
        
        // Simple validation for image URLs
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp"]
        let pathExtension = url.pathExtension.lowercased()
        
        isValidImageURL = imageExtensions.contains(pathExtension) || 
                         urlString.contains("unsplash.com") ||
                         urlString.contains("pexels.com")
    }
}

#Preview {
    StepCoverPhotoView(viewModel: CreatePartyViewModel())
        .padding()
        .background(Color.beige)
}
