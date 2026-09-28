//
//  PhotoDetailPageView.swift
//  Graphos_UI
//
//  Created by Potatostore on 9/2/26.
//

import SwiftUI

struct PhotoDetailPageView: View {
    let photo: Photo
    @Binding var isZoomedIn: Bool

    @State private var image: UIImage?

    // PhotoImageLoader가 픽셀 변환을 알아서 하므로 여기서는 포인트 크기만 전달
    private var targetSize: CGSize {
        UIScreen.main.bounds.size
    }

    var body: some View {
        ZStack {
            if let image {
                ZoomableImageView(image: image, isZoomedIn: $isZoomedIn)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .task(id: photo.id) {
            image = await PhotoImageLoader.loadImage(for: photo, targetSize: targetSize, highQuality: true)
        }
    }
}
