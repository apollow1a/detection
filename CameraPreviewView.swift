import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let captureSession: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        // Set up the preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        previewLayer.connection?.videoOrientation = currentVideoOrientation()
        
        // Insert the preview layer at the back
        view.layer.insertSublayer(previewLayer, at: 0)
        
        // Store the preview layer reference for future updates
        context.coordinator.previewLayer = previewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Ensure the preview layer always fills the view's bounds.
        if let previewLayer = context.coordinator.previewLayer {
            previewLayer.frame = uiView.bounds
            // Update orientation in case the device orientation changed.
            previewLayer.connection?.videoOrientation = currentVideoOrientation()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // Helper function to determine the current video orientation.
    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        let deviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .portrait, .unknown, .faceUp, .faceDown:
            return .portrait
        @unknown default:
            return .portrait
        }
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
