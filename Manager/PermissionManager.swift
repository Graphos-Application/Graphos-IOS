import SwiftUI
import Photos
import Combine
import FoundationModels

class PermissionManager: ObservableObject {
    func requestPhotoPermission() async -> Bool {
            await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    continuation.resume(returning: status == .authorized || status == .limited)
            }
        }
    }
    
}
