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
    @State private var labeledCount: Int = 0
    @State private var totalToLabel: Int = 0
    @State private var skipRequested = false
    @State private var appleIntelligenceStatus: AppleIntelligenceStatus = .available
    @State private var showAppleIntelligenceAlert = false

    private let permissionManager: PermissionManager = PermissionManager()
    private let appStorageManager: AppStorageManager = AppStorageManager()
    private let localStorageManger: LocalStorageManger = LocalStorageManger()
    private let photoToLabelService: PhotoToLabelService = PhotoToLabelService()
    private let appleIntelligenceManager: AppleIntelligenceManager = AppleIntelligenceManager()

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 20) {
                switch(loadingStatus){
                case .loadingPictures:
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("사진을 불러오는 중...")
                        .foregroundColor(.primary)
                case .labeling:
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(totalToLabel > 0 ? "사진 라벨 분석 중... (\(labeledCount)/\(totalToLabel))" : "사진 라벨 분석 중...")
                        .foregroundColor(.primary)

                    if totalToLabel > 0 {
                        Button("건너뛰기") {
                            skipRequested = true
                        }
                        .foregroundColor(.blue)
                        .padding(.top, 8)
                    }
                }
            }
        }
        .task {
            let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

            if status == .authorized || status == .limited {
                checkAppleIntelligence()
                await startPhotoProcessingFlow()
            } else {
                let granted = await permissionManager.requestPhotoPermission()
                if granted {
                    checkAppleIntelligence()
                    await startPhotoProcessingFlow()
                } else {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        await UIApplication.shared.open(url)
                    }
                }
            }
        }
        .alert("Apple Intelligence 안내", isPresented: $showAppleIntelligenceAlert) {
            if appleIntelligenceStatus == .notEnabled {
                Button("설정으로 이동") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("나중에", role: .cancel) {}
            } else {
                Button("확인", role: .cancel) {}
            }
        } message: {
            Text(appleIntelligenceStatus.unavailableMessage)
        }
    }

    // 사진 권한 요청은 iOS가 알아서 시스템 팝업을 띄워주지만, Apple Intelligence는
    // 앱 단위 권한이 아니라 기기 전체 설정이라 그런 팝업이 없음 - 그래서 직접 확인하고
    // 직접 안내함. 사진 권한 다이얼로그와 겹치지 않도록 그게 끝난 뒤에 확인함
    private func checkAppleIntelligence() {
        appleIntelligenceStatus = appleIntelligenceManager.checkAvailability()
        if appleIntelligenceStatus != .available {
            showAppleIntelligenceAlert = true
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
    
    
    private let maxConcurrentLabeling = 6

    @MainActor
    private func fetchDisplayPhotos(photos: [Photo]) async -> [DisplayPhoto]{
        let existingLabelsById = Dictionary(
            uniqueKeysWithValues: await appStorageManager.loadAllLabels().map { ($0.id, $0) }
        )

        var displayPhotos: [DisplayPhoto] = []

        for photo in photos{
            let label = existingLabelsById[photo.id] ?? Label(id: photo.id)
            displayPhotos.append(DisplayPhoto(photo: photo, label: label))
        }

        // Vision이 사물을 하나도 못 찾아 labels가 빈 배열로 저장된 경우와, 아직
        // 한 번도 분석하지 않은 경우를 label.labels.isEmpty만으로는 구분할 수 없어서
        // 전자가 매 실행마다 다시 분석 대상으로 잡히는 문제가 있었음 - 저장된 Label
        // 레코드 존재 여부로 판단해야 "분석했지만 결과 없음"과 "미분석"이 구분됨
        let unlabeledPhotos = displayPhotos.filter { existingLabelsById[$0.id] == nil }
        let labelService = photoToLabelService
        let storageManager = appStorageManager

        labeledCount = 0
        totalToLabel = unlabeledPhotos.count

        await withTaskGroup(of: (id: String, labels: [String])?.self) { group in
            var pending = unlabeledPhotos[...]
            var inFlight = 0

            func startNext() {
                guard !skipRequested, let target = pending.popFirst() else { return }
                inFlight += 1
                group.addTask {
                    guard let labels = try? await labelService.convertPhotoToLabel(photo: target.photo) else {
                        return nil
                    }
                    return (target.id, labels)
                }
            }

            for _ in 0..<maxConcurrentLabeling { startNext() }

            while inFlight > 0, let result = await group.next() {
                inFlight -= 1
                labeledCount += 1

                if let result, let index = displayPhotos.firstIndex(where: { $0.id == result.id }) {
                    displayPhotos[index].label.labels = result.labels
                    await storageManager.saveLabel(label: displayPhotos[index].label)
                }

                if skipRequested {
                    group.cancelAll()
                    break
                }

                startNext()
            }
        }

        return displayPhotos
    }
}
