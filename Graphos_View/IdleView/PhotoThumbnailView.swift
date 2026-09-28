//
//  PhotoThumbnailView.swift
//  Graphos_UI
//
//  Created by Potatostore on 8/24/26.
//

import SwiftUI
import Photos

struct PhotoThumbnailView: View {
    let photo: Photo
    var targetSize: CGSize = CGSize(width: 300, height: 300)
    var contentMode: ContentMode = .fill
    var onDeleted: (() -> Void)? = nil

    @State private var image: UIImage?
    @State private var loadFailed = false

    var body: some View {
        ZStack {
            Color(.systemGray5)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if loadFailed {
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }
        }
        .clipped()
        .task(id: photo.id) {
            image = nil
            loadFailed = false

            if let result = await PhotoImageLoader.loadImage(for: photo, targetSize: targetSize) {
                image = result
            } else {
                loadFailed = true

                if !PhotoImageLoader.exists(photo) {
                    onDeleted?()
                }
            }
        }
    }
}
