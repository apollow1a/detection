import SwiftUI

struct DetectionBoxView: View {
    let detection: Detection
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .local)
            let rect = convertToRect(normalized: detection.boundingBox, in: frame)
            
            ZStack {
                // Draw the detection box with a shadow and animation.
                Path { path in
                    path.addRect(rect)
                }
                .stroke(Color.red, lineWidth: 2)
                .shadow(color: .black, radius: 2, x: 0, y: 0)
                .animation(.easeInOut, value: rect)
                
                // Overlay the detection label.
                Text(detection.label)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(5)
                    .shadow(radius: 3)
                    // Adjust position ensuring the label is not clipped.
                    .position(x: rect.midX, y: max(rect.minY - 15, 15))
            }
            // Combine elements for accessibility.
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(detection.label) detection at \(Int(rect.origin.x)), \(Int(rect.origin.y))")
        }
    }
    
    // Helper function to convert normalized coordinates to absolute coordinates.
    private func convertToRect(normalized: CGRect, in frame: CGRect) -> CGRect {
        return CGRect(
            x: normalized.origin.x * frame.width,
            y: (1 - normalized.origin.y - normalized.height) * frame.height,
            width: normalized.width * frame.width,
            height: normalized.height * frame.height
        )
    }
}

// MARK: - Preview Provider

struct DetectionBoxView_Previews: PreviewProvider {
    // Dummy Detection type for preview purposes.
    struct DummyDetection: DetectionProtocol {
        var boundingBox: CGRect
        var label: String
    }
    
    // If you already have a Detection type defined, update the preview accordingly.
    static var previews: some View {
        let dummyDetection = DummyDetection(
            boundingBox: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.2),
            label: "Object"
        )
        DetectionBoxView(detection: dummyDetection)
            .frame(width: 300, height: 500)
            .previewLayout(.sizeThatFits)
    }
}
