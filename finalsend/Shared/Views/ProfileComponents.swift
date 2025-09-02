import SwiftUI
import PhotosUI

// MARK: - Shared Profile Components

struct SharedProfileHeaderView: View {
    let profile: ProfileResponse?
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView()
                    .frame(width: 80, height: 80)
            } else {
                AsyncImage(url: URL(string: profile?.avatar_url ?? "")) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
            }
            
            VStack(spacing: 8) {
                Text(profile?.full_name ?? "Loading...")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.titleDark)
            }
        }
        .padding(.top, 20)
    }
}

struct EditableProfileHeaderView: View {
    let profile: ProfileResponse?
    let isLoading: Bool
    let isUploading: Bool
    let onImageSelected: (UIImage) -> Void
    let onNameEdit: (() -> Void)?
    
    @State private var showingImagePicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView()
                    .frame(width: 80, height: 80)
            } else {
                ZStack {
                    AsyncImage(url: URL(string: profile?.avatar_url ?? "")) { image in
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    
                    if isUploading {
                        // Loading overlay
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .frame(width: 80, height: 80)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    } else {
                        // Camera icon overlay
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.brandBlue)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                        .offset(x: 25, y: 25)
                    }
                }
            }
            
            VStack(spacing: 8) {
                Button(action: {
                    onNameEdit?()
                }) {
                    HStack(spacing: 4) {
                        Text(profile?.full_name ?? "Loading...")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.titleDark)
                        
                        if onNameEdit != nil {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 20)
        .sheet(isPresented: $showingImagePicker) {
            ProfileImagePicker(selectedImage: .constant(nil), onImageSelected: onImageSelected)
        }
    }
}

struct SharedProfileSection<Content: View>: View {
    let title: String
    let content: Content
    let canEdit: Bool
    let onEdit: (() -> Void)?
    
    init(title: String, canEdit: Bool = false, onEdit: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
        self.canEdit = canEdit
        self.onEdit = onEdit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.titleDark)
                
                Spacer()
                
                if canEdit, let onEdit = onEdit {
                    Button(action: onEdit) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Edit")
                                .font(.callout.weight(.semibold))
                        }
                        .foregroundColor(.titleDark)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.yellow)
                        .cornerRadius(Radius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.button)
                                .stroke(Color.outlineBlack, lineWidth: 1.5)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.white)
            .cornerRadius(Radius.card)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
}

struct SharedProfileRow: View {
    let icon: String
    let label: String
    let value: String?
    let isLink: Bool
    let isAction: Bool
    let valueColor: Color?
    let actionColor: Color?
    let showChevron: Bool
    let showExternalLinkArrow: Bool
    let onTap: (() -> Void)?
    
    init(
        icon: String,
        label: String,
        value: String? = nil,
        isLink: Bool = false,
        isAction: Bool = false,
        valueColor: Color? = nil,
        actionColor: Color? = nil,
        showChevron: Bool = false,
        showExternalLinkArrow: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.label = label
        self.value = value
        self.isLink = isLink
        self.isAction = isAction
        self.valueColor = valueColor
        self.actionColor = actionColor
        self.showChevron = showChevron
        self.showExternalLinkArrow = showExternalLinkArrow
        self.onTap = onTap
    }
    
    var body: some View {
        Group {
            if let onTap = onTap, !showExternalLinkArrow {
                Button(action: onTap) {
                    contentView
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle()) // Ensure the entire button area is tappable
            } else {
                contentView
            }
        }
        .padding(.bottom, 1) // Add minimal spacing between rows
    }
    
    private var contentView: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(actionColor ?? .brandBlue)
                .frame(width: 24)
                .allowsHitTesting(false) // Prevent icon from interfering with button tap
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.callout.weight(.semibold))
                    .foregroundColor(.titleDark)
                
                if let value = value, !value.isEmpty {
                    if isLink, let url = URL(string: value) {
                        Link(value, destination: url)
                            .font(.callout.weight(.medium))
                            .foregroundColor(.brandBlue)
                            .allowsHitTesting(false) // Prevent link from interfering with button tap
                    } else {
                        Text(value)
                            .font(.callout.weight(.medium))
                            .foregroundColor(valueColor ?? .titleDark)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            
            Spacer()
            
            if showExternalLinkArrow, let value = value, !value.isEmpty, let url = URL(string: value) {
                Button(action: {
                    print("🔗 Opening external link: \(url)")
                    UIApplication.shared.open(url)
                }) {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.brandBlue)
                        .font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(PlainButtonStyle())
            } else if isAction || showChevron {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .allowsHitTesting(false) // Prevent chevron from interfering with button tap
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle()) // Ensure the entire content area is tappable
    }
}

// MARK: - Profile Image Picker

struct ProfileImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let onImageSelected: (UIImage) -> Void
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
        let parent: ProfileImagePicker
        
        init(_ parent: ProfileImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        if let selectedImage = image as? UIImage {
                            self.parent.selectedImage = selectedImage
                            self.parent.onImageSelected(selectedImage)
                        }
                    }
                }
            }
        }
    }
}
