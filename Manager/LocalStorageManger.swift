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
    private var modelContext: ModelContext{
        return ModelContext(MainView.modelContainer)
    }
    
    func loadAllPhotos() async -> [Photo]? {
        var allPhotos: [Photo] = []
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let allPhotosFetchResult: PHFetchResult<PHAsset> = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        for index in 0..<allPhotosFetchResult.count{
            let photo: Photo = Photo(id: allPhotosFetchResult[index].localIdentifier, asset: allPhotosFetchResult[index])
            allPhotos.append(photo)
        }
        
        return allPhotos
    }
}
