import SwiftUI
import Photos
import UIKit

enum LoadingStatus{
    case loadingPictures
    case labeling
}

struct LoadingView: View {
    @EnvironmentObject var mainViewModel: MainViewModel

    @State var loadingStatus: LoadingStatus = .loadingPictures
    
    private let permissionManager: PermissionManager = PermissionManager()
    private let appStorageManager: AppStorageManager = AppStorageManager()
    private let localStorageManger: LocalStorageManger = LocalStorageManger()
    private let photoToLabelService: PhotoToLabelService = PhotoToLabelService()
    
    var body: some View {
        ZStack {
            (mainViewModel.darkMode ? Color.black : Color.white).ignoresSafeArea()
            
            VStack(spacing: 20) {
                switch(loadingStatus){
                case .loadingPictures:
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("사진을 불러오는 중...")
                        .foregroundColor(mainViewModel.darkMode ? .white : .black)
                case .labeling:
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("사진 라벨 분석 중...")
                        .foregroundColor(mainViewModel.darkMode ? .white : .black)
                }
            }
        }
        .task {
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            
            if status == .authorized || status == .limited {
                await startPhotoProcessingFlow()
            } else {
                let granted = await permissionManager.requestPhotoPermission()
                if granted {
                    await startPhotoProcessingFlow()
                } else {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        await UIApplication.shared.open(url)
                    }
                }
            }
        }
    }
    
    @MainActor
    private func startPhotoProcessingFlow() async {
        loadingStatus = .loadingPictures
        
        guard let fetchedPhotos = await fetchPhotosFromLocalStorage() else {
            mainViewModel.displayPhotos = []
            mainViewModel.appStatus = .idle
            return
        }
        
        loadingStatus = .labeling
        
        let activeIds = fetchedPhotos.map { $0.id }
        await appStorageManager.deleteOrphanedLabels(activatePhotoIds: activeIds)
        
        mainViewModel.displayPhotos = await fetchDisplayPhotos(photos: fetchedPhotos)
        mainViewModel.appStatus = .idle
    }
    
    private func fetchPhotosFromLocalStorage() async -> [Photo]? {
        return await localStorageManger.loadAllPhotos()
    }
    
    private func fetchDisplayPhotos(photos: [Photo]) async -> [DisplayPhoto]{
        var displayPhotos: [DisplayPhoto] = []
        
        for photo in photos{
            displayPhotos.append(DisplayPhoto(photo: photo, label: await appStorageManager.findByPhotoId(id: photo.id)))
        }
        
        for displayPhoto in displayPhotos {
            if displayPhoto.label.labels.isEmpty {
                if let extractedLabels = try? await photoToLabelService.convertPhotoToLabel(photo: displayPhoto.photo){
                    displayPhoto.label.labels = extractedLabels
                    await appStorageManager.saveLabel(label: displayPhoto.label)
                }
            }
        }
        
        return displayPhotos
    }
}
