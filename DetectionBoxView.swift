import SwiftUI

struct DetectionBoxView: View {
    let detection: Detection
    
    var body: some View {
        GeometryReader { geometry in
            let frame = geometry.frame(in: .local)
            // Convert normalized bounding box to screen coordinates.
            let rect = CGRect(
                x: detection.boundingBox.origin.x * frame.width,
                y: (1 - detection.boundingBox.origin.y - detection.boundingBox.height) * frame.height,
                width: detection.boundingBox.width * frame.width,
                height: detection.boundingBox.height * frame.height
            )
            
            Path { path in
                path.addRect(rect)
            }
            .stroke(Color.red, lineWidth: 2)
            .overlay(
                Text(detection.label)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(4)
                    .position(x: rect.midX, y: rect.minY - 10)
            )
        }
    }
}
