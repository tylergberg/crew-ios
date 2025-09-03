import SwiftUI
import AVFoundation

struct CameraPreviewViewNew: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        view.setPreviewLayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Update is handled automatically by the PreviewView
    }
}

class PreviewView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        // Remove existing layer if any
        previewLayer?.removeFromSuperlayer()
        
        // Set new layer
        previewLayer = layer
        layer.frame = bounds
        layer.videoGravity = .resizeAspectFill
        
        // Ensure proper orientation
        if let connection = layer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        self.layer.addSublayer(layer)
        
        // Trigger layout update
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update preview layer frame when view bounds change
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer?.frame = bounds
        CATransaction.commit()
    }
}
