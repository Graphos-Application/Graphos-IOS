//
//  LocalStorageManger.swift
//  Graphos
//
//  Created by Potatostore on 7/8/26.
//
//  Load and Save Photos from local photo application
//  CRUD from application memory with labeledPhoto class references

import Photos
import PhotosUI
import UIKit
import SwiftData
import SwiftUI

@MainActor
struct LocalStorageManger{
    private let modelContext: ModelContext = ModelContext(MainView.modelContainer)
    
    func loadAllPhotos() async -> [Photo] {
        var allPhotos: [Photo] = []
        var seenSignatures: Set<String> = []

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let allPhotosFetchResult: PHFetchResult<PHAsset> = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        for index in 0..<allPhotosFetchResult.count{
            let asset = allPhotosFetchResult[index]

            // iCloud 동기화 이력이 있는 실기기 라이브러리에는 같은 사진이 서로 다른
            // localIdentifier로 중복 저장돼 있는 경우가 실제로 있음(사진 앱에 "중복 항목"
            // 스마트 앨범이 따로 있는 이유와 동일한 현상). 촬영 시각(서브초 단위까지 동일)과
            // 해상도가 완전히 같으면 같은 사진으로 보고 걸러냄. 연사(Burst) 사진은 같은
            // 촬영 시각/해상도를 공유하는 게 정상이라 예외로 둠
            if asset.burstIdentifier == nil, let creationDate = asset.creationDate {
                let signature = "\(creationDate.timeIntervalSince1970)_\(asset.pixelWidth)_\(asset.pixelHeight)"
                guard seenSignatures.insert(signature).inserted else { continue }
            }

            let photo: Photo = Photo(id: asset.localIdentifier, asset: asset)
            allPhotos.append(photo)
        }

        return allPhotos
    }
}
