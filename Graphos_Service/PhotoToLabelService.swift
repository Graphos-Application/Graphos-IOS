//
//  PhotoToLabelService.swift
//  Graphos
//
//  Created by Potatostore on 7/8/26.
//

import Photos
import Vision
import UIKit
import FoundationModels

enum PhotoError: Error{
    case cgImageConvertFailed
}

extension Photo{
    func loadCgImage() async throws -> CGImage{
        let phImageManager = PHImageManager.default()
        let phImageOption = PHImageRequestOptions()
        
        phImageOption.deliveryMode = .highQualityFormat
        phImageOption.isSynchronous = false
        
        return try await withCheckedThrowingContinuation{continuation in
            phImageManager.requestImage(
                for: self.asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: phImageOption
            ) { uiImage, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let cgImage = uiImage?.cgImage {
                    continuation.resume(returning: cgImage)
                } else {
                    continuation.resume(throwing: PhotoError.cgImageConvertFailed)
                }
            }
        }
    }
}

struct PhotoToLabelService {
    func convertPhotoToLabel(photo: Photo) async throws -> [String]{
        let cgImage = try await photo.loadCgImage()
        
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        try await Task.detached(priority: .userInitiated) {
            try handler.perform([request])
        }.value
        
        guard let results = request.results else { return [] }
        
        let labels = results
            .filter { $0.confidence > 0.5 }
            .prefix(10)
            .map { $0.identifier }
        
        return Array(labels)
    }
}
