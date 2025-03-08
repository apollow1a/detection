import AVFoundation
import Vision
import CoreML
import SwiftUI

class ObjectDetectionManager: NSObject, ObservableObject {
    @Published var detections: [Detection] = []
    
    // Exposed so that CameraPreviewView can access it.
    let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    
    private var visionRequests: [VNRequest] = []
    
    override init() {
        super.init()
        configureSession()
        setupVision()
        startSession()
    }
    
    // MARK: - Session Management
    
    /// Starts the capture session on a background thread.
    func startSession() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
                print("Capture session started.")
            }
        }
    }
    
    /// Stops the capture session on a background thread.
    func stopSession() {
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.stopRunning()
                print("Capture session stopped.")
            }
        }
    }
    
    /// Configures the capture session by setting up the video input and output.
    private func configureSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        // Setup video input using the back camera (change to .front if needed).
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("No video camera available.")
            captureSession.commitConfiguration()
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                print("Unable to add video input.")
            }
        } catch {
            print("Error setting up camera input: \(error)")
            captureSession.commitConfiguration()
            return
        }
        
        // Setup video output.
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        let videoQueue = DispatchQueue(label: "com.detectionapp.videoQueue", qos: .userInitiated)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            print("Unable to add video output.")
        }
        captureSession.commitConfiguration()
    }
    
    // MARK: - Vision Setup
    
    /// Sets up the Vision model and request.
    private func setupVision() {
        // Load the CoreML model (ensure ObjectDetector.mlmodel is added to your project).
        guard let modelURL = Bundle.main.url(forResource: "ObjectDetector", withExtension: "mlmodelc") else {
            print("Model file not found.")
            return
        }
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            let visionModel = try VNCoreMLModel(for: mlModel)
            let request = VNCoreMLRequest(model: visionModel, completionHandler: self.visionRequestDidComplete)
            // Set image crop and scale option to properly resize the image.
            request.imageCropAndScaleOption = .scaleFill
            visionRequests = [request]
        } catch {
            print("Error setting up Vision model: \(error)")
        }
    }
    
    // MARK: - Vision Request Completion
    
    /// Processes Vision results and updates the detections array.
    private func visionRequestDidComplete(request: VNRequest, error: Error?) {
        if let error = error {
            print("Vision request error: \(error)")
            return
        }
        DispatchQueue.main.async {
            var newDetections: [Detection] = []
            if let results = request.results as? [VNRecognizedObjectObservation] {
                for observation in results {
                    guard let topLabel = observation.labels.first else { continue }
                    // Filter for desired object classes.
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

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

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
