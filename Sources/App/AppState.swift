import Foundation
import SwiftUI

enum CameraMode: String, CaseIterable, Identifiable {
    case photo = "PHOTO"
    case filters = "FILTERS"
    case manual = "MANUAL"

    var id: String { rawValue }
}

@MainActor
final class AppState: ObservableObject {
    @Published var activeMode: CameraMode = .photo
    @Published var isGalleryPresented: Bool = false
    @Published var isEditorPresented: Bool = false
    @Published var editingPhotoItem: CapturedPhotoItem?

    let cameraManager = CameraManager()
    let filterLibrary = FilterLibrary()
    let libraryManager = PhotoLibraryManager()

    init() {
        cameraManager.bindFilterLibrary(filterLibrary)
        cameraManager.bindLibraryManager(libraryManager)
    }
}
