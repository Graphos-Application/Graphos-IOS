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
    case classificationTimedOut
    case imageLoadTimedOut
}

extension Photo{
    func loadCgImage() async throws -> CGImage{
        try await withThrowingTaskGroup(of: CGImage.self) { group in
            group.addTask {
                try await Self.requestCgImage(for: self.asset)
            }

            group.addTask {
                try await Task.sleep(nanoseconds: 4_000_000_000)
                throw PhotoError.imageLoadTimedOut
            }

            defer { group.cancelAll() }
            guard let result = try await group.next() else {
                throw PhotoError.cgImageConvertFailed
            }
            return result
        }
    }

    private static func requestCgImage(for asset: PHAsset) async throws -> CGImage {
        let phImageManager = PHImageManager.default()
        let phImageOption = PHImageRequestOptions()

        phImageOption.deliveryMode = .highQualityFormat
        phImageOption.isSynchronous = false

        return try await withCheckedThrowingContinuation{continuation in
            phImageManager.requestImage(
                for: asset,
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
        #if targetEnvironment(simulator)
        // 시뮬레이터의 Vision on-device 추론(Neural Engine 에뮬레이션)이 응답 없이
        // 멈추는 경우가 있어(espresso context 생성 실패), 타임아웃으로도 우회가 안 됨.
        // 시뮬레이터 빌드에서는 실제 추론 없이 플레이스홀더 라벨을 반환하고,
        // 실기기 빌드는 아래의 실제 Vision 파이프라인을 그대로 사용함.
        return ["시뮬레이터 미리보기"]
        #else
        let cgImage = try await photo.loadCgImage()

        return try await withThrowingTaskGroup(of: [String].self) { group in
            group.addTask {
                try await Self.classify(cgImage: cgImage)
            }

            group.addTask {
                try await Task.sleep(nanoseconds: 4_000_000_000)
                throw PhotoError.classificationTimedOut
            }

            defer { group.cancelAll() }
            return try await group.next() ?? []
        }
        #endif
    }

    // Vision의 perform(_:)은 동기 블로킹 호출이라 Swift 동시성의 협력형 스레드풀에서
    // 직접 실행하면(Task.detached) 풀 전체가 굶주릴 수 있음 — 전용 GCD 스레드에서 실행해
    // 타임아웃 Task가 항상 정상적으로 경합할 수 있도록 함
    private static func classify(cgImage: CGImage) async throws -> [String] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let classifyRequest = VNClassifyImageRequest()
                // VNClassifyImageRequest의 범용 taxonomy에는 "기프티콘"/쿠폰/상품권 같은
                // 개념이 아예 없어서, 사진에 찍힌 실제 사물(예: 초콜릿 사진이 그려진
                // 기프티콘)로만 분류되고 검색이 안 되는 문제가 있었음. 대신 이런 모바일
                // 쿠폰류는 거의 항상 교환용 바코드/QR이 박혀있다는 점을 이용해, 전용
                // 바코드 감지기로 "barcode" 라벨을 보조적으로 합성해 붙임(완벽한 매칭은
                // 아니고 휴리스틱)
                let barcodeRequest = VNDetectBarcodesRequest()
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

                do {
                    try handler.perform([classifyRequest, barcodeRequest])

                    // Vision의 VNClassifyImageRequest는 "document"/"text"처럼 넓은 범주가
                    // 0.5 언저리 신뢰도로 잘 튀는 경향이 있어, 실기기 테스트에서 거의 모든
                    // 사진에 "document"가 붙는 문제가 보고됨. 임계값을 0.6으로 올려 낮은
                    // 신뢰도의 잡음성 라벨을 우선 줄임 - 실기기에서 재검증 필요
                    var labels = (classifyRequest.results ?? [])
                        .filter { $0.confidence > 0.6 }
                        .prefix(10)
                        .map { $0.identifier }

                    if !(barcodeRequest.results ?? []).isEmpty, !labels.contains("barcode") {
                        labels.append("barcode")
                    }

                    continuation.resume(returning: labels)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
