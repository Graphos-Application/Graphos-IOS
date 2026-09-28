//
//  PhotoImageLoader.swift
//  Graphos_UI
//
//  Created by Potatostore on 9/2/26.
//
// PHImageManager 요청이 시뮬레이터에서 응답 없이 멈추는 경우가 있어(Vision과
// 같은 원인으로 추정), 타임아웃 이내에 못 받으면 nil을 반환해 화면이
// 무한정 로딩 상태로 남지 않도록 함

import Photos
import UIKit

enum PhotoImageLoader {

    // PHCachingImageManager는 요청마다 새로 만들지 않고 하나를 계속 재사용해야
    // 내부 썸네일 캐시가 유지됨 - 상세보기 갔다가 그리드로 돌아왔을 때 다시
    // 디코딩하지 않고 캐시에서 즉시 반환되게 하는 핵심 장치
    private static let cachingImageManager = PHCachingImageManager()

    // 사용자가 사진 앱에서 사진을 삭제하면 우리가 들고 있던 PHAsset은 메모리에
    // 남아있어도 라이브러리에서는 더 이상 조회되지 않음 - 이걸로 "진짜 삭제됨"과
    // "일시적 로딩 실패"를 구분함
    static func exists(_ photo: Photo) -> Bool {
        PHAsset.fetchAssets(withLocalIdentifiers: [photo.id], options: nil).count > 0
    }

    // 그리드 셀이 화면에 나타나기 직전에 미리 호출해서 PHCachingImageManager가
    // 디코딩을 앞당겨 시작하게 함 - 실제 이미지를 받을 필요는 없고 캐시에 미리
    // 데워두는 용도라 targetSize/photo만 넘기면 됨
    static func startCaching(for photo: Photo, targetSize: CGSize) {
        let scale = UIScreen.main.scale
        let pixelSize = CGSize(width: targetSize.width * scale, height: targetSize.height * scale)
        cachingImageManager.startCachingImages(for: [photo.asset], targetSize: pixelSize, contentMode: .aspectFill, options: nil)
    }

    static func stopCaching(for photo: Photo, targetSize: CGSize) {
        let scale = UIScreen.main.scale
        let pixelSize = CGSize(width: targetSize.width * scale, height: targetSize.height * scale)
        cachingImageManager.stopCachingImages(for: [photo.asset], targetSize: pixelSize, contentMode: .aspectFill, options: nil)
    }

    static func loadImage(for photo: Photo, targetSize: CGSize, highQuality: Bool = false) async -> UIImage? {
        await withTaskGroup(of: UIImage?.self) { group in
            group.addTask {
                await load(photo: photo, targetSize: targetSize, highQuality: highQuality)
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: highQuality ? 8_000_000_000 : 4_000_000_000)
                return nil
            }

            defer { group.cancelAll() }
            return await group.next() ?? nil
        }
    }

    // 실기기에서는 PHImageManager가 Photos 프레임워크가 미리 만들어둔 썸네일
    // 캐시를 그대로 활용해 원본 파일을 직접 읽어 디코딩하는 것보다 훨씬 빠르고,
    // 그리드를 스크롤하거나 상세보기에서 돌아올 때도 버벅이지 않음.
    // 다만 일부 시뮬레이터에서는 PHImageManager 요청이 응답 없이 멈추는 경우가
    // 있어(Vision과 같은 원인으로 추정), 시뮬레이터에서만 PHAssetResourceManager로
    // 원본 파일 바이트를 직접 읽어 CPU(ImageIO)로 디코딩하는 방식으로 우회함
    //
    // targetSize는 호출부 기준 "포인트" 단위로 받고, 여기서 화면 scale을 곱해
    // 실제 픽셀 크기로 변환함. 이전에는 그리드 셀이 포인트 크기를 그대로 넘겨서
    // Retina(2x/3x) 기기에서 실제 필요한 해상도의 1/2~1/3만 요청한 뒤 화면에 늘려
    // 그리는 꼴이 되어 썸네일이 흐릿하게 보였음
    private static func load(photo: Photo, targetSize: CGSize, highQuality: Bool) async -> UIImage? {
        let scale = UIScreen.main.scale
        let pixelSize = CGSize(width: targetSize.width * scale, height: targetSize.height * scale)

        #if targetEnvironment(simulator)
        return await loadViaResourceManager(photo: photo, targetSize: pixelSize)
        #else
        return await loadViaImageManager(photo: photo, targetSize: pixelSize, highQuality: highQuality)
        #endif
    }

    // 요청 ID는 requestImage 호출이 반환된 직후(비동기 완료 전)에 동기적으로 채워짐.
    // 그 사이 아주 좁은 창에서 취소가 들어오면 놓칠 수 있지만, 호출부(PhotoThumbnailView/
    // PhotoDetailPageView)에서 Task.isCancelled를 다시 확인하는 이중 방어가 있어 실질적으로
    // "취소된 셀에 다른 사진 이미지가 뒤늦게 씌워지는" 문제는 막힘
    private final class RequestBox: @unchecked Sendable {
        private let lock = NSLock()
        var id: PHImageRequestID? {
            get { lock.withLock { _id } }
            set { lock.withLock { _id = newValue } }
        }
        private var _id: PHImageRequestID?
    }

    // 그리드를 빠르게 스크롤하거나 상세보기에서 빠르게 스와이프하면 이전 사진의 요청이
    // 아직 안 끝난 채로 셀/페이지가 다른 사진으로 바뀌는 경우가 있음. PHImageManager
    // 요청을 Swift Task 취소와 연결해두지 않으면, 뒤늦게 도착한 "이전 사진"의 응답이
    // 그 사이 다른 사진으로 바뀐 화면에 그대로 그려져서 "엉뚱한 사진이 보인다"는
    // 증상으로 나타남 - withTaskCancellationHandler로 취소 시 실제 요청도 취소함
    private static func loadViaImageManager(photo: Photo, targetSize: CGSize, highQuality: Bool) async -> UIImage? {
        let options = PHImageRequestOptions()
        // .fastFormat은 저해상도 이미지 한 장만 주고 끝나서, 상세보기에서 아무리
        // 기다려도 고화질로 갱신되지 않고 계속 흐릿하게 보임. 상세보기에서는
        // .highQualityFormat으로 원본 해상도에 가까운 이미지를 한 번에 요청함
        options.deliveryMode = highQuality ? .highQualityFormat : .fastFormat
        options.resizeMode = highQuality ? .exact : .fast
        options.isNetworkAccessAllowed = false
        options.isSynchronous = false

        let box = RequestBox()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<UIImage?, Never>) in
                let requestID = cachingImageManager.requestImage(
                    for: photo.asset,
                    targetSize: targetSize,
                    contentMode: .aspectFill,
                    options: options
                ) { image, _ in
                    continuation.resume(returning: image)
                }
                box.id = requestID
            }
        } onCancel: {
            if let requestID = box.id {
                cachingImageManager.cancelImageRequest(requestID)
            }
        }
    }

    private static func loadViaResourceManager(photo: Photo, targetSize: CGSize) async -> UIImage? {
        let resources = PHAssetResource.assetResources(for: photo.asset)
        guard let resource = resources.first(where: { $0.type == .photo }) ?? resources.first else {
            return nil
        }

        var data = Data()
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = false

        let box = RequestBox()

        let fullImage: UIImage? = await withTaskCancellationHandler {
            await withCheckedContinuation { (continuation: CheckedContinuation<UIImage?, Never>) in
                let requestID = PHAssetResourceManager.default().requestData(
                    for: resource,
                    options: options,
                    dataReceivedHandler: { chunk in data.append(chunk) },
                    completionHandler: { error in
                        if error != nil {
                            continuation.resume(returning: nil)
                            return
                        }
                        continuation.resume(returning: UIImage(data: data))
                    }
                )
                box.id = requestID
            }
        } onCancel: {
            if let requestID = box.id {
                PHAssetResourceManager.default().cancelDataRequest(requestID)
            }
        }

        guard let fullImage else { return nil }
        guard !Task.isCancelled else { return nil }
        return await fullImage.byPreparingThumbnail(ofSize: targetSize) ?? fullImage
    }
}
