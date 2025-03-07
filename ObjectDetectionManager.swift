import AVFoundation
import Vision
import CoreML
import SwiftUI

class ObjectDetectionManager: NSObject, ObservableObject {
    @Published var detections: [Detection] = []
    
    // Exposed so CameraPreviewView can use it.
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    
    private var visionRequests = [VNRequest]()
    
    override init() {
        super.init()
        setupCamera()
        setupVision()
        captureSession.startRunning()
    }
    
    private func setupCamera() {
        captureSession.sessionPreset = .high
        
        // Use the back camera; change to .front if needed.
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("No video camera available")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
            
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String:
                                            kCVPixelFormatType_32BGRA]
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    private func setupVision() {
        // Load the ML model (ensure ObjectDetector.mlmodel is added to your project).
        guard let modelURL = Bundle.main.url(forResource: "ObjectDetector", withExtension: "mlmodelc") else {
            print("Model file not found")
            return
        }
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            let visionModel = try VNCoreMLModel(for: mlModel)
            let request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            // Use .scaleFill so the image is resized correctly.
            request.imageCropAndScaleOption = .scaleFill
            visionRequests = [request]
        } catch {
            print("Error setting up Vision model: \(error)")
        }
    }
    
    private func visionRequestDidComplete(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            var newDetections: [Detection] = []
            
            if let results = request.results as? [VNRecognizedObjectObservation] {
                for observation in results {
                    guard let topLabel = observation.labels.first else { continue }
                    // Filter for the desired object classes.
                    let validLabels = ["car", "house", "helicopter", "airplane", "person", "t-shirt", "hat", "shoe"]
                    if validLabels.contains(topLabel.identifier.lowercased()) {
                        let detection = Detection(
                            label: topLabel.identifier,
                            confidence: topLabel.confidence,
                            boundingBox: observation.boundingBox
                        )
                        newDetections.append(detection)
                    }
                }
            }
            self.detections = newDetections
        }
    }
}

extension ObjectDetectionManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                   orientation: .up,
                                                   options: [:])
        do {
            try requestHandler.perform(self.visionRequests)
        } catch {
            print("Error performing vision request: \(error)")
        }
    }
}
