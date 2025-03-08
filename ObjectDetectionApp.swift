import SwiftUI

@main
struct ObjectDetectionApp: App {
    // Create a shared instance of your detection manager.
    @StateObject private var detectionManager = ObjectDetectionManager()
    
    // Observe the scene phase to manage detection sessions.
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(detectionManager)
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                // Start or resume the detection session.
                detectionManager.startSession()
            case .background:
                // Pause or stop the detection session.
                detectionManager.stopSession()
            case .inactive:
                // Optionally handle inactive state if needed.
                break
            @unknown default:
                break
            }
        }
    }
}
