import SwiftUI
import PhotosUI
import AVFoundation

struct PhotoPickerView: View {
    let partyId: UUID
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var galleryService = GalleryService.shared
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showingCamera = false
    @State private var cameraImage: UIImage?
    @State private var isProcessing = false
    @State private var showingPhotoPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Text("Add Photos")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Done") {
                        uploadSelectedPhotos()
                    }
                    .disabled(selectedImages.isEmpty || isProcessing)
                }
                .padding()
                .background(.regularMaterial)
                
                // Content
                if selectedImages.isEmpty {
                    if isProcessing {
                        VStack(spacing: 16) {
                            Spacer()
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading photos...")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else {
                        EmptySelectionView(
                            onSelectPhotos: {
                                showingPhotoPicker = true
                            },
                            onTakePhoto: {
                                showingCamera = true
                            }
                        )
                    }
                } else {
                    SelectedPhotosView(
                        images: selectedImages,
                        onRemoveImage: { index in
                            selectedImages.remove(at: index)
                            selectedItems.remove(at: index)
                        }
                    )
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedItems,
                maxSelectionCount: 20,
                matching: .any(of: [.images, .videos])
            )
            .onChange(of: selectedItems) { newItems in
                loadSelectedImages(from: newItems)
            }
            .sheet(isPresented: $showingCamera) {
                CameraView { image in
                    cameraImage = image
                    if let image = image {
                        selectedImages.append(image)
                    }
                }
            }
        }
    }
    
    private func loadSelectedImages(from items: [PhotosPickerItem]) {
        isProcessing = true
        
        Task {
            var images: [UIImage] = []
            
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            
            await MainActor.run {
                selectedImages = images
                isProcessing = false
            }
        }
    }
    
    private func uploadSelectedPhotos() {
        isProcessing = true
        
        Task {
            let uploadFiles = selectedImages.compactMap { image -> GalleryUploadRequest.UploadFile? in
                guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
                
                return GalleryUploadRequest.UploadFile(
                    data: data,
                    filename: "IMG_\(Int(Date().timeIntervalSince1970)).jpg",
                    mimeType: "image/jpeg",
                    fileType: "image"
                )
            }
            
            await galleryService.uploadFiles(uploadFiles, to: partyId)
            
            await MainActor.run {
                isProcessing = false
                dismiss()
            }
        }
    }
}

// MARK: - Empty Selection View
struct EmptySelectionView: View {
    let onSelectPhotos: () -> Void
    let onTakePhoto: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("Add Photos to Gallery")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Choose photos from your library or take new ones")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(spacing: 16) {
                Button(action: onSelectPhotos) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose from Library")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: onTakePhoto) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Take Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

// MARK: - Selected Photos View
struct SelectedPhotosView: View {
    let images: [UIImage]
    let onRemoveImage: (Int) -> Void
    
    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipped()
                        
                        // Remove button
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: {
                                    onRemoveImage(index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                }
                                .padding(4)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            } else {
                parent.onImageCaptured(nil)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImageCaptured(nil)
        }
    }
}

// MARK: - Preview
#Preview {
    PhotoPickerView(partyId: UUID())
}
