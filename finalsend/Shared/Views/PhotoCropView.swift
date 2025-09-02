import SwiftUI

struct PhotoCropView: View {
    let image: UIImage
    let onCropComplete: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    private let cropSize: CGFloat = 300
    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 3.0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Crop frame
                    ZStack {
                        // Background
                        Color.black
                        
                        // Image with gestures
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                SimultaneousGesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let newOffset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                            offset = newOffset
                                        }
                                        .onEnded { _ in
                                            lastOffset = offset
                                        },
                                    MagnificationGesture()
                                        .onChanged { value in
                                            let newScale = lastScale * value
                                            scale = min(maxScale, max(minScale, newScale))
                                        }
                                        .onEnded { _ in
                                            lastScale = scale
                                        }
                                )
                            )
                            .frame(width: cropSize, height: cropSize)
                            .clipped()
                        
                        // Crop frame border
                        Rectangle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: cropSize, height: cropSize)
                    }
                    .frame(width: cropSize, height: cropSize)
                    
                    Spacer()
                    
                    // Instructions
                    Text("Drag to move • Pinch to zoom")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 20)
                }
            }
            .onAppear {
                print("🖼️ PhotoCropView appeared with image size: \(image.size)")
            }
            .navigationTitle("Crop Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        cropImage()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func cropImage() {
        // Create a new image with the desired size
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cropSize, height: cropSize))
        
        let croppedImage = renderer.image { context in
            // Calculate the scale and offset to position the image correctly
            let imageSize = image.size
            let targetSize = CGSize(width: cropSize, height: cropSize)
            
            // Calculate the scale to fit the image within the crop area
            let scaleX = targetSize.width / imageSize.width
            let scaleY = targetSize.height / imageSize.height
            let scale = max(scaleX, scaleY) * self.scale
            
            // Calculate the scaled image size
            let scaledWidth = imageSize.width * scale
            let scaledHeight = imageSize.height * scale
            
            // Calculate the position to center the image
            let x = (targetSize.width - scaledWidth) / 2 + offset.width
            let y = (targetSize.height - scaledHeight) / 2 + offset.height
            
            // Draw the image
            image.draw(in: CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight))
        }
        
        onCropComplete(croppedImage)
    }
}

#Preview {
    PhotoCropView(
        image: UIImage(systemName: "photo") ?? UIImage(),
        onCropComplete: { _ in },
        onCancel: { }
    )
}
