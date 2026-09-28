//
//  MainViewModel.swift
//  Graphos
//
//  Created by Potatostore on 7/8/26.
//

import Foundation
import Photos
import Combine

struct PhotoDetailContext: Identifiable {
    let photos: [DisplayPhoto]
    let initialIndex: Int
    var id: String { photos.indices.contains(initialIndex) ? photos[initialIndex].id : UUID().uuidString }
}

class MainViewModel: ObservableObject {
    private let permissionManager = PermissionManager()
    private let appStorageManager = AppStorageManager()
    private let localStorageManger = LocalStorageManger()
    private let photoToLabelService = PhotoToLabelService()
    private let nlpService = NLPService()
    private let appleIntelligenceManager = AppleIntelligenceManager()
    private let searchLogManager = SearchLogManager()

    @Published var displayPhotos: [DisplayPhoto] = []
    @Published var searchingPhotos: [DisplayPhoto]? = nil
    @Published var editingPhoto: DisplayPhoto? = nil
    @Published var photoDetailContext: PhotoDetailContext? = nil
    // nil이면 "검색 결과 없음", 값이 있으면 Apple Intelligence 상태 때문에 검색 자체가
    // 불가능했던 것 - SearchingView가 이 둘을 구분해서 다른 안내를 보여줌
    @Published var searchUnavailableStatus: AppleIntelligenceStatus? = nil

    @Published var appStatus: AppStatus = .loading
    @Published var isSearching: Bool = false

    var currentGridPhotos: [DisplayPhoto] {
        searchingPhotos ?? displayPhotos
    }

    func openPhotoDetail(photo: DisplayPhoto) {
        let photos = currentGridPhotos
        guard let index = photos.firstIndex(where: { $0.id == photo.id }) else { return }
        photoDetailContext = PhotoDetailContext(photos: photos, initialIndex: index)
    }

    // 사진 앱에서 이미 삭제된 사진은 목록과 저장된 라벨에서 함께 제거
    func removePhoto(id: String) async {
        displayPhotos.removeAll { $0.id == id }
        searchingPhotos?.removeAll { $0.id == id }

        await appStorageManager.deleteLabels(id: id)
    }
    
    init(){
        appStatus = .loading
    }

    func loadPhotos() async{
        let labels: [Label] = await appStorageManager.loadAllLabels()
        let photos: [Photo] = await localStorageManger.loadAllPhotos()
        	
        
    }
    
    func searchPhotos(prompt: String) async {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedPrompt.isEmpty else {
            searchingPhotos = nil
            searchUnavailableStatus = nil
            return
        }

        isSearching = true

        let availability = appleIntelligenceManager.checkAvailability()
        guard availability == .available else {
            searchUnavailableStatus = availability
            searchingPhotos = []
            isSearching = false
            return
        }
        searchUnavailableStatus = nil

        let availableLabels = Set(displayPhotos.flatMap { $0.label.labels.map { $0.lowercased() } }).sorted()

        if let target = await nlpService.convertPromptToSearchTargetLabels(prompt: trimmedPrompt, availableLabels: availableLabels) {
            searchingPhotos = filterPhotos(target: target)
        } else {
            searchingPhotos = []
        }

        isSearching = false
    }

    func resetSearch(){
        searchingPhotos = nil
        searchUnavailableStatus = nil
        isSearching = false
    }

    // 라이브러리 라벨 목록을 넘겨서 모델이 그대로 골라 쓰게 해도, 드물게 단수/복수형이
    // 어긋난 라벨을 내놓을 수 있어(예: "bottles" vs 저장된 "bottle") 마지막 안전장치로
    // 끝의 "s" 하나 정도는 허용하고 비교함
    private func normalizedForMatch(_ label: String) -> String {
        label.hasSuffix("s") && label.count > 3 ? String(label.dropLast()) : label
    }

    func filterPhotos(target: SearchTargetLabel) -> [DisplayPhoto]{
        let excludedLabels = Set(target.excludedLabels.map { normalizedForMatch($0.lowercased()) })
        let includedLabels = target.includedLabels.map { normalizedForMatch($0.lowercased()) }

        return self.displayPhotos.filter{photo in
            let photoLabels = Set(photo.label.labels.map { normalizedForMatch($0.lowercased()) })

            if !excludedLabels.isDisjoint(with: photoLabels) { return false }

            if !includedLabels.isEmpty {
                return includedLabels.contains { photoLabels.contains($0) }
            }

            return true
        }
    }

    func saveEditingPhotoLabels(_ labels: [String]) async {
        guard let editingPhoto = self.editingPhoto else { return }

        await appStorageManager.updateLabels(id: editingPhoto.id, labels: labels)

        if let index = displayPhotos.firstIndex(where: { $0.id == editingPhoto.id }) {
            var updatedPhoto = displayPhotos[index]
            updatedPhoto.label.labels = labels
            displayPhotos[index] = updatedPhoto
        }

        self.editingPhoto = nil
    }
    
    // 검색 결과가 있었는지, Apple Intelligence를 쓸 수 있었는지와 상관없이 사용자가 실제로
    // 검색을 시도한 문장을 기록함 - searchPhotos와 같은 기준으로 앞뒤 공백을 자르고 빈 검색은 제외
    func saveSearchLog(searchPrompt: String, searchDate: Date) async {
        let trimmedPrompt = searchPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }

        await searchLogManager.saveSearchLog(searchLog: SearchLog(searchDate: searchDate, searchPrompt: trimmedPrompt))
    }

}
